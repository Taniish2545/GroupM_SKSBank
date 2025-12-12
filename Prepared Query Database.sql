/*
   DATA2201 – Relational Databases
   Phase 1
   Group M:
      Tanish Jigarbhai Patel
      Het Jaldipbhai Patel
      Mayur Harshadbhai Patel
      Vraj Dineshkumar Mistry
*/

USE SKS_Bank;
GO

/* Customer accounts & balances */
IF OBJECT_ID('dbo.sp_GetCustomerAccounts','P') IS NOT NULL DROP PROCEDURE dbo.sp_GetCustomerAccounts;
GO
CREATE PROCEDURE dbo.sp_GetCustomerAccounts
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT a.account_id, a.account_type, a.balance, a.last_accessed, b.name AS branch_name
    FROM dbo.AccountHolder ah
    JOIN dbo.Account a ON a.account_id = ah.account_id
    JOIN dbo.Branch b ON b.branch_id = a.branch_id
    WHERE ah.customer_id = @CustomerId
    ORDER BY a.account_id;
END;
GO
-- Test
EXEC dbo.sp_GetCustomerAccounts @CustomerId = 1;
GO

/* Branch totals */
IF OBJECT_ID('dbo.sp_GetBranchTotals','P') IS NOT NULL DROP PROCEDURE dbo.sp_GetBranchTotals;
GO
CREATE PROCEDURE dbo.sp_GetBranchTotals
    @BranchId INT
AS
BEGIN
    SET NOCOUNT ON;
    /* Combines deposit & loan totals for a branch using views */
    SELECT d.branch_id, d.branch_name, d.total_deposits,
           l.total_loan_amounts, l.total_loan_payments
    FROM dbo.v_BranchDepositTotals d
    LEFT JOIN dbo.v_BranchLoanTotals l
      ON l.branch_id = d.branch_id
    WHERE d.branch_id = @BranchId;
END;
GO
-- Test
EXEC dbo.sp_GetBranchTotals @BranchId = 1;
GO

/* Overdrafts for a chequing account within a date range */
IF OBJECT_ID('dbo.sp_GetOverdraftsByAccount','P') IS NOT NULL DROP PROCEDURE dbo.sp_GetOverdraftsByAccount;
GO
CREATE PROCEDURE dbo.sp_GetOverdraftsByAccount
    @AccountId INT,
    @FromDate  DATE,
    @ToDate    DATE
AS
BEGIN
    SET NOCOUNT ON;
    /* Lists overdrafts for the specified chequing account in date range */
    SELECT o.overdraft_id, o.od_date, o.amount, o.check_number
    FROM dbo.Overdraft o
    WHERE o.account_id = @AccountId
      AND o.od_date BETWEEN @FromDate AND @ToDate
    ORDER BY o.od_date;
END;
GO
-- Test
EXEC dbo.sp_GetOverdraftsByAccount @AccountId = 1, @FromDate='2025-09-01', @ToDate='2025-09-30';
GO

/* Joint account holders */
IF OBJECT_ID('dbo.sp_ListJointAccountHolders','P') IS NOT NULL DROP PROCEDURE dbo.sp_ListJointAccountHolders;
GO
CREATE PROCEDURE dbo.sp_ListJointAccountHolders
    @AccountId INT
AS
BEGIN
    SET NOCOUNT ON;
    /* Shows all customers attached to an account and their holder roles */
    SELECT c.customer_id,
           CONCAT(c.first_name, ' ', c.last_name) AS name,
           ah.holder_role,
           ah.since_date
    FROM dbo.AccountHolder ah
    JOIN dbo.Customer c ON c.customer_id = ah.customer_id
    WHERE ah.account_id = @AccountId
    ORDER BY ah.holder_role DESC, c.last_name, c.first_name;
END;
GO
-- Test
EXEC dbo.sp_ListJointAccountHolders @AccountId = 1;
GO

/* Loan amortization-like summary (amount, total paid, balance) */
IF OBJECT_ID('dbo.sp_GetLoanSummary','P') IS NOT NULL DROP PROCEDURE dbo.sp_GetLoanSummary;
GO
CREATE PROCEDURE dbo.sp_GetLoanSummary
    @LoanId INT
AS
BEGIN
    SET NOCOUNT ON;
    /* Returns original amount, total paid to date, and remaining balance (simple) */
    SELECT
        l.loan_id,
        l.amount AS original_amount,
        ISNULL(SUM(lp.amount),0) AS total_paid,
        l.amount - ISNULL(SUM(lp.amount),0) AS remaining_balance
    FROM dbo.Loan l
    LEFT JOIN dbo.LoanPayment lp ON lp.loan_id = l.loan_id
    WHERE l.loan_id = @LoanId
    GROUP BY l.loan_id, l.amount;
END;
GO
-- Test
EXEC dbo.sp_GetLoanSummary @LoanId = 1;
GO

/* Employee manager chain (up to the top) using a recursive CTE */
IF OBJECT_ID('dbo.sp_GetManagerChain','P') IS NOT NULL DROP PROCEDURE dbo.sp_GetManagerChain;
GO
CREATE PROCEDURE dbo.sp_GetManagerChain
    @EmployeeId INT
AS
BEGIN
    SET NOCOUNT ON;
    WITH chain AS (
        SELECT e.employee_id,
               CONCAT(e.first_name, ' ', e.last_name) AS name,
               e.role,
               e.manager_id,
               0 AS lvl
        FROM dbo.Employee e
        WHERE e.employee_id = @EmployeeId
        UNION ALL
        SELECT m.employee_id,
               CONCAT(m.first_name, ' ', m.last_name) AS name,
               m.role,
               m.manager_id,
               c.lvl + 1
        FROM dbo.Employee m
        JOIN chain c ON c.manager_id = m.employee_id
    )
    SELECT employee_id, name, role, lvl
    FROM chain
    ORDER BY lvl;
END;
GO
-- Test
EXEC dbo.sp_GetManagerChain @EmployeeId = 2;
GO

/* Inactive accounts (not accessed since a given date) */
IF OBJECT_ID('dbo.sp_FindInactiveAccounts','P') IS NOT NULL DROP PROCEDURE dbo.sp_FindInactiveAccounts;
GO
CREATE PROCEDURE dbo.sp_FindInactiveAccounts
    @BeforeDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.account_id, a.account_type, a.last_accessed, b.name AS branch_name
    FROM dbo.Account a
    JOIN dbo.Branch b ON b.branch_id = a.branch_id
    WHERE a.last_accessed < @BeforeDate
    ORDER BY a.last_accessed;
END;
GO
-- Test
EXEC dbo.sp_FindInactiveAccounts @BeforeDate='2025-10-03';
GO

/* Staff assigned to a customer (personal banker & loan officer) */
IF OBJECT_ID('dbo.sp_AssignedStaffForCustomer','P') IS NOT NULL DROP PROCEDURE dbo.sp_AssignedStaffForCustomer;
GO
CREATE PROCEDURE dbo.sp_AssignedStaffForCustomer
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.customer_id,
           CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
           pb.employee_id AS personal_banker_id,
           CASE WHEN pb.employee_id IS NULL
                THEN NULL
                ELSE CONCAT(pb.first_name, ' ', pb.last_name)
           END AS personal_banker_name,
           lo.employee_id AS loan_officer_id,
           CASE WHEN lo.employee_id IS NULL
                THEN NULL
                ELSE CONCAT(lo.first_name, ' ', lo.last_name)
           END AS loan_officer_name
    FROM dbo.Customer c
    LEFT JOIN dbo.Employee pb ON pb.employee_id = c.personal_banker_id
    LEFT JOIN dbo.Employee lo ON lo.employee_id = c.loan_officer_id
    WHERE c.customer_id = @CustomerId;
END;
GO
-- Test
EXEC dbo.sp_AssignedStaffForCustomer @CustomerId = 1;
GO

/* Scalar function: total deposits held by a customer (sum of balances of all owned accounts) */
IF OBJECT_ID('dbo.udf_CustomerTotalDeposits','FN') IS NOT NULL DROP FUNCTION dbo.udf_CustomerTotalDeposits;
GO
CREATE FUNCTION dbo.udf_CustomerTotalDeposits (@CustomerId INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @total DECIMAL(18,2);
    SELECT @total = ISNULL(SUM(a.balance),0.00)
    FROM dbo.Account a
    JOIN dbo.AccountHolder ah ON ah.account_id = a.account_id
    WHERE ah.customer_id = @CustomerId;
    RETURN ISNULL(@total,0.00);
END;
GO
-- Test
SELECT dbo.udf_CustomerTotalDeposits(1) AS total_deposits_for_customer_1;
GO

/* Scalar function: total outstanding loan balance for a customer */
IF OBJECT_ID('dbo.udf_CustomerLoanBalance','FN') IS NOT NULL DROP FUNCTION dbo.udf_CustomerLoanBalance;
GO
CREATE FUNCTION dbo.udf_CustomerLoanBalance (@CustomerId INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @bal DECIMAL(18,2);
    ;WITH cust_loans AS (
        SELECT lc.loan_id
        FROM dbo.LoanCustomer lc
        WHERE lc.customer_id = @CustomerId
    ),
    pay AS (
        SELECT cl.loan_id, ISNULL(SUM(lp.amount),0) AS paid
        FROM cust_loans cl
        LEFT JOIN dbo.LoanPayment lp ON lp.loan_id = cl.loan_id
        GROUP BY cl.loan_id
    )
    SELECT @bal = ISNULL(SUM(l.amount - ISNULL(p.paid,0)),0.00)
    FROM cust_loans cl
    JOIN dbo.Loan l ON l.loan_id = cl.loan_id
    LEFT JOIN pay p ON p.loan_id = cl.loan_id;

    RETURN ISNULL(@bal,0.00);
END;
GO
-- Test
SELECT dbo.udf_CustomerLoanBalance(1) AS total_outstanding_loan_balance_for_customer_1;
GO
