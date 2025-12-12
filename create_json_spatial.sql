/*
   DATA2201 – Relational Databases
   Phase 2
   Group M:
      Tanish Jigarbhai Patel
      Het Jaldipbhai Patel
      Mayur Harshadbhai Patel
      Vraj Dineshkumar Mistry
*/

USE SKS_Bank;
GO


-- Add JSON Column to Account

IF COL_LENGTH('dbo.Account', 'preferences') IS NULL
BEGIN
    ALTER TABLE dbo.Account
    ADD preferences NVARCHAR(MAX)
        CONSTRAINT CK_Account_Preferences_JSON CHECK (preferences IS NULL OR ISJSON(preferences) = 1);
END;
GO

-- Insert sample JSON
UPDATE dbo.Account
SET preferences = '{"notifications":true,"daily_limit":500,"currency":"CAD"}'
WHERE account_id = 1;

UPDATE dbo.Account
SET preferences = '{"notifications":false,"daily_limit":1000,"currency":"USD"}'
WHERE account_id = 2;
GO



-- Add Spatial Geography Column to Branch

IF COL_LENGTH('dbo.Branch', 'branch_location') IS NULL
BEGIN
    ALTER TABLE dbo.Branch
    ADD branch_location GEOGRAPHY NULL;
END;
GO

-- Sample coordinates
UPDATE dbo.Branch
SET branch_location = GEOGRAPHY::Point(51.0447, -114.0719, 4326)
WHERE branch_id = 1;

UPDATE dbo.Branch
SET branch_location = GEOGRAPHY::Point(53.5461, -113.4938, 4326) 
WHERE branch_id = 3;
GO


-- TEST JSON + SPATIAL

-- Test JSON reading
SELECT 
    account_id,
    preferences,
    JSON_VALUE(preferences, '$.daily_limit') AS daily_limit,
    JSON_VALUE(preferences, '$.currency') AS currency
FROM dbo.Account;

-- Test spatial reading
SELECT
    branch_id,
    name,
    city,
    branch_location.Lat AS latitude,
    branch_location.Long AS longitude
FROM dbo.Branch
WHERE branch_location IS NOT NULL;
GO
