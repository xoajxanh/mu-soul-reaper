import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser } from '@/lib/auth';
import { prisma, ensureInitialSeed } from '@/lib/db';
import { generateSvipEncryptedToken } from '@/lib/keygen';

export const dynamic = 'force-dynamic';

// =========================================================================
// [MOD FEATURE]: API QUẢN LÝ TOKEN SVIP (CHO CLIENT DEV/ADMIN)
// Mô tả: Danh sách và tạo mới Token SVIP theo quy tắc Keygen.ps1.
//        Chặn nhân viên SALE tạo mã UID = ALL (chỉ ADMIN mới được tạo ALL).
//        Hỗ trợ cờ isTest để loại khỏi doanh thu.
// =========================================================================

export async function GET(req: NextRequest) {
  await ensureInitialSeed();
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const search = searchParams.get('search') || '';
  const status = searchParams.get('status') || 'ALL'; // ALL, ACTIVE, EXPIRING_SOON, EXPIRED, DELETED, TEST
  const createdBy = searchParams.get('createdBy') || '';
  
  const page = Math.max(1, parseInt(searchParams.get('page') || '1', 10));
  const limit = Math.max(1, parseInt(searchParams.get('limit') || '20', 10));
  const skip = (page - 1) * limit;

  const whereClause: any = {
    type: 'SVIP',
  };

  if (search.trim() !== '') {
    whereClause.OR = [
      { deviceSnMd5: { contains: search.trim() } },
      { characterUid: { contains: search.trim() } },
      { tokenKey: { contains: search.trim() } },
      { customerName: { contains: search.trim() } },
    ];
  }

  if (session.role === 'SALE') {
    whereClause.createdById = session.userId;
  } else if (session.role === 'ADMIN') {
    if (createdBy.trim() !== '' && createdBy.trim() !== 'ALL') {
      whereClause.createdById = createdBy.trim();
    }
  }

  const now = new Date();
  const threeDaysLater = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

  if (status === 'DELETED') {
    whereClause.isDeleted = true;
  } else if (status === 'TEST') {
    whereClause.isDeleted = false;
    whereClause.isTest = true;
  } else {
    whereClause.isDeleted = false;
    if (status === 'ACTIVE') {
      whereClause.expireAt = { gte: now };
    } else if (status === 'EXPIRING_SOON') {
      whereClause.expireAt = { gte: now, lte: threeDaysLater };
    } else if (status === 'EXPIRED') {
      whereClause.expireAt = { lt: now };
    }
  }

  const [total, tokens] = await Promise.all([
    prisma.token.count({ where: whereClause }),
    prisma.token.findMany({
      where: whereClause,
      include: {
        createdBy: { select: { id: true, username: true, displayName: true } },
        _count: { select: { notes: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  const totalPages = Math.ceil(total / limit) || 1;

  return NextResponse.json({
    tokens,
    pagination: {
      page,
      limit,
      total,
      totalPages,
    },
  });
}

export async function POST(req: NextRequest) {
  await ensureInitialSeed();
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  try {
    const body = await req.json();
    const {
      deviceSnMd5,
      characterUid,
      customerName,
      isTest,
      durationDays,
      startDate,
      mainTier,
      subTier,
      price,
      notes,
    } = body;

    if (!deviceSnMd5 || !characterUid || !durationDays) {
      return NextResponse.json({ error: 'Mã thiết bị MD5, UID nhân vật và Thời hạn là bắt buộc' }, { status: 400 });
    }

    const cleanDeviceSn = String(deviceSnMd5).trim();
    const cleanUid = String(characterUid).trim();
    const duration = parseFloat(durationDays);

    if (isNaN(duration) || duration <= 0) {
      return NextResponse.json({ error: 'Thời hạn sử dụng không hợp lệ' }, { status: 400 });
    }

    // =========================================================================
    // [MOD FEATURE]: BẢO MẬT PHÂN QUYỀN UID = ALL (ADMIN ONLY)
    // Mô tả: Chỉ ADMIN mới được tạo Token cho mọi nhân vật (ALL). SALE bị chặn 100%.
    // =========================================================================
    if (cleanUid.toUpperCase() === 'ALL' && session.role !== 'ADMIN') {
      return NextResponse.json({
        error: 'Chỉ Quản trị viên (Admin) mới có quyền tạo Token SVIP cho tất cả nhân vật (ALL)! Nhân viên SALE bắt buộc phải nhập UID nhân vật cụ thể.',
      }, { status: 403 });
    }

    // Xác định Ngày Bắt Đầu và Ngày Hết Hạn
    let startDateTime = new Date();
    if (startDate) {
      const parsedStart = new Date(startDate);
      if (!isNaN(parsedStart.getTime())) {
        startDateTime = parsedStart;
      }
    }

    const expireAt = new Date(startDateTime.getTime() + duration * 86400 * 1000);
    const startTimeUnix = Math.floor(startDateTime.getTime() / 1000);

    const parsedMain = Number(mainTier) || 8;
    const parsedSub = Number(subTier) || 7;

    // Sinh Token theo chuẩn Keygen.ps1
    const { encryptedToken } = generateSvipEncryptedToken({
      deviceSnMd5: cleanDeviceSn,
      characterUid: cleanUid,
      mainTier: parsedMain,
      subTier: parsedSub,
      durationDays: duration,
      startTimeUnix,
    });

    const tokenRecord = await prisma.token.create({
      data: {
        deviceSnMd5: cleanDeviceSn,
        characterUid: cleanUid,
        customerName: customerName ? String(customerName).trim() : null,
        isTest: Boolean(isTest ?? false),
        type: 'SVIP',
        durationDays: duration,
        expireAt,
        characterReincarnation: parsedMain,
        characterReincarnationSecondary: parsedSub,
        price: Boolean(isTest) ? 0 : Number(price ?? 0),
        encryptedToken,
        createdById: session.userId,
      },
      include: {
        createdBy: { select: { displayName: true, username: true } },
      },
    });

    // Ghi log ghi chú khởi tạo nếu có
    if (notes && String(notes).trim() !== '') {
      await prisma.tokenNote.create({
        data: {
          tokenId: tokenRecord.id,
          createdById: session.userId,
          action: 'CREATE',
          detail: String(notes).trim(),
        },
      });
    }

    return NextResponse.json({
      success: true,
      token: tokenRecord,
      message: 'Tạo Token SVIP thành công!',
    });
  } catch (err: any) {
    console.error('[SVIP Tokens] Error creating token:', err);
    return NextResponse.json({ error: err.message || 'Lỗi server khi tạo Token SVIP' }, { status: 500 });
  }
}
