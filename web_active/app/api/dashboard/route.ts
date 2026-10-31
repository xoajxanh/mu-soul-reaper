import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser } from '@/lib/auth';
import { prisma, ensureInitialSeed } from '@/lib/db';

export const dynamic = 'force-dynamic';


export async function GET(req: NextRequest) {
  await ensureInitialSeed();
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const saleId = searchParams.get('saleId');
  const typeParam = searchParams.get('type') || searchParams.get('tab') || 'CUSTOMER';
  const targetType = typeParam.toUpperCase() === 'SVIP' ? 'SVIP' : 'CUSTOMER';

  const now = new Date();
  const threeDaysLater = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
  const startOfCurrentMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  // =========================================================================
  // [MOD FEATURE]: PHÂN QUYỀN VÀ LỌC DỮ LIỆU DASHBOARD THEO SALE & TYPE (CUSTOMER/SVIP)
  // Mô tả: Lọc dữ liệu theo tab Customer hoặc SVIP, bỏ qua hoàn toàn token isTest
  // =========================================================================
  let targetUserId: string | null = null;
  if (session.role === 'SALE') {
    targetUserId = session.userId;
  } else if (session.role === 'ADMIN' && saleId && saleId !== 'ALL') {
    targetUserId = saleId;
  }

  const notTestWhere: any = { isTest: false, isDeleted: false, type: targetType };
  if (targetUserId) {
    notTestWhere.createdById = targetUserId;
  }

  const [
    totalRevenueAgg,
    monthRevenueAgg,
    totalTokensCount,
    monthTokensCount,
    expiringSoonCount,
    expiredCount,
    recentTokens,
  ] = await Promise.all([
    prisma.token.aggregate({ where: notTestWhere, _sum: { price: true } }),
    prisma.token.aggregate({
      where: { ...notTestWhere, createdAt: { gte: startOfCurrentMonth } },
      _sum: { price: true },
    }),
    prisma.token.count({ where: notTestWhere }),
    prisma.token.count({ where: { ...notTestWhere, createdAt: { gte: startOfCurrentMonth } } }),
    prisma.token.count({
      where: { ...notTestWhere, expireAt: { gte: now, lte: threeDaysLater } },
    }),
    prisma.token.count({ where: { ...notTestWhere, expireAt: { lt: now } } }),
    prisma.token.findMany({
      where: notTestWhere,
      take: 5,
      orderBy: { createdAt: 'desc' },
      include: {
        createdBy: { select: { displayName: true, username: true } },
        vipPackage: { select: { name: true } },
      },
    }),
  ]);

  // Aggregate monthly data for current year (Jan-Dec)
  const currentYear = now.getFullYear();
  const monthlyChartData = [];

  for (let month = 0; month < 12; month++) {
    const startOfMonth = new Date(currentYear, month, 1);
    const endOfMonth = new Date(currentYear, month + 1, 0, 23, 59, 59);

    const [mRevenue, mCount] = await Promise.all([
      prisma.token.aggregate({
        where: { ...notTestWhere, createdAt: { gte: startOfMonth, lte: endOfMonth } },
        _sum: { price: true },
      }),
      prisma.token.count({
        where: { ...notTestWhere, createdAt: { gte: startOfMonth, lte: endOfMonth } },
      }),
    ]);

    monthlyChartData.push({
      month: `Thg ${month + 1}`,
      revenue: mRevenue._sum.price || 0,
      tokens: mCount,
    });
  }

  // =========================================================================
  // [MOD FEATURE]: THỐNG KÊ DOANH SỐ TỪNG NHÂN VIÊN CHO ADMIN
  // Mô tả: Truy vấn danh sách và chỉ số hiệu suất của từng tài khoản nhân viên
  // =========================================================================
  let salesStats: any[] = [];
  let salesList: any[] = [];

  if (session.role === 'ADMIN') {
    const users = await prisma.user.findMany({
      select: { id: true, username: true, displayName: true, role: true },
      orderBy: { displayName: 'asc' },
    });
    salesList = users;

    salesStats = await Promise.all(
      users.map(async (u) => {
        const [uTotalRev, uTotalCount, uMonthRev, uMonthCount] = await Promise.all([
          prisma.token.aggregate({
            where: { isTest: false, isDeleted: false, type: targetType, createdById: u.id },
            _sum: { price: true },
          }),
          prisma.token.count({
            where: { isTest: false, isDeleted: false, type: targetType, createdById: u.id },
          }),
          prisma.token.aggregate({
            where: { isTest: false, isDeleted: false, type: targetType, createdById: u.id, createdAt: { gte: startOfCurrentMonth } },
            _sum: { price: true },
          }),
          prisma.token.count({
            where: { isTest: false, isDeleted: false, type: targetType, createdById: u.id, createdAt: { gte: startOfCurrentMonth } },
          }),
        ]);

        return {
          userId: u.id,
          username: u.username,
          displayName: u.displayName,
          role: u.role,
          totalRevenue: uTotalRev._sum.price || 0,
          totalTokens: uTotalCount,
          monthRevenue: uMonthRev._sum.price || 0,
          monthTokens: uMonthCount,
        };
      })
    );

    // Sắp xếp theo doanh thu tháng giảm dần
    salesStats.sort((a, b) => b.monthRevenue - a.monthRevenue || b.totalRevenue - a.totalRevenue);
  }

  return NextResponse.json({
    summary: {
      totalRevenue: totalRevenueAgg._sum.price || 0,
      monthRevenue: monthRevenueAgg._sum.price || 0,
      totalTokens: totalTokensCount,
      monthTokens: monthTokensCount,
      expiringSoon: expiringSoonCount,
      expired: expiredCount,
    },
    monthlyChartData,
    recentTokens,
    salesStats,
    salesList,
    selectedSaleId: targetUserId || 'ALL',
    selectedType: targetType,
  });
}
