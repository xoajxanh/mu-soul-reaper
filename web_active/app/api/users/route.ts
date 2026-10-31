import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser, hashPassword } from '@/lib/auth';
import { prisma } from '@/lib/db';

export async function GET(req: NextRequest) {
  const session = await getSessionUser(req);
  if (!session || session.role !== 'ADMIN') {
    return NextResponse.json({ error: 'Không có quyền truy cập (Chỉ Admin)' }, { status: 403 });
  }

  const users = await prisma.user.findMany({
    select: {
      id: true,
      username: true,
      displayName: true,
      role: true,
      createdAt: true,
      updatedAt: true,
      _count: {
        select: { tokens: true },
      },
    },
    orderBy: { createdAt: 'desc' },
  });

  return NextResponse.json({ users });
}

export async function POST(req: NextRequest) {
  const session = await getSessionUser(req);
  if (!session || session.role !== 'ADMIN') {
    return NextResponse.json({ error: 'Không có quyền thực hiện (Chỉ Admin)' }, { status: 403 });
  }

  try {
    const body = await req.json();
    const { username, password, displayName, role } = body;

    if (!username || !password || !displayName || !role) {
      return NextResponse.json({ error: 'Vui lòng nhập đầy đủ thông tin' }, { status: 400 });
    }

    if (!['ADMIN', 'SALE'].includes(role)) {
      return NextResponse.json({ error: 'Role không hợp lệ (ADMIN hoặc SALE)' }, { status: 400 });
    }

    const existing = await prisma.user.findUnique({
      where: { username: username.trim() },
    });

    if (existing) {
      return NextResponse.json({ error: 'Tên đăng nhập đã tồn tại' }, { status: 400 });
    }

    const newUser = await prisma.user.create({
      data: {
        username: username.trim(),
        passwordHash: hashPassword(password),
        displayName: displayName.trim(),
        role: role as 'ADMIN' | 'SALE',
      },
      select: { id: true, username: true, displayName: true, role: true, createdAt: true },
    });

    return NextResponse.json({ success: true, user: newUser });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Lỗi khi tạo người dùng' }, { status: 500 });
  }
}
