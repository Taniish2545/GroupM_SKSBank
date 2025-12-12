/*
   DATA2201 – Relational Databases
   Phase 2
   Group M:
      Tanish Jigarbhai Patel
      Het Jaldipbhai Patel
      Mayur Harshadbhai Patel
      Vraj Dineshkumar Mistry
*/
-- Creates logins & users for:
-- customer_group_M
-- accountant_group_M

-- 1. Create login 

USE master;
GO

-- Drop existing logins if script re-run
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'customer_group_M')
    DROP LOGIN customer_group_M;
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'accountant_group_M')
    DROP LOGIN accountant_group_M;
GO

-- Create logins (simple passwords for assignment)
CREATE LOGIN customer_group_M
WITH PASSWORD = 'customer',
     CHECK_POLICY = OFF;
GO

CREATE LOGIN accountant_group_M
WITH PASSWORD = 'accountant',
     CHECK_POLICY = OFF;
GO


-- 2. Create users in SKS_Bank database & grant permissions

USE SKS_Bank;
GO

-- Drop database users if re-run
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'customer_group_M')
    DROP USER customer_group_M;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'accountant_group_M')
    DROP USER accountant_group_M;
GO

-- Create users
CREATE USER customer_group_M FOR LOGIN customer_group_M;
GO

CREATE USER accountant_group_M FOR LOGIN accountant_group_M;
GO



-- Permissions for customer_group_M
-- READ-ONLY on customer-related tables
-- Cannot see employee or branch tables

GRANT SELECT ON dbo.Customer         TO customer_group_M;
GRANT SELECT ON dbo.Account          TO customer_group_M;
GRANT SELECT ON dbo.SavingsAccount   TO customer_group_M;
GRANT SELECT ON dbo.ChequingAccount  TO customer_group_M;
GRANT SELECT ON dbo.AccountHolder    TO customer_group_M;
GRANT SELECT ON dbo.Overdraft        TO customer_group_M;
GRANT SELECT ON dbo.Loan             TO customer_group_M;
GRANT SELECT ON dbo.LoanCustomer     TO customer_group_M;
GRANT SELECT ON dbo.LoanPayment      TO customer_group_M;
GRANT SELECT ON dbo.AccountLoan      TO customer_group_M;  -- if you have this table
GO



-- Permissions for accountant_group_M
-- Can read ALL tables
-- Cannot modify accounts or loans


-- Give read access to everything
EXEC sp_addrolemember 'db_datareader', 'accountant_group_M';
GO

DENY INSERT, UPDATE, DELETE ON dbo.Account         TO accountant_group_M;
DENY INSERT, UPDATE, DELETE ON dbo.SavingsAccount  TO accountant_group_M;
DENY INSERT, UPDATE, DELETE ON dbo.ChequingAccount TO accountant_group_M;
DENY INSERT, UPDATE, DELETE ON dbo.AccountHolder   TO accountant_group_M;
DENY INSERT, UPDATE, DELETE ON dbo.Overdraft       TO accountant_group_M;
DENY INSERT, UPDATE, DELETE ON dbo.Loan            TO accountant_group_M;
DENY INSERT, UPDATE, DELETE ON dbo.LoanCustomer    TO accountant_group_M;
DENY INSERT, UPDATE, DELETE ON dbo.LoanPayment     TO accountant_group_M;
DENY INSERT, UPDATE, DELETE ON dbo.AccountLoan     TO accountant_group_M;
GO

-- 3. TEST USERS


PRINT '=== TESTING customer_group_M ===';
GO

EXECUTE AS LOGIN = 'customer_group_M';

PRINT 'Should SUCCEED: SELECT Customer';
SELECT TOP 3 * FROM dbo.Customer;

PRINT 'Should FAIL: SELECT Employee';
BEGIN TRY
    SELECT TOP 3 * FROM dbo.Employee;
END TRY
BEGIN CATCH
    PRINT 'Correct: Access denied.';
END CATCH;

PRINT 'Should FAIL: UPDATE Customer';
BEGIN TRY
    UPDATE dbo.Customer SET city='X' WHERE customer_id=1;
END TRY
BEGIN CATCH
    PRINT 'Correct: UPDATE denied.';
END CATCH;

REVERT;
GO


PRINT '=== TESTING accountant_group_M ===';
GO

EXECUTE AS LOGIN = 'accountant_group_M';

PRINT 'Should SUCCEED: SELECT Branch';
SELECT TOP 3 * FROM dbo.Branch;

PRINT 'Should FAIL: UPDATE Account';
BEGIN TRY
    UPDATE dbo.Account SET balance = balance + 1 WHERE account_id=1;
END TRY
BEGIN CATCH
    PRINT 'Correct: UPDATE denied.';
END CATCH;

REVERT;
GO
