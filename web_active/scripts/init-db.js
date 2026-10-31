const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const { execSync } = require('child_process');

const MASTER_URL = 'sqlserver://161.248.146.65:1992;database=master;user=sa;password=1minhtaoBIK;encrypt=true;trustServerCertificate=true;';
const TARGET_URL = 'sqlserver://161.248.146.65:1992;database=mu_soul_reaper;user=sa;password=1minhtaoBIK;encrypt=true;trustServerCertificate=true;';

async function main() {
  console.log('1. Connecting to SQL Server (master) to create database [mu_soul_reaper] if not exists...');
  const masterPrisma = new PrismaClient({
    datasources: { db: { url: MASTER_URL } }
  });

  try {
    await masterPrisma.$executeRawUnsafe(`
      IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'mu_soul_reaper')
      BEGIN
        CREATE DATABASE [mu_soul_reaper];
      END
    `);
    console.log('   -> Database [mu_soul_reaper] is ready!');
  } finally {
    await masterPrisma.$disconnect();
  }

  console.log('2. Pushing Prisma schema to [mu_soul_reaper]...');
  execSync('npx prisma db push --skip-generate', {
    cwd: __dirname + '/..',
    stdio: 'inherit',
    env: { ...process.env, DATABASE_URL: TARGET_URL }
  });

  console.log('3. Seeding initial data into [mu_soul_reaper]...');
  const prisma = new PrismaClient({
    datasources: { db: { url: TARGET_URL } }
  });

  try {
    const userCount = await prisma.user.count();
    if (userCount === 0) {
      const adminPass = bcrypt.hashSync('admin123', 10);
      const salePass = bcrypt.hashSync('sale123', 10);

      await prisma.user.create({
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
      console.log('   -> Created default users: admin / sale1');

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
      console.log('   -> Created 5 default VIP Packages');

      await prisma.telegramContact.createMany({
        data: [
          { username: '@xoajxanh', name: 'Admin Xoài' },
          { username: '@legend92vn', name: 'Admin Legend' },
        ],
      });
      console.log('   -> Created default Telegram Contacts');
    } else {
      console.log('   -> Users already exist, skipping seed.');
    }

    const templateCount = await prisma.messageTemplate.count();
    if (templateCount === 0) {
      const firstUser = await prisma.user.findFirst();
      if (firstUser) {
        await prisma.messageTemplate.createMany({
          data: [
            {
              title: 'Bảng Giá Tool MU Soul Reaper',
              shortcut: 'bg',
              category: 'BÁO GIÁ',
              imageUrl: '/uploads/templates/bang_gia_vutmod.png',
              content: 'Mình gửi b bảng giá tham khảo Tool MU Soul Reaper bên mình:\n\n⚙️ BẢN THƯỜNG (400k/tháng): Chạy nhanh, Đánh xa, Zoom gần xa, Auto PK (Tự khóa mục tiêu, chọn mục tiêu pk), Nhặt KUN + PV 80%.\n\n👑 BẢN VIP (600k/tháng): Bao gồm toàn bộ tính năng Bản Thường + AUTO SĂN BOSS (Tự chuyển kênh/map, tự vào ấn Vàng/KC, tự hồi sinh khi bị PK và tiếp tục săn boss).\n\nBác cần cài đặt bản nào báo em hỗ trợ ngay nhé!',
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
        console.log('   -> Created 3 default Message Templates');
      }
    }
    console.log('=== ALL DONE SUCCESSFULLY! ===');
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

