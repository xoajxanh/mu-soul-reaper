import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser } from '@/lib/auth';
import { prisma } from '@/lib/db';

export const dynamic = 'force-dynamic';

// =========================================================================
// [MOD FEATURE]: API CHI TIẾT LỊCH SỬ THIẾT BỊ (ADMIN ONLY)
// Mô tả: Truy vấn toàn bộ dòng thời gian đăng nhập của 1 mã máy MD5
// =========================================================================

export async function GET(req: NextRequest, { params }: { params: { md5: string } }) {
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  const { md5 } = params;
  const cleanMd5 = decodeURIComponent(md5).trim();

  try {
    if (session.role !== 'ADMIN') {
      const hasPerm = await prisma.token.findFirst({
        where: {
          deviceSnMd5: cleanMd5,
          createdById: session.userId,
          isDeleted: false,
        },
      });
      if (!hasPerm) {
        return NextResponse.json({ error: 'Bạn không có quyền xem thông tin thiết bị này!' }, { status: 403 });
      }
    }

    const [historyList, tokens] = await Promise.all([
      prisma.deviceLoginHistory.findMany({
        where: { deviceSnMd5: cleanMd5 },
        orderBy: { createdAt: 'desc' },
        take: 100, // Tối đa 100 lần đăng nhập gần nhất
      }),
      prisma.token.findMany({
        where: {
          deviceSnMd5: cleanMd5,
          isDeleted: false,
          ...(session.role !== 'ADMIN' ? { createdById: session.userId } : {}),
        },
        include: {
          createdBy: { select: { displayName: true, username: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return NextResponse.json({
      deviceSnMd5: cleanMd5,
      totalRecords: historyList.length,
      history: historyList,
      tokens,
    });
  } catch (err: any) {
    console.error('[History Detail API] Error:', err);
    return NextResponse.json({ error: err.message || 'Lỗi khi tải chi tiết lịch sử thiết bị' }, { status: 500 });
  }
}
