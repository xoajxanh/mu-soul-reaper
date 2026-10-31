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

  const telegrams = await prisma.telegramContact.findMany({
    orderBy: { createdAt: 'asc' },
  });

  return NextResponse.json({ telegrams });
}

export async function POST(req: NextRequest) {
  const session = await getSessionUser(req);
  if (!session || session.role !== 'ADMIN') {
    return NextResponse.json({ error: 'Chỉ Admin mới có quyền quản lý Telegram CSKH' }, { status: 403 });
  }

  try {
    const body = await req.json();
    const { username, name } = body;

    if (!username || !name) {
      return NextResponse.json({ error: 'Vui lòng nhập Username Telegram và Tên mô tả' }, { status: 400 });
    }

    let cleanUsername = username.trim();
    if (!cleanUsername.startsWith('@')) {
      cleanUsername = '@' + cleanUsername;
    }

    const existing = await prisma.telegramContact.findUnique({
      where: { username: cleanUsername },
    });

    if (existing) {
      return NextResponse.json({ error: 'Username Telegram này đã tồn tại trong hệ thống' }, { status: 400 });
    }

    const newContact = await prisma.telegramContact.create({
      data: {
        username: cleanUsername,
        name: name.trim(),
        active: true,
      },
    });

    return NextResponse.json({ success: true, telegram: newContact });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi thêm Telegram Contact' }, { status: 500 });
  }
}
