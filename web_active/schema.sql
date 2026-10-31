-- SQL Server Schema Migration Script for MUVH Admin Web
-- Database: mu_soul_reaper

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'User')
BEGIN
    CREATE TABLE [dbo].[User] (
        [id] NVARCHAR(100) NOT NULL PRIMARY KEY,
        [username] NVARCHAR(100) NOT NULL UNIQUE,
        [passwordHash] NVARCHAR(255) NOT NULL,
        [displayName] NVARCHAR(255) NOT NULL,
        [role] NVARCHAR(50) NOT NULL DEFAULT 'SALE',
        [createdAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT GETDATE()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VipPackage')
BEGIN
    CREATE TABLE [dbo].[VipPackage] (
        [id] NVARCHAR(100) NOT NULL PRIMARY KEY,
        [name] NVARCHAR(255) NOT NULL,
        [durationDays] FLOAT NOT NULL,
        [fovMin] INT NOT NULL DEFAULT 20,
        [fovMax] INT NOT NULL DEFAULT 90,
        [bossRefreshMin] INT NOT NULL DEFAULT 1,
        [bossRefreshMax] INT NOT NULL DEFAULT 60,
        [maxMoveSpeed] FLOAT NOT NULL DEFAULT 2.5,
        [maxAttackSpeed] FLOAT NOT NULL DEFAULT 2.5,
        [maxMonsterRange] INT NOT NULL DEFAULT 50,
        [maxPickupCount] INT NOT NULL DEFAULT 100,
        [activeTabBasic] BIT NOT NULL DEFAULT 1,
        [activeTabAdvanced] BIT NOT NULL DEFAULT 1,
        [activeTabAutofarm] BIT NOT NULL DEFAULT 1,
        [price] FLOAT NOT NULL DEFAULT 0,
        [createdAt] DATETIME2 NOT NULL DEFAULT GETDATE()
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Token')
BEGIN
    CREATE TABLE [dbo].[Token] (
        [id] NVARCHAR(100) NOT NULL PRIMARY KEY,
        [tokenKey] NVARCHAR(100) NOT NULL UNIQUE,
        [deviceSnMd5] NVARCHAR(100) NOT NULL,
        [characterUid] NVARCHAR(100) NOT NULL,
        [packageId] NVARCHAR(100) NULL,
        [durationDays] FLOAT NOT NULL,
        [expireAt] DATETIME2 NOT NULL,
        [fovMin] INT NOT NULL DEFAULT 20,
        [fovMax] INT NOT NULL DEFAULT 90,
        [bossRefreshMin] INT NOT NULL DEFAULT 1,
        [bossRefreshMax] INT NOT NULL DEFAULT 60,
        [maxMoveSpeed] FLOAT NOT NULL DEFAULT 2.5,
        [maxAttackSpeed] FLOAT NOT NULL DEFAULT 2.5,
        [maxMonsterRange] INT NOT NULL DEFAULT 50,
        [maxPickupCount] INT NOT NULL DEFAULT 100,
        [activeTabBasic] BIT NOT NULL DEFAULT 1,
        [activeTabAdvanced] BIT NOT NULL DEFAULT 1,
        [activeTabAutofarm] BIT NOT NULL DEFAULT 1,
        [characterReincarnation] INT NOT NULL DEFAULT 8,
        [characterReincarnationSecondary] INT NOT NULL DEFAULT 7,
        [adminTelegrams] NVARCHAR(MAX) NOT NULL DEFAULT '["@admin1", "@admin2"]',
        [price] FLOAT NOT NULL DEFAULT 0,
        [isCustom] BIT NOT NULL DEFAULT 0,
        [customerName] NVARCHAR(255) NULL,
        [isTest] BIT NOT NULL DEFAULT 0,
        [encryptedToken] NVARCHAR(MAX) NOT NULL,
        [createdById] NVARCHAR(100) NOT NULL,
        [createdAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [FK_Token_User] FOREIGN KEY ([createdById]) REFERENCES [dbo].[User]([id]),
        CONSTRAINT [FK_Token_VipPackage] FOREIGN KEY ([packageId]) REFERENCES [dbo].[VipPackage]([id])
    );

    CREATE INDEX [IX_Token_Device_UID] ON [dbo].[Token] ([deviceSnMd5], [characterUid]);
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TokenNote')
BEGIN
    CREATE TABLE [dbo].[TokenNote] (
        [id] NVARCHAR(100) NOT NULL PRIMARY KEY,
        [tokenId] NVARCHAR(100) NOT NULL,
        [createdById] NVARCHAR(100) NOT NULL,
        [action] NVARCHAR(50) NOT NULL,
        [detail] NVARCHAR(MAX) NOT NULL,
        [createdAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [FK_TokenNote_Token] FOREIGN KEY ([tokenId]) REFERENCES [dbo].[Token]([id]),
        CONSTRAINT [FK_TokenNote_User] FOREIGN KEY ([createdById]) REFERENCES [dbo].[User]([id])
    );
END;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MessageTemplate')
BEGIN
    CREATE TABLE [dbo].[MessageTemplate] (
        [id] NVARCHAR(100) NOT NULL PRIMARY KEY,
        [title] NVARCHAR(255) NOT NULL,
        [shortcut] NVARCHAR(50) NULL,
        [category] NVARCHAR(100) NOT NULL DEFAULT 'BÁO GIÁ',
        [content] NVARCHAR(MAX) NOT NULL,
        [imageUrl] NVARCHAR(MAX) NULL,
        [isGlobal] BIT NOT NULL DEFAULT 1,
        [sortOrder] INT NOT NULL DEFAULT 0,
        [createdById] NVARCHAR(100) NOT NULL,
        [createdAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [updatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [FK_MessageTemplate_User] FOREIGN KEY ([createdById]) REFERENCES [dbo].[User]([id])
    );
END;
