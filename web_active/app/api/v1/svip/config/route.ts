import { NextRequest, NextResponse } from 'next/server';
import { prisma, ensureInitialSeed } from '@/lib/db';

export const dynamic = 'force-dynamic';

// =========================================================================
// [MOD FEATURE]: API XÁC THỰC BẢN QUYỀN ONLINE CHO BẢN CLIENT (SVIP)
// Mô tả: Kiểm tra token active theo Device SN MD5 và Character UID (hỗ trợ UID = "ALL").
//        Ghi nhận lịch sử đăng nhập DeviceLoginHistory khi isLogin = 1.
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

    if (!sn) {
      return NextResponse.json({ error: 'Thiếu tham số sn (Mã thiết bị MD5)' }, { status: 400 });
    }

    const cleanSn = sn.trim();
    const cleanUid = (uid || '').trim();

    // Tìm tất cả token SVIP còn hiệu lực của máy này (khớp UID hoặc ALL)
    const matchingTokens = await prisma.token.findMany({
      where: {
        deviceSnMd5: cleanSn,
        type: 'SVIP',
        isDeleted: false,
        characterUid: cleanUid !== '' ? { in: [cleanUid, 'ALL', 'all'] } : { in: ['ALL', 'all'] },
      },
      orderBy: { createdAt: 'desc' },
    });

    let token = null;
    if (matchingTokens.length > 0) {
      // Ưu tiên token gán đích danh UID nhân vật, nếu không có mới lấy token ALL
      token = matchingTokens.find((t) => t.characterUid.toUpperCase() === cleanUid.toUpperCase()) ||
              matchingTokens.find((t) => t.characterUid.toUpperCase() === 'ALL') ||
              matchingTokens[0];
    }

    if (!token) {
      // Kiểm tra xem có token SVIP nào bị xóa không
      const deletedToken = await prisma.token.findFirst({
        where: {
          deviceSnMd5: cleanSn,
          type: 'SVIP',
          isDeleted: true,
        },
        orderBy: { createdAt: 'desc' },
      });

      if (deletedToken) {
        return NextResponse.json({
          error: 'Token SVIP bản quyền đã bị thu hồi hoặc xóa bởi quản trị viên',
          status: 'DELETED',
          isDeleted: true,
        }, { status: 403 });
      }

      return NextResponse.json({
        error: 'Chưa có bản quyền SVIP cho thiết bị này hoặc UID không hợp lệ!',
        status: 'NOT_FOUND',
      }, { status: 444 });
    }

    const now = new Date();
    if (new Date(token.expireAt) < now) {
      return NextResponse.json({
        error: 'Token SVIP đã hết hạn sử dụng. Vui lòng gia hạn để tiếp tục!',
        status: 'EXPIRED',
        isExpired: true,
        expireAt: token.expireAt,
      }, { status: 403 });
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
      console.error('[SVIP Update] Failed to update lastOnline:', updateErr);
    }

    return NextResponse.json({
      success: true,
      status: 'ACTIVE',
      isExpired: false,
      token: token.encryptedToken,
      expireAt: token.expireAt,
      durationDays: token.durationDays,
      characterUid: token.characterUid,
      mainTier: token.characterReincarnation,
      subTier: token.characterReincarnationSecondary,
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi máy chủ khi xác thực SVIP' }, { status: 500 });
  }
}
