const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const constraints = await prisma.$queryRaw`
      SELECT name FROM sys.default_constraints 
      WHERE parent_object_id = OBJECT_ID('VipPackage')
    `;
    console.log('VipPackage constraints:', constraints);
    for (const c of constraints) {
      if (c.name.includes('adminTelegrams') || c.name.includes('characterReincarnation')) {
        console.log('Dropping constraint:', c.name);
        await prisma.$executeRawUnsafe(`ALTER TABLE [dbo].[VipPackage] DROP CONSTRAINT [${c.name}]`);
      }
    }
  } catch (e) {
    console.error('Error dropping constraints:', e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
