import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser } from '@/lib/auth';
import { writeFile, mkdir } from 'fs/promises';
import path from 'path';

export async function POST(req: NextRequest) {
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const formData = await req.formData();
    const file = formData.get('file') as File | null;
    if (!file) {
      return NextResponse.json({ error: 'Chưa chọn file ảnh' }, { status: 400 });
    }

    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);

    const uploadsDir = path.join(process.cwd(), 'public', 'uploads', 'templates');
    await mkdir(uploadsDir, { recursive: true });

    const ext = path.extname(file.name) || '.png';
    const cleanExt = ext.toLowerCase().replace(/[^a-z0-9.]/g, '');
    const filename = `template_${Date.now()}_${Math.random().toString(36).substring(2, 8)}${cleanExt || '.png'}`;
    const filePath = path.join(uploadsDir, filename);

    await writeFile(filePath, buffer);

    return NextResponse.json({
      success: true,
      url: `/uploads/templates/${filename}`,
    });
  } catch (error: any) {
    console.error('Upload error:', error);
    return NextResponse.json({ error: error.message || 'Lỗi khi tải ảnh lên' }, { status: 500 });
  }
}
