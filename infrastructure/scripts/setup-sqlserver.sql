-- SQL Server Setup Script
-- This script creates the Customer table and sample data for testing

-- Create Customer table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Customer] (
        [CustomerId] INT PRIMARY KEY IDENTITY(1,1),
        [Name] NVARCHAR(100) NOT NULL,
        [Email] NVARCHAR(100) NOT NULL,
        [Active] BIT DEFAULT 1,
        [CreatedDate] DATETIME DEFAULT GETDATE(),
        [ModifiedDate] DATETIME DEFAULT GETDATE()
    );
    
    PRINT 'Customer table created successfully.';
END
ELSE
BEGIN
    PRINT 'Customer table already exists.';
END
GO

-- Create index for better performance on triggers
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customer_CreatedDate' AND object_id = OBJECT_ID('dbo.Customer'))
BEGIN
    CREATE INDEX IX_Customer_CreatedDate ON dbo.Customer(CreatedDate);
    PRINT 'Index IX_Customer_CreatedDate created.';
END
GO

-- Add ModifiedDate update trigger (optional, for tracking changes)
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'TR_Customer_UpdateModifiedDate')
BEGIN
    EXEC('
    CREATE TRIGGER TR_Customer_UpdateModifiedDate
    ON dbo.Customer
    AFTER UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;
        UPDATE dbo.Customer
        SET ModifiedDate = GETDATE()
        FROM dbo.Customer c
        INNER JOIN inserted i ON c.CustomerId = i.CustomerId;
    END
    ');
    PRINT 'Trigger TR_Customer_UpdateModifiedDate created.';
END
GO

-- Insert sample test data
PRINT 'Inserting sample data...';

INSERT INTO dbo.Customer (Name, Email, Active)
VALUES 
    ('John Smith', 'john.smith@example.com', 1),
    ('Jane Doe', 'jane.doe@example.com', 1),
    ('Bob Johnson', 'bob.johnson@example.com', 1),
    ('Alice Williams', 'alice.williams@example.com', 1),
    ('Charlie Brown', 'charlie.brown@example.com', 1);

PRINT 'Sample data inserted.';
GO

-- Verify the data
SELECT 
    CustomerId,
    Name,
    Email,
    Active,
    CreatedDate,
    ModifiedDate
FROM dbo.Customer
ORDER BY CustomerId;

PRINT 'Setup complete!';
GO
