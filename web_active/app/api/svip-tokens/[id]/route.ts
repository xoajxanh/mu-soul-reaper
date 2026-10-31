import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser } from '@/lib/auth';
import { prisma } from '@/lib/db';
import { generateSvipEncryptedToken } from '@/lib/keygen';

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  const { id } = params;
  const token = await prisma.token.findUnique({
    where: { id },
    include: {
      createdBy: { select: { id: true, username: true, displayName: true, role: true } },
      notes: {
        include: {
          createdBy: { select: { id: true, username: true, displayName: true } },
        },
        orderBy: { createdAt: 'desc' },
      },
    },
  });

  if (!token || token.type !== 'SVIP') {
    return NextResponse.json({ error: 'Token SVIP không tồn tại' }, { status: 404 });
  }

  if (session.role === 'SALE' && token.createdById !== session.userId) {
    return NextResponse.json({ error: 'Bạn không có quyền xem Token của nhân viên khác!' }, { status: 403 });
  }

  const now = new Date();
  const isExpired = new Date(token.expireAt) < now;
  const threeDaysLater = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
  const isExpiringSoon = !isExpired && new Date(token.expireAt) <= threeDaysLater;
  const status = token.isDeleted ? 'DELETED' : isExpired ? 'EXPIRED' : isExpiringSoon ? 'EXPIRING_SOON' : 'ACTIVE';

  return NextResponse.json({
    token: {
      ...token,
      isExpired,
      isExpiringSoon,
      status,
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
    if (!existingToken || existingToken.type !== 'SVIP') {
      return NextResponse.json({ error: 'Không tìm thấy Token SVIP' }, { status: 404 });
    }

    if (session.role === 'SALE' && existingToken.createdById !== session.userId) {
      return NextResponse.json({ error: 'Bạn không có quyền chỉnh sửa Token của người khác!' }, { status: 403 });
    }

    const body = await req.json();
    const {
      deviceSnMd5,
      characterUid,
      customerName,
      durationDays,
      startDate,
      mainTier,
      subTier,
      price,
      isTest,
      notes,
    } = body;

    const cleanDeviceSn = deviceSnMd5 ? String(deviceSnMd5).trim() : existingToken.deviceSnMd5;
    const cleanUid = characterUid ? String(characterUid).trim() : existingToken.characterUid;
    const duration = durationDays !== undefined ? parseFloat(durationDays) : existingToken.durationDays;

    if (cleanUid.toUpperCase() === 'ALL' && session.role !== 'ADMIN') {
      return NextResponse.json({
        error: 'Chỉ Quản trị viên (Admin) mới có quyền tạo hoặc đổi Token SVIP sang UID ALL!',
      }, { status: 403 });
    }

    // Tự động lấy Ngày Bắt Đầu, cộng thêm với số ngày thời lượng sử dụng
    let startDateTime = new Date();
    if (startDate) {
      const parsedStart = new Date(startDate);
      if (!isNaN(parsedStart.getTime())) {
        startDateTime = parsedStart;
      }
    }

    const expireAt = new Date(startDateTime.getTime() + duration * 86400 * 1000);
    const startTimeUnix = Math.floor(startDateTime.getTime() / 1000);

    const parsedMain = mainTier !== undefined ? Number(mainTier) : existingToken.characterReincarnation;
    const parsedSub = subTier !== undefined ? Number(subTier) : existingToken.characterReincarnationSecondary;
    const parsedIsTest = isTest !== undefined ? Boolean(isTest) : existingToken.isTest;
    const parsedPrice = parsedIsTest ? 0 : (price !== undefined ? Number(price) : existingToken.price);

    // Sinh lại Token mới theo chuẩn Keygen.ps1
    const { encryptedToken } = generateSvipEncryptedToken({
      deviceSnMd5: cleanDeviceSn,
      characterUid: cleanUid,
      mainTier: parsedMain,
      subTier: parsedSub,
      durationDays: duration,
      startTimeUnix,
    });

    const updatedToken = await prisma.token.update({
      where: { id },
      data: {
        deviceSnMd5: cleanDeviceSn,
        characterUid: cleanUid,
        customerName: customerName !== undefined ? (customerName ? String(customerName).trim() : null) : existingToken.customerName,
        durationDays: duration,
        expireAt,
        characterReincarnation: parsedMain,
        characterReincarnationSecondary: parsedSub,
        price: parsedPrice,
        isTest: parsedIsTest,
        encryptedToken,
      },
    });

    if (notes && String(notes).trim() !== '') {
      await prisma.tokenNote.create({
        data: {
          tokenId: id,
          createdById: session.userId,
          action: 'UPDATE',
          detail: String(notes).trim(),
        },
      });
    }

    return NextResponse.json({
      success: true,
      token: updatedToken,
      message: 'Cập nhật Token SVIP thành công!',
    });
  } catch (err: any) {
    console.error('[SVIP Tokens] Error updating token:', err);
    return NextResponse.json({ error: err.message || 'Lỗi khi cập nhật Token SVIP' }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  const { id } = params;
  const token = await prisma.token.findUnique({ where: { id } });
  if (!token || token.type !== 'SVIP') {
    return NextResponse.json({ error: 'Không tìm thấy Token SVIP' }, { status: 404 });
  }

  if (session.role === 'SALE' && token.createdById !== session.userId) {
    return NextResponse.json({ error: 'Bạn không có quyền xóa Token của người khác!' }, { status: 403 });
  }

  const { searchParams } = new URL(req.url);
  const action = searchParams.get('action') || 'soft';

  if (action === 'restore') {
    await prisma.token.update({
      where: { id },
      data: { isDeleted: false, deletedAt: null },
    });
    await prisma.tokenNote.create({
      data: {
        tokenId: id,
        createdById: session.userId,
        action: 'RESTORE',
        detail: 'Đã khôi phục Token SVIP',
      },
    });
    return NextResponse.json({ success: true, message: 'Đã khôi phục Token SVIP' });
  }

  if (action === 'hard' && session.role === 'ADMIN') {
    await prisma.tokenNote.deleteMany({ where: { tokenId: id } });
    await prisma.token.delete({ where: { id } });
    return NextResponse.json({ success: true, message: 'Đã xóa vĩnh viễn Token SVIP' });
  }

  // Soft delete
  await prisma.token.update({
    where: { id },
    data: { isDeleted: true, deletedAt: new Date() },
  });

  await prisma.tokenNote.create({
    data: {
      tokenId: id,
      createdById: session.userId,
      action: 'SOFT_DELETE',
      detail: 'Đã xóa (thu hồi) Token SVIP',
    },
  });

  return NextResponse.json({ success: true, message: 'Đã thu hồi Token SVIP' });
}
