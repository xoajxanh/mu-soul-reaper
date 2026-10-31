import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser, hashPassword } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function PUT(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session || session.role !== 'ADMIN') {
    return NextResponse.json({ error: 'Không có quyền (Chỉ Admin)' }, { status: 403 });
  }

  try {
    const { id } = params;
    const body = await req.json();
    const { displayName, role, newPassword } = body;

    const updateData: any = {};
    if (displayName) updateData.displayName = displayName.trim();
    if (role && ['ADMIN', 'SALE'].includes(role)) updateData.role = role;
    if (newPassword && newPassword.trim() !== '') {
      updateData.passwordHash = hashPassword(newPassword.trim());
    }

    const updatedUser = await prisma.user.update({
      where: { id },
      data: updateData,
      select: { id: true, username: true, displayName: true, role: true, updatedAt: true },
    });

    return NextResponse.json({ success: true, user: updatedUser });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi cập nhật tài khoản' }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session || session.role !== 'ADMIN') {
    return NextResponse.json({ error: 'Không có quyền (Chỉ Admin)' }, { status: 403 });
  }

  try {
    const { id } = params;
    if (id === session.userId) {
      return NextResponse.json({ error: 'Không thể tự xóa chính mình' }, { status: 400 });
    }

    await prisma.user.delete({
      where: { id },
    });

    return NextResponse.json({ success: true, message: 'Đã xóa người dùng' });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi xóa người dùng' }, { status: 500 });
  }
}
