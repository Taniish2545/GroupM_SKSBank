/*
   DATA2201 – Relational Databases
   Phase 2
   Group M:
      Tanish Jigarbhai Patel
      Het Jaldipbhai Patel
      Mayur Harshadbhai Patel
      Vraj Dineshkumar Mistry
*/

-- 3 custom triggers + Audit table + test queries

USE SKS_Bank;
GO


-- 1. Create Audit Table

IF OBJECT_ID('dbo.Audit', 'U') IS NOT NULL
    DROP TABLE dbo.Audit;
GO

CREATE TABLE dbo.Audit (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    description NVARCHAR(4000) NOT NULL,
    changed_at DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME())
);
GO


-- Trigger 1 – Log NEW Customers

IF OBJECT_ID('dbo.trg_CustomerInsert_Audit', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_CustomerInsert_Audit;
GO

CREATE TRIGGER dbo.trg_CustomerInsert_Audit
ON dbo.Customer
AFTER INSERT
AS
BEGIN
    INSERT INTO dbo.Audit (description)
    SELECT CONCAT(
        'New customer created. ID=', i.customer_id,
        ', Name=', i.first_name, ' ', i.last_name
    )
    FROM inserted AS i;
END;
GO


-- Trigger 2 – Log Account UPDATE 

IF OBJECT_ID('dbo.trg_AccountUpdate_Audit', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_AccountUpdate_Audit;
GO

CREATE TRIGGER dbo.trg_AccountUpdate_Audit
ON dbo.Account
AFTER UPDATE
AS
BEGIN
    IF NOT (UPDATE(balance) OR UPDATE(last_accessed))
        RETURN;

    INSERT INTO dbo.Audit (description)
    SELECT CONCAT(
        'Account updated. ID=', i.account_id,
        ' | Old balance=', d.balance,
        ' | New balance=', i.balance,
        ' | Old last_accessed=', CONVERT(NVARCHAR(30), d.last_accessed, 126),
        ' | New last_accessed=', CONVERT(NVARCHAR(30), i.last_accessed, 126)
    )
    FROM inserted i
    JOIN deleted d ON d.account_id = i.account_id
    WHERE 
        d.balance <> i.balance
        OR d.last_accessed <> i.last_accessed;
END;
GO


-- Trigger 3 – Log NEW Overdrafts

IF OBJECT_ID('dbo.trg_OverdraftInsert_Audit', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_OverdraftInsert_Audit;
GO

CREATE TRIGGER dbo.trg_OverdraftInsert_Audit
ON dbo.Overdraft
AFTER INSERT
AS
BEGIN
    INSERT INTO dbo.Audit (description)
    SELECT CONCAT(
        'New overdraft created. account_id=', i.account_id,
        ', amount=', i.amount,
        ', date=', CONVERT(NVARCHAR(30), i.od_date, 126),
        ', check_number=', i.check_number
    )
    FROM inserted i;
END;
GO


-- 5. TEST THE TRIGGERS


-- Test Customer insert
INSERT INTO dbo.Customer (first_name, last_name, street, city, province, postal_code,
                           personal_banker_id, loan_officer_id)
VALUES ('Test', 'Customer', '100 Test St', 'Calgary', 'AB', 'T1T1T1', NULL, NULL);

-- Test Account update
UPDATE dbo.Account
SET balance = balance + 100
WHERE account_id = 1;

-- Test Overdraft insert
INSERT INTO dbo.Overdraft (account_id, od_date, amount, check_number)
VALUES (1, GETDATE(), 200.00, 'CHK-9999');

-- View Audit Log
SELECT * FROM dbo.Audit ORDER BY audit_id;
GO
