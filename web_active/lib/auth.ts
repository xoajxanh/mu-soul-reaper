import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { cookies } from 'next/headers';
import { NextRequest } from 'next/server';

const JWT_SECRET = process.env.JWT_SECRET || 'MUVH_SUPER_SECRET_JWT_KEY_2026_XOAI';

export interface UserSession {
  userId: string;
  username: string;
  displayName: string;
  role: 'ADMIN' | 'SALE';
}

export function hashPassword(password: string): string {
  return bcrypt.hashSync(password, 10);
}

export function comparePassword(password: string, hash: string): boolean {
  return bcrypt.compareSync(password, hash);
}

export function signJwtToken(payload: UserSession): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
}

export function verifyJwtToken(token: string): UserSession | null {
  try {
    return jwt.verify(token, JWT_SECRET) as UserSession;
  } catch (e) {
    return null;
  }
}

export async function getSessionUser(req?: NextRequest): Promise<UserSession | null> {
  let token: string | undefined;

  if (req) {
    const authHeader = req.headers.get('authorization');
    if (authHeader && authHeader.startsWith('Bearer ')) {
      token = authHeader.substring(7);
    } else {
      token = req.cookies.get('muvh_session')?.value;
    }
  } else {
    const cookieStore = cookies();
    token = cookieStore.get('muvh_session')?.value;
  }

  if (!token) return null;
  return verifyJwtToken(token);
}
