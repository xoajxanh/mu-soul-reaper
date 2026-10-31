import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser } from '@/lib/auth';
import { prisma } from '@/lib/db';

export const dynamic = 'force-dynamic';

export async function PUT(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session || (session.role !== 'ADMIN' && session.role !== 'SALE')) {
    return NextResponse.json({ error: 'Bạn không có quyền cập nhật gói VIP' }, { status: 403 });
  }

  try {
    const { id } = params;
    const body = await req.json();

    const updatedPkg = await prisma.vipPackage.update({
      where: { id },
      data: {
        name: body.name ? body.name.trim() : undefined,
        durationDays: body.durationDays !== undefined ? Number(body.durationDays) : undefined,
        fovMin: body.fovMin !== undefined ? Number(body.fovMin) : undefined,
        fovMax: body.fovMax !== undefined ? Number(body.fovMax) : undefined,
        bossRefreshMin: body.bossRefreshMin !== undefined ? Number(body.bossRefreshMin) : undefined,
        bossRefreshMax: body.bossRefreshMax !== undefined ? Number(body.bossRefreshMax) : undefined,
        maxMoveSpeed: body.maxMoveSpeed !== undefined ? Number(body.maxMoveSpeed) : undefined,
        maxAttackSpeed: body.maxAttackSpeed !== undefined ? Number(body.maxAttackSpeed) : undefined,
        maxMonsterRange: body.maxMonsterRange !== undefined ? Number(body.maxMonsterRange) : undefined,
        maxPickupCount: body.maxPickupCount !== undefined ? Number(body.maxPickupCount) : undefined,
        pickupDelayMin: body.pickupDelayMin !== undefined ? Number(body.pickupDelayMin) : undefined,
        pickupDelayMax: body.pickupDelayMax !== undefined ? Number(body.pickupDelayMax) : undefined,
        activeTabBasic: body.activeTabBasic !== undefined ? Boolean(body.activeTabBasic) : undefined,
        activeTabAdvanced: body.activeTabAdvanced !== undefined ? Boolean(body.activeTabAdvanced) : undefined,
        activeTabAutofarm: body.activeTabAutofarm !== undefined ? Boolean(body.activeTabAutofarm) : undefined,
        price: body.price !== undefined ? Number(body.price) : undefined,
      },
    });

    return NextResponse.json({ success: true, package: updatedPkg });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi cập nhật gói VIP' }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session || (session.role !== 'ADMIN' && session.role !== 'SALE')) {
    return NextResponse.json({ error: 'Bạn không có quyền xóa gói VIP' }, { status: 403 });
  }

  try {
    const { id } = params;
    await prisma.vipPackage.delete({
      where: { id },
    });

    return NextResponse.json({ success: true, message: 'Đã xóa gói VIP' });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi xóa gói VIP' }, { status: 500 });
  }
}
