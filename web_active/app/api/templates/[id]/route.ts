import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser } from '@/lib/auth';
import { prisma, ensureInitialSeed } from '@/lib/db';

export const dynamic = 'force-dynamic';

export async function PUT(req: NextRequest, { params }: { params: { id: string } }) {
  await ensureInitialSeed();
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  const { id } = params;

  try {
    const existing = await prisma.messageTemplate.findUnique({
      where: { id },
    });

    if (!existing) {
      return NextResponse.json({ error: 'Mẫu tin nhắn không tồn tại' }, { status: 404 });
    }

    // Kiểm tra quyền sửa: Cả Admin và Sale đều có quyền chỉnh sửa mẫu tin nhắn
    if (session.role !== 'ADMIN' && session.role !== 'SALE') {
      return NextResponse.json({ error: 'Bạn không có quyền chỉnh sửa mẫu tin nhắn này' }, { status: 403 });
    }

    const body = await req.json();
    const { title, shortcut, category, content, imageUrl, isGlobal, sortOrder } = body;

    const updateData: any = {};
    if (title !== undefined) updateData.title = title.trim();
    if (shortcut !== undefined) updateData.shortcut = shortcut ? shortcut.trim().toLowerCase() : null;
    if (category !== undefined) updateData.category = category.trim();
    if (content !== undefined) updateData.content = content.trim();
    if (imageUrl !== undefined) updateData.imageUrl = imageUrl ? imageUrl.trim() : null;
    if (sortOrder !== undefined) updateData.sortOrder = Number(sortOrder) || 0;

    // Cả Admin và Sale đều có thể cấu hình isGlobal
    if (isGlobal !== undefined) {
      updateData.isGlobal = Boolean(isGlobal);
    }

    const updated = await prisma.messageTemplate.update({
      where: { id },
      data: updateData,
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

    return NextResponse.json({ success: true, template: updated });
  } catch (err: any) {
    console.error('Error updating template:', err);
    return NextResponse.json({ error: err.message || 'Lỗi khi cập nhật mẫu tin nhắn' }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  await ensureInitialSeed();
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  const { id } = params;

  try {
    const existing = await prisma.messageTemplate.findUnique({
      where: { id },
    });

    if (!existing) {
      return NextResponse.json({ error: 'Mẫu tin nhắn không tồn tại' }, { status: 404 });
    }

    // Kiểm tra quyền xóa: Cả Admin và Sale đều có quyền xóa mẫu tin nhắn
    if (session.role !== 'ADMIN' && session.role !== 'SALE') {
      return NextResponse.json({ error: 'Bạn không có quyền xóa mẫu tin nhắn này' }, { status: 403 });
    }

    await prisma.messageTemplate.delete({
      where: { id },
    });

    return NextResponse.json({ success: true, message: 'Đã xóa mẫu tin nhắn' });
  } catch (err: any) {
    console.error('Error deleting template:', err);
    return NextResponse.json({ error: err.message || 'Lỗi khi xóa mẫu tin nhắn' }, { status: 500 });
  }
}
