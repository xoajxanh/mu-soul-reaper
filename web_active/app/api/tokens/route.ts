import { NextRequest, NextResponse } from 'next/server';
import { getSessionUser } from '@/lib/auth';
import { prisma, ensureInitialSeed } from '@/lib/db';
import { generateEncryptedToken } from '@/lib/keygen';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  await ensureInitialSeed();
  const session = await getSessionUser(req);
  if (!session) {
    return NextResponse.json({ error: 'Chưa đăng nhập' }, { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const search = searchParams.get('search') || '';
  const status = searchParams.get('status') || 'ALL'; // ALL, ACTIVE, EXPIRING_SOON, EXPIRED, DELETED
  const createdBy = searchParams.get('createdBy') || '';
  
  // Pagination parameters
  const page = Math.max(1, parseInt(searchParams.get('page') || '1', 10));
  const limit = Math.max(1, parseInt(searchParams.get('limit') || '20', 10));
  const skip = (page - 1) * limit;

  const whereClause: any = {
    type: { not: 'SVIP' },
  };

  if (search.trim() !== '') {
    whereClause.OR = [
      { deviceSnMd5: { contains: search.trim() } },
      { characterUid: { contains: search.trim() } },
      { tokenKey: { contains: search.trim() } },
      { customerName: { contains: search.trim() } },
    ];
  }

  // =========================================================================
  // [MOD FEATURE]: PHÂN QUYỀN TRUY VẤN TOKEN THEO USER ROLE
  // Mô tả: SALE chỉ xem được token do chính mình tạo; ADMIN có thể xem tất cả hoặc lọc theo Sale
  // =========================================================================
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
        vipPackage: { select: { id: true, name: true } },
        createdBy: { select: { id: true, username: true, displayName: true } },
        parent: { select: { id: true, characterUid: true, deviceSnMd5: true, customerName: true, expireAt: true, isDeleted: true } },
        children: { select: { id: true, characterUid: true, deviceSnMd5: true, customerName: true, expireAt: true, isDeleted: true } },
        _count: { select: { notes: true, children: true } },
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
      packageId,
      durationDays,
      fovMin,
      fovMax,
      bossRefreshMin,
      bossRefreshMax,
      maxMoveSpeed,
      maxAttackSpeed,
      maxMonsterRange,
      maxPickupCount,
      pickupDelayMin,
      pickupDelayMax,
      activeTabBasic,
      activeTabAdvanced,
      activeTabAutofarm,
      characterReincarnation,
      characterReincarnationSecondary,
      adminTelegrams,
      price,
      isCustom,
      parentCharacterUid,
      parentDeviceSnMd5,
      subTokenType,
    } = body;

    if (!deviceSnMd5 || !characterUid || !durationDays) {
      return NextResponse.json({ error: 'Mã thiết bị MD5, Character UID và Thời hạn là bắt buộc' }, { status: 400 });
    }

    // =========================================================================
    // [MOD FEATURE]: XỬ LÝ LIÊN KẾT TOKEN CHA (PARENT TOKEN: NV PHỤ & MÁY PHỤ)
    // Mô tả: Hỗ trợ 2 loại Token phụ thuộc:
    // 1. Token Nhân Vật Phụ (cùng máy, khác UID -> query theo parentCharacterUid + deviceSnMd5)
    // 2. Token Máy Phụ (khác máy, cùng UID -> query theo parentDeviceSnMd5 + characterUid)
    // =========================================================================
    let parentId: string | null = null;
    let parentToken: any = null;
    let subTokenTag = '';

    if (subTokenType === 'CHARACTER' || (parentCharacterUid && String(parentCharacterUid).trim() !== '')) {
      const cleanParentUid = String(parentCharacterUid).trim();
      if (cleanParentUid === characterUid.trim()) {
        return NextResponse.json({ error: 'Token Nhân vật phụ không thể tự chọn chính mình làm Token cha!' }, { status: 400 });
      }

      parentToken = await prisma.token.findFirst({
        where: {
          characterUid: cleanParentUid,
          deviceSnMd5: deviceSnMd5.trim(),
          isDeleted: false,
        },
        orderBy: { createdAt: 'desc' },
      });

      if (!parentToken) {
        return NextResponse.json({
          error: `Không tìm thấy Token cha với UID [${cleanParentUid}] trên cùng thiết bị này! Vui lòng kiểm tra lại.`,
        }, { status: 400 });
      }

      parentId = parentToken.id;
      subTokenTag = ` [TOKEN NV PHỤ của UID: ${parentToken.characterUid}]`;
    } else if (subTokenType === 'DEVICE' || (parentDeviceSnMd5 && String(parentDeviceSnMd5).trim() !== '')) {
      const cleanParentDeviceSn = String(parentDeviceSnMd5).trim();
      if (cleanParentDeviceSn === deviceSnMd5.trim()) {
        return NextResponse.json({
          error: 'Mã máy chính không được trùng với mã máy phụ hiện tại! (Nếu cùng máy, vui lòng chọn Token Nhân Vật Phụ).',
        }, { status: 400 });
      }

      parentToken = await prisma.token.findFirst({
        where: {
          deviceSnMd5: cleanParentDeviceSn,
          characterUid: characterUid.trim(),
          isDeleted: false,
        },
        orderBy: { createdAt: 'desc' },
      });

      if (!parentToken) {
        return NextResponse.json({
          error: `Không tìm thấy Token máy chính nào với Mã máy [${cleanParentDeviceSn}] và UID nhân vật [${characterUid.trim()}]! Vui lòng kiểm tra lại.`,
        }, { status: 400 });
      }

      parentId = parentToken.id;
      subTokenTag = ` [TOKEN MÁY PHỤ của Máy chính: ${parentToken.deviceSnMd5}]`;
    }

    const duration = parentToken ? parentToken.durationDays : Number(durationDays);
    const now = new Date();
    const expireAt = parentToken ? new Date(parentToken.expireAt) : new Date(now.getTime() + duration * 86400 * 1000);
    const expireAtUnix = Math.floor(expireAt.getTime() / 1000);

    const telegramsList = Array.isArray(adminTelegrams)
      ? adminTelegrams
      : typeof adminTelegrams === 'string'
      ? adminTelegrams.split(',').map((s) => s.trim()).filter((s) => s)
      : ['@admin1', '@admin2'];

    const primaryReinc = Number(characterReincarnation ?? 8);
    const secondaryReinc = Number(characterReincarnationSecondary ?? (primaryReinc > 1 ? primaryReinc - 1 : 1));

    const tokenParams = {
      deviceSnMd5: deviceSnMd5.trim(),
      characterUid: characterUid.trim(),
      durationDays: duration,
      expireAtUnix,
      fovMin: Number(fovMin ?? 20),
      fovMax: Number(fovMax ?? 90),
      bossRefreshMin: Number(bossRefreshMin ?? 1),
      bossRefreshMax: Number(bossRefreshMax ?? 60),
      maxMoveSpeed: Number(maxMoveSpeed ?? 2.5),
      maxAttackSpeed: Number(maxAttackSpeed ?? 2.5),
      maxMonsterRange: Number(maxMonsterRange ?? 50),
      maxPickupCount: Number(maxPickupCount ?? 100),
      pickupDelayMin: Number(pickupDelayMin ?? 100),
      pickupDelayMax: Number(pickupDelayMax ?? 500),
      activeTabBasic: Boolean(activeTabBasic ?? true),
      activeTabAdvanced: Boolean(activeTabAdvanced ?? true),
      activeTabAutofarm: Boolean(activeTabAutofarm ?? true),
      characterReincarnation: primaryReinc,
      characterReincarnationSecondary: secondaryReinc,
      adminTelegrams: telegramsList,
    };

    const { encryptedToken } = generateEncryptedToken(tokenParams);

    const tokenRecord = await prisma.token.create({
      data: {
        deviceSnMd5: tokenParams.deviceSnMd5,
        characterUid: tokenParams.characterUid,
        customerName: customerName ? String(customerName).trim() : null,
        isTest: Boolean(isTest ?? false),
        type: 'CUSTOMER',
        packageId: packageId || null,
        durationDays: duration,
        expireAt,
        fovMin: tokenParams.fovMin,
        fovMax: tokenParams.fovMax,
        bossRefreshMin: tokenParams.bossRefreshMin,
        bossRefreshMax: tokenParams.bossRefreshMax,
        maxMoveSpeed: tokenParams.maxMoveSpeed,
        maxAttackSpeed: tokenParams.maxAttackSpeed,
        maxMonsterRange: tokenParams.maxMonsterRange,
        maxPickupCount: tokenParams.maxPickupCount,
        pickupDelayMin: tokenParams.pickupDelayMin,
        pickupDelayMax: tokenParams.pickupDelayMax,
        activeTabBasic: tokenParams.activeTabBasic,
        activeTabAdvanced: tokenParams.activeTabAdvanced,
        activeTabAutofarm: tokenParams.activeTabAutofarm,
        characterReincarnation: tokenParams.characterReincarnation,
        characterReincarnationSecondary: tokenParams.characterReincarnationSecondary,
        adminTelegrams: JSON.stringify(telegramsList),
        price: Number(price ?? 0),
        isCustom: Boolean(isCustom ?? false),
        encryptedToken,
        createdById: session.userId,
        parentId,
      },
    });

    // Create Audit Log Note
    const testTag = Boolean(isTest) ? ' [TEST]' : '';
    const initialNoteDetail = `Khởi tạo Token${testTag}${subTokenTag} mới cho Khách hàng [${customerName ? customerName.trim() : 'Chưa nhập'}], thiết bị [${tokenParams.deviceSnMd5}], UID nhân vật [${tokenParams.characterUid}], thời hạn ${duration} ngày, giá ${Number(price || 0).toLocaleString('vi-VN')} VNĐ.`;
    await prisma.tokenNote.create({
      data: {
        tokenId: tokenRecord.id,
        createdById: session.userId,
        action: 'CREATE',
        detail: initialNoteDetail,
      },
    });

    return NextResponse.json({ success: true, token: tokenRecord });
  } catch (err: any) {
    console.error('Token create error:', err);
    return NextResponse.json({ error: err.message || 'Lỗi khi kích hoạt Token' }, { status: 500 });
  }
}
