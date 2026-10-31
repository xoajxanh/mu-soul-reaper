const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Adding customerName and isTest columns safely to live database...');
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
    `);
    console.log('Column customerName checked/added successfully.');

    await prisma.$executeRawUnsafe(`
      IF NOT EXISTS (
        SELECT * FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'[dbo].[Token]') 
        AND name = 'isTest'
      )
      BEGIN
        ALTER TABLE [dbo].[Token] ADD [isTest] BIT NOT NULL DEFAULT 0;
      END;
    `);
    console.log('Column isTest checked/added successfully.');
  } catch (e) {
    console.error('Error adding columns:', e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
