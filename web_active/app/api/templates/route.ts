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
  const q = searchParams.get('q')?.trim().toLowerCase() || '';
  const category = searchParams.get('category')?.trim() || '';

  const whereClause: any = {};

  // Phân quyền: Cả Admin và Sale đều thấy toàn bộ kịch bản chung của team


  if (category && category !== 'ALL') {
    if (category === 'MINE') {
      whereClause.createdById = session.userId;
    } else {
      whereClause.category = category;
    }
  }

  const templates = await prisma.messageTemplate.findMany({
    where: whereClause,
    orderBy: [
      { sortOrder: 'asc' },
      { createdAt: 'desc' },
    ],
    include: {
      createdBy: {
        select: {
          id: true,
          username: true,
          displayName: true,
          role: true,
        },
      },
    },
  });

  // Lọc tìm kiếm nếu có
  const filtered = q
    ? templates.filter(
        (t) =>
          t.title.toLowerCase().includes(q) ||
          (t.shortcut && t.shortcut.toLowerCase().includes(q)) ||
          t.content.toLowerCase().includes(q)
      )
    : templates;

  return NextResponse.json({ templates: filtered, currentUserId: session.userId, userRole: session.role });
}

export async function POST(req: NextRequest) {
  await ensureInitialSeed();
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  try {
    const body = await req.json();
    const { title, shortcut, category, content, imageUrl, isGlobal, sortOrder } = body;

    if (!title || !title.trim()) {
      return NextResponse.json({ error: 'Vui lòng nhập Tiêu đề mẫu tin nhắn' }, { status: 400 });
    }

    if (!content || !content.trim()) {
      return NextResponse.json({ error: 'Vui lòng nhập Nội dung tin nhắn' }, { status: 400 });
    }

    // Cả Admin và Sale đều có thể tạo mẫu Global cho toàn team (mặc định true nếu không chỉ định)
    const templateIsGlobal = isGlobal !== undefined ? Boolean(isGlobal) : true;

    const newTemplate = await prisma.messageTemplate.create({
      data: {
        title: title.trim(),
        shortcut: shortcut ? shortcut.trim().toLowerCase() : null,
        category: category?.trim() || 'BÁO GIÁ',
        content: content.trim(),
        imageUrl: imageUrl ? imageUrl.trim() : null,
        isGlobal: templateIsGlobal,
        sortOrder: Number(sortOrder) || 0,
        createdById: session.userId,
      },
      include: {
        createdBy: {
          select: {
            id: true,
            username: true,
            displayName: true,
            role: true,
          },
        },
      },
    });

    return NextResponse.json({ success: true, template: newTemplate });
  } catch (err: any) {
    console.error('Error creating message template:', err);
    return NextResponse.json({ error: err.message || 'Lỗi khi tạo mẫu tin nhắn' }, { status: 500 });
  }
}
