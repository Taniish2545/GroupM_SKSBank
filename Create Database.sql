/*
   DATA2201 – Relational Databases
   Phase 1
   Group M:- Tanish Jigarbhai Patel
             Het Jaldipbhai Patel
             Mayur Harshadbhai Patel
             Vraj Dineshkumar Mistry
*/
-- Drop & Create database
IF DB_ID('SKS_Bank') IS NOT NULL
BEGIN
    ALTER DATABASE SKS_Bank SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SKS_Bank;
END;
GO

CREATE DATABASE SKS_Bank;
GO

USE SKS_Bank;
GO

/*
   Tables
*/

-- Branches
CREATE TABLE dbo.Branch (
    branch_id      INT IDENTITY(1,1) CONSTRAINT PK_Branch PRIMARY KEY,
    name           NVARCHAR(100) NOT NULL UNIQUE,
    city           NVARCHAR(100) NOT NULL
);
GO

-- Employees (manager is self-referencing)
CREATE TABLE dbo.Employee (
    employee_id    INT IDENTITY(1,1) CONSTRAINT PK_Employee PRIMARY KEY,
    first_name     NVARCHAR(50)  NOT NULL,
    last_name      NVARCHAR(100) NOT NULL,
    street         NVARCHAR(150) NULL,
    city           NVARCHAR(100) NOT NULL,
    province       NVARCHAR(50)  NOT NULL,
    postal_code    NVARCHAR(20)  NULL,
    start_date     DATE          NOT NULL,
    role           NVARCHAR(50)  NOT NULL,
    manager_id     INT           NULL
);
GO

ALTER TABLE dbo.Employee
ADD CONSTRAINT FK_Employee_Manager
FOREIGN KEY (manager_id)
REFERENCES dbo.Employee(employee_id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;
GO

-- Location (branch or office)
CREATE TABLE dbo.Location (
    location_id   INT IDENTITY(1,1) CONSTRAINT PK_Location PRIMARY KEY,
    location_type NVARCHAR(20) NOT NULL
        CONSTRAINT CK_Location_Type CHECK (location_type IN ('BRANCH','OFFICE')),
    street        NVARCHAR(150) NULL,
    city          NVARCHAR(100) NOT NULL,
    province      NVARCHAR(50)  NOT NULL,
    branch_id     INT NULL
);
GO

ALTER TABLE dbo.Location
ADD CONSTRAINT FK_Location_Branch
FOREIGN KEY (branch_id)
REFERENCES dbo.Branch(branch_id)
ON UPDATE NO ACTION
ON DELETE SET NULL;
GO

-- Which locations an employee works at 
CREATE TABLE dbo.EmployeeLocation (
    employee_id INT NOT NULL
        CONSTRAINT FK_EmployeeLocation_Employee
        REFERENCES dbo.Employee(employee_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    location_id INT NOT NULL
        CONSTRAINT FK_EmployeeLocation_Location
        REFERENCES dbo.Location(location_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT PK_EmployeeLocation PRIMARY KEY (employee_id, location_id)
);
GO

-- Customers
CREATE TABLE dbo.Customer (
    customer_id        INT IDENTITY(1,1) CONSTRAINT PK_Customer PRIMARY KEY,
    first_name         NVARCHAR(50)  NOT NULL,
    last_name          NVARCHAR(100) NOT NULL,
    street             NVARCHAR(150) NULL,
    city               NVARCHAR(100) NOT NULL,
    province           NVARCHAR(50)  NOT NULL,
    postal_code        NVARCHAR(20)  NULL,
    personal_banker_id INT NULL,
    loan_officer_id    INT NULL
);
GO

ALTER TABLE dbo.Customer
ADD CONSTRAINT FK_Customer_PersonalBanker
FOREIGN KEY (personal_banker_id)
REFERENCES dbo.Employee(employee_id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;
GO

ALTER TABLE dbo.Customer
ADD CONSTRAINT FK_Customer_LoanOfficer
FOREIGN KEY (loan_officer_id)
REFERENCES dbo.Employee(employee_id)
ON UPDATE NO ACTION
ON DELETE NO ACTION;
GO

-- Accounts
CREATE TABLE dbo.Account (
    account_id     INT IDENTITY(1,1) CONSTRAINT PK_Account PRIMARY KEY,
    branch_id      INT NOT NULL
        CONSTRAINT FK_Account_Branch
        REFERENCES dbo.Branch(branch_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    account_type   NVARCHAR(20) NOT NULL
        CONSTRAINT CK_Account_Type CHECK (account_type IN ('CHEQUING','SAVINGS')),
    balance        DECIMAL(12,2) NOT NULL CONSTRAINT DF_Account_Balance DEFAULT (0),
    last_accessed  DATE NOT NULL
);
GO

-- Savings-specific attributes
CREATE TABLE dbo.SavingsAccount (
    account_id    INT NOT NULL
        CONSTRAINT PK_SavingsAccount PRIMARY KEY
        CONSTRAINT FK_SavingsAccount_Account
        REFERENCES dbo.Account(account_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    interest_rate DECIMAL(5,4) NOT NULL -- e.g., 0.0150 for 1.50%
);
GO

-- Chequing-specific marker table
CREATE TABLE dbo.ChequingAccount (
    account_id INT NOT NULL
        CONSTRAINT PK_ChequingAccount PRIMARY KEY
        CONSTRAINT FK_ChequingAccount_Account
        REFERENCES dbo.Account(account_id)
        ON UPDATE NO ACTION ON DELETE CASCADE
);
GO

-- Joint account holders 
CREATE TABLE dbo.AccountHolder (
    account_id   INT NOT NULL
        CONSTRAINT FK_AccountHolder_Account
        REFERENCES dbo.Account(account_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    customer_id  INT NOT NULL
        CONSTRAINT FK_AccountHolder_Customer
        REFERENCES dbo.Customer(customer_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    holder_role  NVARCHAR(20) NOT NULL
        CONSTRAINT CK_AccountHolder_Role CHECK (holder_role IN ('PRIMARY','JOINT')),
    since_date   DATE NOT NULL,
    CONSTRAINT PK_AccountHolder PRIMARY KEY (account_id, customer_id)
);
GO

-- Overdrafts for chequing accounts only
CREATE TABLE dbo.Overdraft (
    overdraft_id  INT IDENTITY(1,1) CONSTRAINT PK_Overdraft PRIMARY KEY,
    account_id    INT NOT NULL
        CONSTRAINT FK_Overdraft_Chequing
        REFERENCES dbo.ChequingAccount(account_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    od_date       DATE NOT NULL,
    amount        DECIMAL(12,2) NOT NULL,
    check_number  NVARCHAR(30) NULL
);
GO

-- Loans 
CREATE TABLE dbo.Loan (
    loan_id           INT IDENTITY(1,1) CONSTRAINT PK_Loan PRIMARY KEY,
    origin_branch_id  INT NOT NULL
        CONSTRAINT FK_Loan_Branch
        REFERENCES dbo.Branch(branch_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    amount            DECIMAL(12,2) NOT NULL,
    start_date        DATE NOT NULL
);
GO

-- Which customers hold a loan
CREATE TABLE dbo.LoanCustomer (
    loan_id     INT NOT NULL
        CONSTRAINT FK_LoanCustomer_Loan
        REFERENCES dbo.Loan(loan_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    customer_id INT NOT NULL
        CONSTRAINT FK_LoanCustomer_Customer
        REFERENCES dbo.Customer(customer_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    role        NVARCHAR(20) NOT NULL
        CONSTRAINT CK_LoanCustomer_Role CHECK (role IN ('PRIMARY','CO-BORROWER')),
    CONSTRAINT PK_LoanCustomer PRIMARY KEY (loan_id, customer_id)
);
GO

-- Loan payments
CREATE TABLE dbo.LoanPayment (
    loan_id       INT NOT NULL
        CONSTRAINT FK_LoanPayment_Loan
        REFERENCES dbo.Loan(loan_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    payment_no    INT NOT NULL,
    payment_date  DATE NOT NULL,
    amount        DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_LoanPayment PRIMARY KEY (loan_id, payment_no)
);
GO

-- Accounts linked to loans (M:N)
CREATE TABLE dbo.AccountLoan (
    account_id INT NOT NULL
        CONSTRAINT FK_AccountLoan_Account
        REFERENCES dbo.Account(account_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    loan_id    INT NOT NULL
        CONSTRAINT FK_AccountLoan_Loan
        REFERENCES dbo.Loan(loan_id)
        ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT PK_AccountLoan PRIMARY KEY (account_id, loan_id)
);
GO

-- Total deposit balances by branch
CREATE VIEW dbo.v_BranchDepositTotals
AS
SELECT
    b.branch_id,
    b.name AS branch_name,
    SUM(a.balance) AS total_deposits
FROM dbo.Branch b
LEFT JOIN dbo.Account a
    ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.name;
GO

-- Total loan amounts and total payments by branch of loan origin
CREATE VIEW dbo.v_BranchLoanTotals
AS
SELECT
    b.branch_id,
    b.name AS branch_name,
    SUM(l.amount) AS total_loan_amounts,
    SUM(ISNULL(lp.amount,0)) AS total_loan_payments
FROM dbo.Branch b
LEFT JOIN dbo.Loan l
    ON l.origin_branch_id = b.branch_id
LEFT JOIN dbo.LoanPayment lp
    ON lp.loan_id = l.loan_id
GROUP BY b.branch_id, b.name;
GO
