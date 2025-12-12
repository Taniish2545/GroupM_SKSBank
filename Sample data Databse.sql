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

-- Branches
INSERT INTO dbo.Branch(name, city) VALUES
('Downtown', 'Calgary'),
('Uptown',   'Calgary'),
('Riverside','Edmonton'),
('NorthHill','Edmonton'),
('Lakeside', 'Toronto');
GO

-- Employees 
INSERT INTO dbo.Employee (first_name, last_name, street, city, province, postal_code, start_date, role, manager_id) VALUES
('Mayur',    'Patel',  '101 1st St',  'Calgary',  'AB', NULL,'2020-01-15','Manager',          NULL),     
('Vrushank', 'Patel',  '202 2nd St',  'Calgary',  'AB', NULL,'2021-03-10','Personal Banker',  1), 
('Shrey',    'Patel',  '303 3rd St',  'Calgary',  'AB', NULL,'2022-05-01','Loan Officer',     1),   
('Noah',     'Park',   '404 4th St',  'Edmonton', 'AB', NULL,'2019-09-01','Manager',          NULL),   
('Emma',     'Singh',  '505 5th St',  'Edmonton', 'AB', NULL,'2023-02-11','Personal Banker',  4), 
('Lucas',    'Brown',  '606 6th St',  'Toronto',  'ON', NULL,'2018-07-21','Manager',          NULL), 
('Mia',      'Patel',  '707 7th St',  'Calgary',  'AB', NULL,'2021-11-12','Teller',           1),         
('Ethan',    'Zhao',   '808 8th St',  'Calgary',  'AB', NULL,'2020-08-08','Loan Officer',     1);  
GO

-- Locations + offices
INSERT INTO dbo.Location(location_type, street, city, province, branch_id) VALUES
('BRANCH','10 Main St',      'Calgary',  'AB', 1),
('BRANCH','22 King St',      'Calgary',  'AB', 2),
('BRANCH','35 River Rd',     'Edmonton', 'AB', 3),
('BRANCH','44 North Ave',    'Edmonton', 'AB', 4),
('BRANCH','50 Lake Dr',      'Toronto',  'ON', 5),
('OFFICE','900 9 Ave SW',    'Calgary',  'AB', NULL),
('OFFICE','1200 12 Ave NW',  'Edmonton', 'AB', NULL);
GO

-- Which locations employees work at
INSERT INTO dbo.EmployeeLocation(employee_id, location_id) VALUES
(1,1),(2,1),(3,1),(7,1),
(4,3),(5,4),
(6,5),
(8,2),
(2,6),(3,6),  -- Calgary office
(5,7);        -- Edmonton office
GO

-- Customers
INSERT INTO dbo.Customer(first_name, last_name, street, city, province, postal_code, personal_banker_id, loan_officer_id) VALUES
('Prit',     'Patel',  '12 Apple Ln',   'Calgary',  'AB', NULL, 2, 3),
('Arpan',    'Smith',  '34 Berry Rd',   'Calgary',  'AB', NULL, 2, 8),
('Tanish',   'Patel',  '56 Cedar St',   'Edmonton', 'AB', NULL, 5, 4),
('Aaisha',   'Khan',   '78 Dogwood Dr', 'Edmonton', 'AB', NULL, 5, 4),
('Priyanka', 'Chopra', '90 Elm St',     'Toronto',  'ON', NULL, NULL, 6),
('Mark',     'Patel',  '11 Fir St',     'Calgary',  'AB', NULL, 2, NULL);
GO

-- Accounts
INSERT INTO dbo.Account(branch_id, account_type, balance, last_accessed) VALUES
(1,'CHEQUING', 2500.00,'2024-10-01'),
(1,'SAVINGS',  5000.00,'2024-10-02'),
(3,'CHEQUING',  750.00,'2024-09-28'),
(4,'CHEQUING', 1300.00,'2024-09-30'),
(5,'SAVINGS',  9800.00,'2024-10-05'),
(2,'SAVINGS',  1200.00,'2024-10-04');
GO

-- Savings accounts
INSERT INTO dbo.SavingsAccount(account_id, interest_rate) VALUES
(2, 0.0150),
(5, 0.0200),
(6, 0.0125);
GO

-- Chequing accounts
INSERT INTO dbo.ChequingAccount(account_id) VALUES
(1),(3),(4);
GO

-- Joint holders (customers accounts)
INSERT INTO dbo.AccountHolder(account_id, customer_id, holder_role, since_date) VALUES
(1,1,'PRIMARY','2022-02-01'),
(1,2,'JOINT','2022-02-01'),
(2,1,'PRIMARY','2022-02-01'),
(3,3,'PRIMARY','2023-06-15'),
(4,4,'PRIMARY','2023-07-20'),
(5,5,'PRIMARY','2023-09-10'),
(6,6,'PRIMARY','2023-01-01');
GO

-- Overdrafts only chequing
INSERT INTO dbo.Overdraft(account_id, od_date, amount, check_number) VALUES
(1,'2024-09-10', 150.00, 'CHK-1001'),
(1,'2024-09-12',  80.50, 'CHK-1002'),
(3,'2024-08-01',  45.00, 'CHK-2101'),
(4,'2024-07-22', 300.00, 'CHK-3301'),
(4,'2024-09-02', 120.00, 'CHK-3302');
GO

-- Loans
INSERT INTO dbo.Loan(origin_branch_id, amount, start_date) VALUES
(1, 20000.00,'2024-03-01'),
(3, 350000.00,'2023-11-15'),
(4, 15000.00,'2025-01-10'),
(2, 8000.00,'2024-09-05'),
(5, 120000.00,'2024-12-20');
GO

-- Loan customers
INSERT INTO dbo.LoanCustomer(loan_id, customer_id, role) VALUES
(1,1,'PRIMARY'),
(1,2,'CO-BORROWER'),
(2,3,'PRIMARY'),
(3,4,'PRIMARY'),
(4,6,'PRIMARY'),
(5,5,'PRIMARY');
GO

-- Loan payments
INSERT INTO dbo.LoanPayment(loan_id, payment_no, payment_date, amount) VALUES
(1,1,'2023-04-01', 500.00),
(1,2,'2023-05-01', 500.00),
(1,3,'2023-06-01', 500.00),
(2,1,'2023-12-15', 3500.00),
(2,2,'2024-01-15', 3500.00),
(3,1,'2025-02-10', 400.00),
(4,1,'2024-10-05', 200.00),
(5,1,'2025-01-20', 1200.00);
GO

-- Accounts linked to loans
INSERT INTO dbo.AccountLoan(account_id, loan_id) VALUES
(1,1),
(2,1),
(3,2),
(4,3),
(6,4),
(5,5);
GO
