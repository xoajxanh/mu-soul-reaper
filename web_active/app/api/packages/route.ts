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

  const packages = await prisma.vipPackage.findMany({
    orderBy: { durationDays: 'asc' },
  });

  return NextResponse.json({ packages });
}

export async function POST(req: NextRequest) {
  const session = await getSessionUser(req);
  if (!session || (session.role !== 'ADMIN' && session.role !== 'SALE')) {
    return NextResponse.json({ error: 'Bạn không có quyền tạo gói VIP' }, { status: 403 });
  }

  try {
    const body = await req.json();
    const {
      name,
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
      price,
    } = body;

    if (!name || !durationDays) {
      return NextResponse.json({ error: 'Tên gói và số ngày hết hạn là bắt buộc' }, { status: 400 });
    }

    const newPkg = await prisma.vipPackage.create({
      data: {
        name: name.trim(),
        durationDays: Number(durationDays),
        fovMin: Number(fovMin ?? 20),
        fovMax: Number(fovMax ?? 90),
        bossRefreshMin: Number(bossRefreshMin ?? 1),
        bossRefreshMax: Number(bossRefreshMax ?? 60),
        maxMoveSpeed: Number(maxMoveSpeed ?? 2.5),
        maxAttackSpeed: Number(maxAttackSpeed ?? 2.5),
        maxMonsterRange: Number(maxMonsterRange ?? 50),
        maxPickupCount: Number(maxPickupCount ?? 100),
        pickupDelayMin: Number(pickupDelayMin ?? 100),
        pickupDelayMax: Number(pickupDelayMax ?? 500),
        activeTabBasic: Boolean(activeTabBasic ?? true),
        activeTabAdvanced: Boolean(activeTabAdvanced ?? true),
        activeTabAutofarm: Boolean(activeTabAutofarm ?? true),
        price: Number(price ?? 0),
      },
    });

    return NextResponse.json({ success: true, package: newPkg });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi tạo gói VIP' }, { status: 500 });
  }
}
