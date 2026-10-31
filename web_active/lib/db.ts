import { PrismaClient } from '@prisma/client';
import { hashPassword } from './auth';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

let seedExecuted = false;

export async function ensureInitialSeed() {
  if (seedExecuted) return;
  seedExecuted = true;
  try {
    // Safely ensure missing columns exist and types are FLOAT on live DB without dropping any data
    try {
      await prisma.$executeRawUnsafe(`
        IF NOT EXISTS (
          SELECT * FROM sys.columns 
          WHERE object_id = OBJECT_ID(N'[dbo].[Token]') 
          AND name = 'customerName'
        )
        BEGIN
          ALTER TABLE [dbo].[Token] ADD [customerName] NVARCHAR(255) NULL;
        END;

        IF NOT EXISTS (
          SELECT * FROM sys.columns 
          WHERE object_id = OBJECT_ID(N'[dbo].[Token]') 
          AND name = 'isTest'
        )
        BEGIN
          ALTER TABLE [dbo].[Token] ADD [isTest] BIT NOT NULL DEFAULT 0;
        END;

        IF NOT EXISTS (
          SELECT * FROM sys.columns 
          WHERE object_id = OBJECT_ID(N'[dbo].[Token]') 
          AND name = 'characterReincarnationSecondary'
        )
        BEGIN
          ALTER TABLE [dbo].[Token] ADD [characterReincarnationSecondary] INT NOT NULL DEFAULT 7;
        END;

        ALTER TABLE [dbo].[VipPackage] ALTER COLUMN [durationDays] FLOAT NOT NULL;
        ALTER TABLE [dbo].[Token] ALTER COLUMN [durationDays] FLOAT NOT NULL;
      `);
    } catch (migErr) {
      console.error('Column check warning:', migErr);
    }

    const userCount = await prisma.user.count();
    if (userCount === 0) {
      console.log('Seeding initial Super Admin user...');
      const adminPass = hashPassword('admin123');
      const salePass = hashPassword('sale123');

      const superAdmin = await prisma.user.create({
        data: {
          username: 'admin',
          passwordHash: adminPass,
          displayName: 'Super Admin',
          role: 'ADMIN',
        },
      });

      await prisma.user.create({
        data: {
          username: 'sale1',
          passwordHash: salePass,
          displayName: 'Nhân viên CSKH 1',
          role: 'SALE',
        },
      });

      console.log('Seeding default VIP packages...');
      const defaultPackages = [
        { name: 'Gói VIP 3 Ngày', durationDays: 3, price: 50000 },
        { name: 'Gói VIP 7 Ngày', durationDays: 7, price: 100000 },
        { name: 'Gói VIP 15 Ngày', durationDays: 15, price: 180000 },
        { name: 'Gói VIP 30 Ngày', durationDays: 30, price: 300000 },
        { name: 'Gói VIP 90 Ngày', durationDays: 90, price: 800000 },
      ];

      for (const pkg of defaultPackages) {
        await prisma.vipPackage.create({
          data: {
            name: pkg.name,
            durationDays: pkg.durationDays,
            fovMin: 20,
            fovMax: 90,
            bossRefreshMin: 1,
            bossRefreshMax: 60,
            maxMoveSpeed: 2.5,
            maxAttackSpeed: 2.5,
            maxMonsterRange: 50,
            maxPickupCount: 100,
            activeTabBasic: true,
            activeTabAdvanced: true,
            activeTabAutofarm: true,
            price: pkg.price,
          },
        });
      }
      console.log('Seeding default Telegram CSKH contacts...');
      await prisma.telegramContact.createMany({
        data: [
          { username: '@xoajxanh', name: 'Admin Xoài' },
          { username: '@legend92vn', name: 'Admin Legend' },
        ],
      });

      console.log('Database initial seed complete!');
    }

    // Seed default message templates if empty
    try {
      const templateCount = await (prisma as any).messageTemplate.count();
      if (templateCount === 0) {
        const firstUser = await prisma.user.findFirst();
        if (firstUser) {
          console.log('Seeding default message templates...');
          await (prisma as any).messageTemplate.createMany({
            data: [
              {
                title: 'Bảng Giá Tool MU Vĩnh Hằng',
                shortcut: 'bg',
                category: 'BÁO GIÁ',
                imageUrl: '/uploads/templates/bang_gia_vutmod.png',
                content: 'Mình gửi b bảng giá tham khảo Tool MU Vĩnh Hằng bên mình:\n\n⚙️ BẢN THƯỜNG (400k/tháng): Chạy nhanh, Đánh xa, Zoom gần xa, Auto PK (Tự khóa mục tiêu, chọn mục tiêu pk), Nhặt KUN + PV 80%.\n\n👑 BẢN VIP (600k/tháng): Bao gồm toàn bộ tính năng Bản Thường + AUTO SĂN BOSS (Tự chuyển kênh/map, tự vào ấn Vàng/KC, tự hồi sinh khi bị PK và tiếp tục săn boss).\n\nBác cần cài đặt bản nào báo em hỗ trợ ngay nhé!',
                isGlobal: true,
                sortOrder: 1,
                createdById: firstUser.id,
              },
              {
                title: 'Thông Tin Chuyển Khoản & Thanh Toán',
                shortcut: 'stk',
                category: 'THANH TOÁN',
                imageUrl: null,
                content: 'Dạ em gửi bác thông tin tài khoản thanh toán kích hoạt Tool ạ:\n\n🏦 Ngân hàng: MB Bank (Quân Đội)\n💳 Số tài khoản: 0988888888\n👤 Chủ tài khoản: VUT MOD TEAM\n📝 Nội dung CK: [Tên Zalo/Telegram] - [Gói Tool]\n\nBác chuyển khoản xong chụp lại biên lai gửi em để em kích hoạt token ngay cho bác nhé!',
                isGlobal: true,
                sortOrder: 2,
                createdById: firstUser.id,
              },
              {
                title: 'Hướng Dẫn Lấy Mã Thiết Bị & UID',
                shortcut: 'hd',
                category: 'HƯỚNG DẪN',
                imageUrl: null,
                content: 'Dạ để kích hoạt bản quyền Tool, bác làm giúp em 2 bước này nhé:\n\n1️⃣ Tải và cài đặt file APK Mod theo link em gửi.\n2️⃣ Đăng nhập vào game, bấm vào icon Mod ở góc màn hình để copy "Mã Thiết Bị" và "UID Nhân Vật" gửi qua đây cho em.\n\nEm kích hoạt Token bản quyền trong vòng 1 phút là bác vào chiến được luôn ạ!',
                isGlobal: true,
                sortOrder: 3,
                createdById: firstUser.id,
              }
            ]
          });
          console.log('Seeded 3 default message templates!');
        }
      }
    } catch (tplErr) {
      console.error('Error seeding message templates:', tplErr);
    }
  } catch (err) {
    console.error('Error during initial seed:', err);
  }
}

