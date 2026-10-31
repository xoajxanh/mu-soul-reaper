import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser, hashPassword, comparePassword } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function POST(req: NextRequest) {
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  try {
    const body = await req.json();
    const { displayName, oldPassword, newPassword } = body;

    const user = await prisma.user.findUnique({
      where: { id: session.userId },
    });

    if (!user) {
      return NextResponse.json({ error: 'Tài khoản không tồn tại' }, { status: 404 });
    }

    const updateData: any = {};

    if (displayName && displayName.trim() !== '') {
      updateData.displayName = displayName.trim();
    }

    if (newPassword && newPassword.trim() !== '') {
      if (!oldPassword || !comparePassword(oldPassword, user.passwordHash)) {
        return NextResponse.json({ error: 'Mật khẩu cũ không chính xác' }, { status: 400 });
      }
      if (newPassword.length < 6) {
        return NextResponse.json({ error: 'Mật khẩu mới phải từ 6 ký tự trở lên' }, { status: 400 });
      }
      updateData.passwordHash = hashPassword(newPassword.trim());
    }

    const updated = await prisma.user.update({
      where: { id: session.userId },
      data: updateData,
      select: { id: true, username: true, displayName: true, role: true },
    });

    return NextResponse.json({ success: true, user: updated, message: 'Cập nhật thông tin thành công' });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi hệ thống' }, { status: 500 });
  }
}
