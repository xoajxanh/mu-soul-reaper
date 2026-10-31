import { NextRequest, NextResponse } from 'next/server';
import { prisma, ensureInitialSeed } from '@/lib/db';
import { comparePassword, signJwtToken } from '@/lib/auth';

export async function POST(req: NextRequest) {
  try {
    await ensureInitialSeed();
    const body = await req.json();
    const { username, password } = body;

    if (!username || !password) {
      return NextResponse.json({ error: 'Tên đăng nhập và mật khẩu không được trống' }, { status: 400 });
    }

    const user = await prisma.user.findUnique({
      where: { username: username.trim() },
    });

    if (!user || !comparePassword(password, user.passwordHash)) {
      return NextResponse.json({ error: 'Tên đăng nhập hoặc mật khẩu không chính xác' }, { status: 401 });
    }

    const sessionPayload = {
      userId: user.id,
      username: user.username,
      displayName: user.displayName,
      role: user.role as 'ADMIN' | 'SALE',
    };

    const token = signJwtToken(sessionPayload);

    const response = NextResponse.json({
      success: true,
      user: sessionPayload,
      token,
    });

    response.cookies.set('muvh_session', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
      maxAge: 60 * 60 * 24 * 7, // 7 days
    });

    return response;
  } catch (err: any) {
    console.error('Login error:', err);
    return NextResponse.json({ error: err.message || 'Lỗi hệ thống khi đăng nhập' }, { status: 500 });
  }
}
