import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { generateEncryptedToken } from '@/lib/keygen';

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  const { id } = params;
  const token = await prisma.token.findUnique({
    where: { id },
    include: {
      vipPackage: true,
      createdBy: { select: { id: true, username: true, displayName: true, role: true } },
      parent: {
        select: {
          id: true,
          characterUid: true,
          customerName: true,
          deviceSnMd5: true,
          expireAt: true,
          isDeleted: true,
          durationDays: true,
        },
      },
      children: {
        select: {
          id: true,
          characterUid: true,
          customerName: true,
          deviceSnMd5: true,
          expireAt: true,
          isDeleted: true,
          createdAt: true,
          isTest: true,
        },
        orderBy: { createdAt: 'desc' },
      },
      notes: {
        include: {
          createdBy: { select: { id: true, username: true, displayName: true } },
        },
        orderBy: { createdAt: 'desc' },
      },
    },
  });

  if (!token) {
    return NextResponse.json({ error: 'Token không tồn tại' }, { status: 404 });
  }

  // =========================================================================
  // [MOD FEATURE]: KIỂM TRA QUYỀN XEM CHI TIẾT TOKEN
  // =========================================================================
  if (session.role === 'SALE' && token.createdById !== session.userId) {
    return NextResponse.json({ error: 'Bạn không có quyền xem Token của nhân viên khác!' }, { status: 403 });
  }

  const now = new Date();
  let effectiveExpireAt = token.expireAt;
  let isExpired = new Date(token.expireAt) < now;
  let isDeleted = token.isDeleted;

  // Nếu là Token Phụ, kế thừa trạng thái từ Token Cha
  if (token.parent) {
    effectiveExpireAt = token.parent.expireAt;
    isExpired = new Date(token.parent.expireAt) < now;
    if (token.parent.isDeleted) {
      isDeleted = true;
    }
  }

  const threeDaysLater = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
  const isExpiringSoon = !isExpired && new Date(effectiveExpireAt) <= threeDaysLater;
  const status = isDeleted ? 'DELETED' : isExpired ? 'EXPIRED' : isExpiringSoon ? 'EXPIRING_SOON' : 'ACTIVE';

  return NextResponse.json({
    token: {
      ...token,
      isExpired,
      isExpiringSoon,
      status,
      effectiveExpireAt,
    },
  });
}

export async function PUT(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  try {
    const { id } = params;
    const existingToken = await prisma.token.findUnique({ where: { id } });
    if (!existingToken) {
      return NextResponse.json({ error: 'Token không tồn tại' }, { status: 404 });
    }

    // =========================================================================
    // [MOD FEATURE]: KIỂM TRA QUYỀN CHỈNH SỬA TOKEN
    // =========================================================================
    if (session.role === 'SALE' && existingToken.createdById !== session.userId) {
      return NextResponse.json({ error: 'Bạn không có quyền chỉnh sửa Token của nhân viên khác!' }, { status: 403 });
    }

    const body = await req.json();

    // Check if Admin is restoring a soft-deleted token
    if (body.action === 'RESTORE' && session.role === 'ADMIN') {
      const restoredToken = await prisma.token.update({
        where: { id },
        data: {
          isDeleted: false,
          deletedAt: null,
        },
      });

      await prisma.tokenNote.create({
        data: {
          tokenId: id,
          createdById: session.userId,
          action: 'RESTORE',
          detail: `Admin [${session.displayName}] đã khôi phục lại Token bị xóa logic.`,
        },
      });

      return NextResponse.json({ success: true, message: 'Đã khôi phục Token thành công', token: restoredToken });
    }

    // Role SALE validation: block editing if token is deleted or expired
    if (session.role === 'SALE') {
      if (existingToken.isDeleted) {
        return NextResponse.json(
          { error: 'Token này đã bị xóa logic, nhân viên Sale không có quyền chỉnh sửa!' },
          { status: 403 }
        );
      }

      const now = new Date();
      if (new Date(existingToken.expireAt) < now) {
        return NextResponse.json(
          { error: 'Token này đã hết hạn sử dụng. Nhân viên Sale không được phép chỉnh sửa! Vui lòng liên hệ Admin để gia hạn.' },
          { status: 403 }
        );
      }
    }

    const {
      deviceSnMd5,
      characterUid,
      customerName,
      isTest,
      packageId,
      durationDays,
      fovMin,
      fovMax,
      bossRefreshMin,
      bossRefreshMax,
      maxMoveSpeed,
      maxAttackSpeed,
      maxMonsterRange,
      maxPickupCount,
      pickupDelayMin,
      pickupDelayMax,
      activeTabBasic,
      activeTabAdvanced,
      activeTabAutofarm,
      characterReincarnation,
      characterReincarnationSecondary,
      adminTelegrams,
      price,
      isCustom,
      noteDetail,
      parentCharacterUid,
      parentDeviceSnMd5,
      subTokenType,
    } = body;

    // =========================================================================
    // [MOD FEATURE]: CẬP NHẬT LIÊN KẾT TOKEN CHA (NV PHỤ & MÁY PHỤ)
    // =========================================================================
    let newParentId: string | null | undefined = undefined;
    const targetSn = (deviceSnMd5 !== undefined ? deviceSnMd5 : existingToken.deviceSnMd5).trim();
    const targetUid = (characterUid !== undefined ? characterUid : existingToken.characterUid).trim();

    if (subTokenType === 'NONE') {
      newParentId = null;
    } else if (subTokenType === 'CHARACTER' || (parentCharacterUid !== undefined && parentCharacterUid.trim() !== '')) {
      const cleanParentUid = String(parentCharacterUid || '').trim();
      if (!cleanParentUid) {
        newParentId = null;
      } else {
        if (cleanParentUid === targetUid) {
          return NextResponse.json({ error: 'Token Nhân vật phụ không thể tự nhận chính mình làm Token cha!' }, { status: 400 });
        }

        const foundParent = await prisma.token.findFirst({
          where: {
            characterUid: cleanParentUid,
            deviceSnMd5: targetSn,
            isDeleted: false,
          },
          orderBy: { createdAt: 'desc' },
        });

        if (!foundParent) {
          return NextResponse.json({
            error: `Không tìm thấy Token cha với UID [${cleanParentUid}] trên thiết bị này! Vui lòng kiểm tra lại.`,
          }, { status: 400 });
        }
        if (foundParent.id === id) {
          return NextResponse.json({ error: 'Token không thể tự nhận chính mình làm Token cha!' }, { status: 400 });
        }
        newParentId = foundParent.id;
      }
    } else if (subTokenType === 'DEVICE' || (parentDeviceSnMd5 !== undefined && parentDeviceSnMd5.trim() !== '')) {
      const cleanParentSn = String(parentDeviceSnMd5 || '').trim();
      if (!cleanParentSn) {
        newParentId = null;
      } else {
        if (cleanParentSn === targetSn) {
          return NextResponse.json({
            error: 'Mã máy chính không được trùng với mã máy phụ hiện tại! (Nếu cùng máy, vui lòng chọn Token Nhân Vật Phụ).',
          }, { status: 400 });
        }

        const foundParent = await prisma.token.findFirst({
          where: {
            deviceSnMd5: cleanParentSn,
            characterUid: targetUid,
            isDeleted: false,
          },
          orderBy: { createdAt: 'desc' },
        });

        if (!foundParent) {
          return NextResponse.json({
            error: `Không tìm thấy Token máy chính nào với Mã máy [${cleanParentSn}] và UID nhân vật [${targetUid}]! Vui lòng kiểm tra lại.`,
          }, { status: 400 });
        }
        if (foundParent.id === id) {
          return NextResponse.json({ error: 'Token không thể tự nhận chính mình làm Token cha!' }, { status: 400 });
        }
        newParentId = foundParent.id;
      }
    } else if (parentCharacterUid === '' || parentDeviceSnMd5 === '') {
      newParentId = null;
    }

    const newDuration = durationDays !== undefined ? Number(durationDays) : existingToken.durationDays;
    // Tính hạn sử dụng: Nếu là token con, kế thừa từ cha; nếu độc lập, tính từ createdAt
    const baseCreatedAt = new Date(existingToken.createdAt);
    let expireAt = new Date(baseCreatedAt.getTime() + newDuration * 86400 * 1000);
    const effectiveParentId = newParentId !== undefined ? newParentId : existingToken.parentId;
    if (effectiveParentId) {
      const pTok = await prisma.token.findUnique({ where: { id: effectiveParentId } });
      if (pTok) {
        expireAt = new Date(pTok.expireAt);
      }
    }
    const expireAtUnix = Math.floor(expireAt.getTime() / 1000);

    let telegramsList: string[];
    if (adminTelegrams) {
      telegramsList = Array.isArray(adminTelegrams)
        ? adminTelegrams
        : typeof adminTelegrams === 'string'
        ? adminTelegrams.split(',').map((s) => s.trim()).filter((s) => s)
        : ['@admin1', '@admin2'];
    } else {
      try {
        telegramsList = JSON.parse(existingToken.adminTelegrams);
      } catch {
        telegramsList = ['@admin1', '@admin2'];
      }
    }

    const updatedPrimary = characterReincarnation !== undefined ? Number(characterReincarnation) : existingToken.characterReincarnation;
    const updatedSecondary = characterReincarnationSecondary !== undefined 
      ? Number(characterReincarnationSecondary) 
      : (existingToken.characterReincarnationSecondary ?? (updatedPrimary > 1 ? updatedPrimary - 1 : 1));

    const updatedParams = {
      deviceSnMd5: (deviceSnMd5 !== undefined ? deviceSnMd5 : existingToken.deviceSnMd5).trim(),
      characterUid: (characterUid !== undefined ? characterUid : existingToken.characterUid).trim(),
      durationDays: newDuration,
      expireAtUnix,
      fovMin: fovMin !== undefined ? Number(fovMin) : existingToken.fovMin,
      fovMax: fovMax !== undefined ? Number(fovMax) : existingToken.fovMax,
      bossRefreshMin: bossRefreshMin !== undefined ? Number(bossRefreshMin) : existingToken.bossRefreshMin,
      bossRefreshMax: bossRefreshMax !== undefined ? Number(bossRefreshMax) : existingToken.bossRefreshMax,
      maxMoveSpeed: maxMoveSpeed !== undefined ? Number(maxMoveSpeed) : existingToken.maxMoveSpeed,
      maxAttackSpeed: maxAttackSpeed !== undefined ? Number(maxAttackSpeed) : existingToken.maxAttackSpeed,
      maxMonsterRange: maxMonsterRange !== undefined ? Number(maxMonsterRange) : existingToken.maxMonsterRange,
      maxPickupCount: maxPickupCount !== undefined ? Number(maxPickupCount) : existingToken.maxPickupCount,
      pickupDelayMin: pickupDelayMin !== undefined ? Number(pickupDelayMin) : existingToken.pickupDelayMin,
      pickupDelayMax: pickupDelayMax !== undefined ? Number(pickupDelayMax) : existingToken.pickupDelayMax,
      activeTabBasic: activeTabBasic !== undefined ? Boolean(activeTabBasic) : existingToken.activeTabBasic,
      activeTabAdvanced: activeTabAdvanced !== undefined ? Boolean(activeTabAdvanced) : existingToken.activeTabAdvanced,
      activeTabAutofarm: activeTabAutofarm !== undefined ? Boolean(activeTabAutofarm) : existingToken.activeTabAutofarm,
      characterReincarnation: updatedPrimary,
      characterReincarnationSecondary: updatedSecondary,
      adminTelegrams: telegramsList,
    };

    const { encryptedToken } = generateEncryptedToken(updatedParams);

    const updatedToken = await prisma.token.update({
      where: { id },
      data: {
        deviceSnMd5: updatedParams.deviceSnMd5,
        characterUid: updatedParams.characterUid,
        customerName: customerName !== undefined ? (customerName ? String(customerName).trim() : null) : existingToken.customerName,
        isTest: isTest !== undefined ? Boolean(isTest) : existingToken.isTest,
        packageId: packageId !== undefined ? packageId : existingToken.packageId,
        durationDays: updatedParams.durationDays,
        expireAt,
        fovMin: updatedParams.fovMin,
        fovMax: updatedParams.fovMax,
        bossRefreshMin: updatedParams.bossRefreshMin,
        bossRefreshMax: updatedParams.bossRefreshMax,
        maxMoveSpeed: updatedParams.maxMoveSpeed,
        maxAttackSpeed: updatedParams.maxAttackSpeed,
        maxMonsterRange: updatedParams.maxMonsterRange,
        maxPickupCount: updatedParams.maxPickupCount,
        pickupDelayMin: updatedParams.pickupDelayMin,
        pickupDelayMax: updatedParams.pickupDelayMax,
        activeTabBasic: updatedParams.activeTabBasic,
        activeTabAdvanced: updatedParams.activeTabAdvanced,
        activeTabAutofarm: updatedParams.activeTabAutofarm,
        characterReincarnation: updatedParams.characterReincarnation,
        characterReincarnationSecondary: updatedParams.characterReincarnationSecondary,
        adminTelegrams: JSON.stringify(telegramsList),
        price: price !== undefined ? Number(price) : existingToken.price,
        isCustom: isCustom !== undefined ? Boolean(isCustom) : existingToken.isCustom,
        encryptedToken,
        parentId: newParentId !== undefined ? newParentId : existingToken.parentId,
      },
    });

    // Đồng bộ thời hạn cho tất cả các Token Con nếu Token Cha được gia hạn/cập nhật hạn
    await prisma.token.updateMany({
      where: { parentId: id },
      data: { expireAt },
    });

    const auditDetail = noteDetail
      ? noteDetail.trim()
      : `Cập nhật cấu hình Token (MD5: ${updatedParams.deviceSnMd5}, UID: ${updatedParams.characterUid}, Hạn: ${updatedParams.durationDays} ngày).`;

    await prisma.tokenNote.create({
      data: {
        tokenId: id,
        createdById: session.userId,
        action: 'UPDATE',
        detail: auditDetail,
      },
    });

    return NextResponse.json({ success: true, token: updatedToken });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi cập nhật Token' }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  try {
    const { id } = params;
    const token = await prisma.token.findUnique({ where: { id } });
    if (!token) {
      return NextResponse.json({ error: 'Token không tồn tại' }, { status: 404 });
    }

    // =========================================================================
    // [MOD FEATURE]: KIỂM TRA QUYỀN XÓA TOKEN
    // =========================================================================
    if (session.role === 'SALE' && token.createdById !== session.userId) {
      return NextResponse.json({ error: 'Bạn không có quyền xóa Token của nhân viên khác!' }, { status: 403 });
    }

    const { searchParams } = new URL(req.url);
    const isHardDelete = searchParams.get('hard') === 'true';

    // If SALE staff or soft-delete requested: Soft Delete (Xóa Logic)
    if (session.role === 'SALE' || (!isHardDelete && token.isDeleted === false)) {
      await prisma.token.update({
        where: { id },
        data: {
          isDeleted: true,
          deletedAt: new Date(),
        },
      });

      // Log Soft Delete in TokenNote
      await prisma.tokenNote.create({
        data: {
          tokenId: id,
          createdById: session.userId,
          action: 'SOFT_DELETE',
          detail: `Nhân viên [${session.displayName}] (${session.role}) đã thực hiện xóa logic (Soft Delete) Token này. Token đã bị hủy kích hoạt trên Client Mod.`,
        },
      });

      return NextResponse.json({
        success: true,
        isSoftDelete: true,
        message: 'Đã hủy kích hoạt và xóa logic Token. Nhật ký đã được lưu cho Admin kiểm tra.',
      });
    }

    // Only ADMIN can perform Hard Delete (Xóa Vĩnh Viễn khỏi DB)
    if (session.role !== 'ADMIN') {
      return NextResponse.json({ error: 'Chỉ Admin mới có quyền xóa vĩnh viễn Token khỏi cơ sở dữ liệu!' }, { status: 403 });
    }

    // Admin Hard Delete - Atomically delete dependent notes and token
    await prisma.$transaction([
      prisma.tokenNote.deleteMany({ where: { tokenId: id } }),
      prisma.token.delete({ where: { id } }),
    ]);

    return NextResponse.json({ success: true, isHardDelete: true, message: 'Admin đã xóa vĩnh viễn Token thành công' });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi xóa Token' }, { status: 500 });
  }
}
