import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser } from '@/lib/auth';
import { prisma } from '@/lib/db';

export const dynamic = 'force-dynamic';

export async function PUT(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session || session.role !== 'ADMIN') {
    return NextResponse.json({ error: 'Chỉ Admin mới có quyền cập nhật Telegram CSKH' }, { status: 403 });
  }

  try {
    const { id } = params;
    const body = await req.json();
    const { username, name, active } = body;

    let cleanUsername = username ? username.trim() : undefined;
    if (cleanUsername && !cleanUsername.startsWith('@')) {
      cleanUsername = '@' + cleanUsername;
    }

    const updated = await prisma.telegramContact.update({
      where: { id },
      data: {
        username: cleanUsername,
        name: name ? name.trim() : undefined,
        active: active !== undefined ? Boolean(active) : undefined,
      },
    });

    return NextResponse.json({ success: true, telegram: updated });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi cập nhật Telegram Contact' }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getSessionUser(req);
  if (!session || session.role !== 'ADMIN') {
    return NextResponse.json({ error: 'Chỉ Admin mới có quyền xóa Telegram CSKH' }, { status: 403 });
  }

  try {
    const { id } = params;
    await prisma.telegramContact.delete({
      where: { id },
    });

    return NextResponse.json({ success: true, message: 'Đã xóa Telegram Contact' });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi xóa Telegram Contact' }, { status: 500 });
  }
}
