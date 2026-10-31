const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Adding lastOnline, lastCharacterName, lastServerName columns safely to Token table...');
  try {
    await prisma.$executeRawUnsafe(`
      IF NOT EXISTS (
        SELECT * FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'[dbo].[Token]') 
        AND name = 'lastOnline'
      )
      BEGIN
        ALTER TABLE [dbo].[Token] ADD [lastOnline] DATETIME2 NULL;
      END;
    `);
    console.log('Column lastOnline checked/added successfully.');

    await prisma.$executeRawUnsafe(`
      IF NOT EXISTS (
        SELECT * FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'[dbo].[Token]') 
        AND name = 'lastCharacterName'
      )
      BEGIN
        ALTER TABLE [dbo].[Token] ADD [lastCharacterName] NVARCHAR(255) NULL;
      END;
    `);
    console.log('Column lastCharacterName checked/added successfully.');

    await prisma.$executeRawUnsafe(`
      IF NOT EXISTS (
        SELECT * FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'[dbo].[Token]') 
        AND name = 'lastServerName'
      )
      BEGIN
        ALTER TABLE [dbo].[Token] ADD [lastServerName] NVARCHAR(255) NULL;
      END;
    `);
    console.log('Column lastServerName checked/added successfully.');
  } catch (e) {
    console.error('Error adding columns:', e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
