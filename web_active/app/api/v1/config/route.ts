import { NextRequest, NextResponse } from 'next/server';
import { prisma, ensureInitialSeed } from '@/lib/db';
import { generateEncryptedToken } from '@/lib/keygen';

export const dynamic = 'force-dynamic';

// =========================================================================
// [MOD FEATURE]: HỖ TRỢ TOKEN PHỤ (PARENT - CHILD SUB-TOKEN)
// Mô tả: Kiểm tra kế thừa trạng thái ACTIVE/EXPIRED và đóng gói expire_time theo Token Cha
// =========================================================================

export async function GET(req: NextRequest) {
  try {
    await ensureInitialSeed();
    const { searchParams } = new URL(req.url);
    const sn = searchParams.get('sn');
    const uid = searchParams.get('uid');
    const roleName = searchParams.get('name') || searchParams.get('roleName') || '';
    const serverName = searchParams.get('server') || searchParams.get('serverName') || '';
    const isLogin = searchParams.get('isLogin') === '1';

    if (!sn || !uid) {
      return NextResponse.json({ error: 'Thiếu tham số sn (Serial MD5) hoặc uid (Character ID)' }, { status: 400 });
    }

    const cleanSn = sn.trim();
    const cleanUid = uid.trim();

    const token = await prisma.token.findFirst({
      where: {
        deviceSnMd5: cleanSn,
        characterUid: cleanUid,
        type: { not: 'SVIP' },
        isDeleted: false,
      },
      include: {
        parent: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!token) {
      // Kiểm tra xem có token đã bị xóa hay không để báo lỗi chính xác
      const deletedToken = await prisma.token.findFirst({
        where: {
          deviceSnMd5: cleanSn,
          characterUid: cleanUid,
          type: { not: 'SVIP' },
          isDeleted: true,
        },
        orderBy: { createdAt: 'desc' },
      });

      if (deletedToken) {
        return NextResponse.json({
          error: 'Token bản quyền đã bị thu hồi hoặc xóa bởi quản trị viên',
          status: 'DELETED',
          isDeleted: true,
        }, { status: 403 });
      }

      return NextResponse.json({
        error: 'Không tìm thấy Token bản quyền tương ứng với thiết bị và nhân vật này',
        status: 'NOT_FOUND',
      }, { status: 444 });
    }

    const now = new Date();

    // =========================================================================
    // [MOD FEATURE]: XỬ LÝ TOKEN PHỤ (Kế thừa trạng thái & hạn dùng của Token Cha)
    // =========================================================================
    let activeTokenToReturn = token.encryptedToken;
    let activeExpireAt = token.expireAt;
    let activeDurationDays = token.durationDays;
    let isSubTokenResult = false;
    let parentUidResult: string | undefined = undefined;

    if (token.parentId && token.parent) {
      const isDeviceSub = token.parent.deviceSnMd5 !== token.deviceSnMd5;
      const parentLabel = isDeviceSub
        ? `Mã máy chính: ${token.parent.deviceSnMd5}`
        : `UID chính: ${token.parent.characterUid}`;

      if (token.parent.isDeleted) {
        return NextResponse.json({
          error: `Token chính liên kết (${parentLabel}) đã bị thu hồi hoặc xóa bởi quản trị viên`,
          status: 'DELETED',
          isDeleted: true,
          isSubToken: true,
          subTokenType: isDeviceSub ? 'DEVICE' : 'CHARACTER',
          parentCharacterUid: token.parent.characterUid,
          parentDeviceSnMd5: token.parent.deviceSnMd5,
        }, { status: 403 });
      }

      const parentExpireAt = new Date(token.parent.expireAt);
      if (parentExpireAt < now) {
        return NextResponse.json({
          error: `Token chính liên kết (${parentLabel}) đã hết hạn sử dụng. Vui lòng gia hạn Token máy chính!`,
          status: 'EXPIRED',
          isExpired: true,
          expireAt: token.parent.expireAt,
          isSubToken: true,
          subTokenType: isDeviceSub ? 'DEVICE' : 'CHARACTER',
          parentCharacterUid: token.parent.characterUid,
          parentDeviceSnMd5: token.parent.deviceSnMd5,
        }, { status: 403 });
      }

      // Token Cha còn hạn -> Token Phụ HỢP LỆ & ACTIVE!
      let parsedTelegrams: string[] = ['@admin1', '@admin2'];
      try {
        parsedTelegrams = JSON.parse(token.adminTelegrams);
      } catch {
        parsedTelegrams = ['@admin1', '@admin2'];
      }

      const parentExpireUnix = Math.floor(parentExpireAt.getTime() / 1000);
      const { encryptedToken: dynamicToken } = generateEncryptedToken({
        deviceSnMd5: token.deviceSnMd5,
        characterUid: token.characterUid,
        durationDays: token.parent.durationDays,
        expireAtUnix: parentExpireUnix,
        fovMin: token.fovMin,
        fovMax: token.fovMax,
        bossRefreshMin: token.bossRefreshMin,
        bossRefreshMax: token.bossRefreshMax,
        maxMoveSpeed: token.maxMoveSpeed,
        maxAttackSpeed: token.maxAttackSpeed,
        maxMonsterRange: token.maxMonsterRange,
        maxPickupCount: token.maxPickupCount,
        pickupDelayMin: token.pickupDelayMin,
        pickupDelayMax: token.pickupDelayMax,
        activeTabBasic: token.activeTabBasic,
        activeTabAdvanced: token.activeTabAdvanced,
        activeTabAutofarm: token.activeTabAutofarm,
        characterReincarnation: token.characterReincarnation,
        characterReincarnationSecondary: token.characterReincarnationSecondary,
        adminTelegrams: parsedTelegrams,
      });

      activeTokenToReturn = dynamicToken;
      activeExpireAt = token.parent.expireAt;
      activeDurationDays = token.parent.durationDays;
      isSubTokenResult = true;
      parentUidResult = token.parent.characterUid;
    } else {
      // Token độc lập / Token chính
      if (new Date(token.expireAt) < now) {
        return NextResponse.json({
          error: 'Token bản quyền đã hết hạn sử dụng',
          status: 'EXPIRED',
          isExpired: true,
          expireAt: token.expireAt,
          isSubToken: false,
        }, { status: 403 });
      }
    }

    // =========================================================================
    // [MOD FEATURE]: CHỐNG CHƠI SONG SONG TRÊN CÙNG MÃ MÁY (ANTI-CONCURRENT 75S)
    // Mô tả: Kiểm tra nếu trên cùng mã máy có nhân vật/token khác vừa online trong vòng 75s
    // =========================================================================
    const thresholdDate = new Date(now.getTime() - 75 * 1000);
    const concurrentToken = await prisma.token.findFirst({
      where: {
        id: { not: token.id },
        deviceSnMd5: cleanSn,
        isDeleted: false,
        lastOnline: { gte: thresholdDate },
      },
      orderBy: { lastOnline: 'desc' },
    });

    if (concurrentToken) {
      const otherName = concurrentToken.lastCharacterName || concurrentToken.characterUid || 'khác';
      return NextResponse.json({
        error: `Mã máy này đang có nhân vật [${otherName}] đang chơi! Gói phụ chỉ được chơi luân phiên, không thể mở 2 acc song song cùng lúc.`,
        status: 'CONCURRENT_BLOCKED',
      }, { status: 403 });
    }

    // =========================================================================
    // [MOD FEATURE]: CẬP NHẬT TRẠNG THÁI ONLINE VÀ THÔNG TIN NHÂN VẬT (HEARTBEAT)
    // Mô tả: Lưu lastOnline, lastCharacterName, lastServerName mỗi khi client ping
    // =========================================================================
    try {
      await prisma.token.update({
        where: { id: token.id },
        data: {
          lastOnline: now,
          ...(roleName && roleName.trim() !== '' ? { lastCharacterName: roleName.trim() } : {}),
          ...(serverName && serverName.trim() !== '' ? { lastServerName: serverName.trim() } : {}),
        },
      });
    } catch (updateErr) {
      console.error('[Config Update] Failed to update lastOnline:', updateErr);
    }

    return NextResponse.json({
      success: true,
      status: 'ACTIVE',
      isExpired: false,
      token: activeTokenToReturn,
      expireAt: activeExpireAt,
      durationDays: activeDurationDays,
      isSubToken: isSubTokenResult,
      ...(parentUidResult ? { parentCharacterUid: parentUidResult } : {}),
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi server khi xử lý cấu hình' }, { status: 500 });
  }
}
