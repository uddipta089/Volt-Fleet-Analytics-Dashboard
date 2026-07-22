USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE WAREHOUSE VOLT_FLEET_WH 
WITH WAREHOUSE_SIZE = 'XSMALL' 
AUTO_SUSPEND = 300 
AUTO_RESUME = TRUE;

CREATE OR REPLACE DATABASE VOLT_FLEET_DB;
CREATE OR REPLACE SCHEMA VOLT_FLEET_DB.RAW;
CREATE OR REPLACE SCHEMA VOLT_FLEET_DB.ANALYTICS;

USE SCHEMA VOLT_FLEET_DB.RAW;

CREATE OR REPLACE STORAGE INTEGRATION s3_baas_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://volt-fleet-analytics-baas-ev/')
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::402010192995:role/volt-fleet-analytics';

-- After running this, copy the generated IAM User ARN to update your AWS Trust Policy
DESC STORAGE INTEGRATION s3_baas_integration;

CREATE OR REPLACE FILE FORMAT csv_baas_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('NULL', '')
  EMPTY_FIELD_AS_NULL = TRUE;

CREATE OR REPLACE STAGE s3_baas_stage
  URL = 's3://volt-fleet-analytics-baas-ev/'
  STORAGE_INTEGRATION = s3_baas_integration
  FILE_FORMAT = csv_baas_format;


  CREATE OR REPLACE TABLE Dim_Stations (
    StationID VARCHAR(50) PRIMARY KEY,
    City VARCHAR(100),
    Total_Ports INT,
    Peak_Grid_Cost_Per_kWh NUMBER(10,2),
    OffPeak_Grid_Cost_Per_kWh NUMBER(10,2)
);

CREATE OR REPLACE TABLE Dim_Customers (
    CustomerID VARCHAR(50) PRIMARY KEY,
    City VARCHAR(100),
    Vehicle_Model VARCHAR(100),
    Subscription_Plan VARCHAR(50),
    Rate_Per_KM NUMBER(10,2),
    Monthly_Fee NUMBER(10,2),
    Account_Status VARCHAR(50)
);

CREATE OR REPLACE TABLE Dim_Batteries (
    BatteryID VARCHAR(50) PRIMARY KEY,
    Capacity_kWh INT,
    Manufacturer VARCHAR(100),
    Manufacture_Date DATE,
    Current_SoH_Pct NUMBER(5,2)
);

CREATE OR REPLACE TABLE Fact_Swap_Transactions (
    TransactionID VARCHAR(50) PRIMARY KEY,
    Date DATE,
    CustomerID VARCHAR(50),
    StationID VARCHAR(50),
    Battery_Returned_ID VARCHAR(50),
    Battery_Issued_ID VARCHAR(50),
    Odometer_Reading INT,
    Wait_Time_Minutes INT
);

CREATE OR REPLACE TABLE Fact_Charging_Logs (
    LogID VARCHAR(50) PRIMARY KEY,
    Date DATE,
    StationID VARCHAR(50),
    BatteryID VARCHAR(50),
    Start_Hour INT,
    Energy_Consumed_kWh NUMBER(10,2),
    Is_Peak_Hour INT,
    Total_Cost_INR NUMBER(12,2)
);

COPY INTO Dim_Stations FROM @s3_baas_stage/stations.csv;
COPY INTO Dim_Customers FROM @s3_baas_stage/customers.csv;
COPY INTO Dim_Batteries FROM @s3_baas_stage/batteries.csv;
COPY INTO Fact_Swap_Transactions FROM @s3_baas_stage/swap_transactions.csv;
COPY INTO Fact_Charging_Logs FROM @s3_baas_stage/charging_logs.csv;


-- Switch to the Analytics layer
USE SCHEMA VOLT_FLEET_DB.ANALYTICS;

-- 1. Transform Customers: Handle NULLs in billing and standardize text
CREATE OR REPLACE VIEW vw_clean_customers AS
SELECT 
    CustomerID,
    UPPER(TRIM(City)) AS City,
    Vehicle_Model,
    Subscription_Plan,
    COALESCE(Rate_Per_KM, 0) AS Rate_Per_KM,
    COALESCE(Monthly_Fee, 0) AS Monthly_Fee,
    Account_Status
FROM VOLT_FLEET_DB.RAW.Dim_Customers;

-- 2. Transform Batteries: Categorize State of Health (SoH)
CREATE OR REPLACE VIEW vw_clean_batteries AS
SELECT 
    BatteryID,
    Capacity_kWh,
    UPPER(TRIM(Manufacturer)) AS Manufacturer,
    Manufacture_Date,
    Current_SoH_Pct,
    CASE 
        WHEN Current_SoH_Pct < 80.0 THEN 'Degraded - Replace Soon'
        WHEN Current_SoH_Pct BETWEEN 80.0 AND 90.0 THEN 'Warning - Monitor'
        ELSE 'Healthy'
    END AS Battery_Health_Status
FROM VOLT_FLEET_DB.RAW.Dim_Batteries;

-- 3. Transform Swaps: Remove duplicates and create 'Stockout' proxy logic
CREATE OR REPLACE VIEW vw_clean_swaps AS
SELECT DISTINCT 
    TransactionID,
    Date,
    CustomerID,
    StationID,
    Battery_Returned_ID,
    Battery_Issued_ID,
    Odometer_Reading,
    COALESCE(Wait_Time_Minutes, 0) AS Wait_Time_Minutes,
    CASE 
        WHEN Wait_Time_Minutes > 15 THEN 1 
        ELSE 0 
    END AS Is_Stockout_Proxy
FROM VOLT_FLEET_DB.RAW.Fact_Swap_Transactions;

-- 4. Transform Charging Logs: Filter invalid energy pulls
CREATE OR REPLACE VIEW vw_clean_charging AS
SELECT 
    LogID,
    Date,
    StationID,
    BatteryID,
    Start_Hour,
    Energy_Consumed_kWh,
    Is_Peak_Hour,
    Total_Cost_INR
FROM VOLT_FLEET_DB.RAW.Fact_Charging_Logs
WHERE Energy_Consumed_kWh > 0;


-- 1. How many total active customers are registered?
SELECT COUNT(CustomerID) AS Total_Active_Customers 
FROM vw_clean_customers WHERE Account_Status = 'Active';

-- 2. What is the breakdown of customers by Subscription Plan?
SELECT Subscription_Plan, COUNT(*) AS Customer_Count 
FROM vw_clean_customers GROUP BY Subscription_Plan;

-- 3. How many customers are currently defaulted on their BaaS payments?
SELECT COUNT(*) AS Defaulted_Customers 
FROM vw_clean_customers WHERE Account_Status = 'Defaulted';

-- 4. What is the total energy consumed across all BaaS stations?
SELECT SUM(Energy_Consumed_kWh) AS Total_Energy_kWh FROM vw_clean_charging;

-- 5. What is the average wait time for an EV driver swapping a battery?
SELECT AVG(Wait_Time_Minutes) AS Avg_Wait_Time FROM vw_clean_swaps;

-- 6. What is the total grid cost incurred by the BaaS company?
SELECT SUM(Total_Cost_INR) AS Total_Grid_Cost FROM vw_clean_charging;

-- 7. Which city has the most physical swap stations?
SELECT City, COUNT(StationID) AS Station_Count 
FROM VOLT_FLEET_DB.RAW.Dim_Stations GROUP BY City ORDER BY Station_Count DESC;

-- 8. What is the average State of Health (SoH) of the entire battery fleet?
SELECT AVG(Current_SoH_Pct) AS Avg_Fleet_SoH FROM vw_clean_batteries;

-- 9. How many batteries are currently classified as 'Degraded'?
SELECT COUNT(*) AS Degraded_Battery_Count 
FROM vw_clean_batteries WHERE Battery_Health_Status = 'Degraded - Replace Soon';

-- 10. Total charging cost incurred by 'Exide' manufactured batteries?
SELECT b.Manufacturer, SUM(c.Total_Cost_INR) AS Total_Cost
FROM vw_clean_charging c
JOIN vw_clean_batteries b ON c.BatteryID = b.BatteryID
WHERE b.Manufacturer = 'EXIDE'
GROUP BY b.Manufacturer;




-- 11. What is the total grid cost broken down by Peak vs. Off-Peak charging?
SELECT 
    CASE WHEN Is_Peak_Hour = 1 THEN 'Peak Hours' ELSE 'Off-Peak Hours' END AS Charging_Time,
    SUM(Total_Cost_INR) AS Total_Cost,
    SUM(Energy_Consumed_kWh) AS Total_Energy
FROM vw_clean_charging
GROUP BY Is_Peak_Hour;

-- 12. Which 5 stations process the highest volume of battery swaps?
SELECT StationID, COUNT(TransactionID) AS Total_Swaps 
FROM vw_clean_swaps 
GROUP BY StationID ORDER BY Total_Swaps DESC LIMIT 5;

-- 13. What is the average battery degradation (SoH) by Manufacturer?
SELECT Manufacturer, AVG(Current_SoH_Pct) AS Avg_Health 
FROM vw_clean_batteries 
GROUP BY Manufacturer ORDER BY Avg_Health ASC;

-- 14. What is the customer default rate percentage?
SELECT 
    ROUND((SUM(CASE WHEN Account_Status = 'Defaulted' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS Default_Rate_Pct
FROM vw_clean_customers;

-- 15. What is the average driver wait time by City?
SELECT c.City, AVG(s.Wait_Time_Minutes) AS Avg_Wait
FROM vw_clean_swaps s
JOIN vw_clean_customers c ON s.CustomerID = c.CustomerID
GROUP BY c.City ORDER BY Avg_Wait DESC;

-- 16. How many stockout events (wait > 15 mins) occurred per station?
SELECT StationID, SUM(Is_Stockout_Proxy) AS Total_Stockouts
FROM vw_clean_swaps
GROUP BY StationID ORDER BY Total_Stockouts DESC;

-- 17. Find all drivers who have executed more than 50 battery swaps.
SELECT CustomerID, COUNT(TransactionID) AS Swap_Count
FROM vw_clean_swaps
GROUP BY CustomerID HAVING COUNT(TransactionID) > 50;

-- 18. What is the average energy cost per kWh during peak vs off-peak?
SELECT 
    Is_Peak_Hour, 
    ROUND(SUM(Total_Cost_INR) / SUM(Energy_Consumed_kWh), 2) AS Avg_Cost_Per_kWh
FROM vw_clean_charging GROUP BY Is_Peak_Hour;

-- 19. Total Projected Monthly Revenue from 'Fixed-Monthly' tier drivers by City.
SELECT City, SUM(Monthly_Fee) AS Total_Monthly_Recurring_Revenue
FROM vw_clean_customers 
WHERE Subscription_Plan = 'Fixed-Monthly' AND Account_Status = 'Active'
GROUP BY City;

-- 20. Which vehicle model is driven by the most customers?
SELECT Vehicle_Model, COUNT(CustomerID) AS Driver_Count 
FROM vw_clean_customers 
GROUP BY Vehicle_Model ORDER BY Driver_Count DESC;




-- 21. Rank stations by their total grid cost using a Window Function.
SELECT 
    StationID, 
    SUM(Total_Cost_INR) AS Total_Cost,
    RANK() OVER(ORDER BY SUM(Total_Cost_INR) DESC) AS Cost_Rank
FROM vw_clean_charging
GROUP BY StationID;

-- 22. Calculate the rolling 7-day average of swaps per station.
WITH DailySwaps AS (
    SELECT StationID, Date, COUNT(TransactionID) AS Daily_Swaps
    FROM vw_clean_swaps GROUP BY StationID, Date
)
SELECT 
    StationID, 
    Date, 
    Daily_Swaps,
    AVG(Daily_Swaps) OVER(PARTITION BY StationID ORDER BY Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS Rolling_7Day_Avg
FROM DailySwaps;

-- 23. Identify "Problem Stations" where the stockout rate is higher than the overall company average.
WITH StationStockouts AS (
    SELECT StationID, AVG(Is_Stockout_Proxy) AS Station_Stockout_Rate
    FROM vw_clean_swaps GROUP BY StationID
),
CompanyAverage AS (
    SELECT AVG(Is_Stockout_Proxy) AS Overall_Avg FROM vw_clean_swaps
)
SELECT s.StationID, s.Station_Stockout_Rate, c.Overall_Avg
FROM StationStockouts s
CROSS JOIN CompanyAverage c
WHERE s.Station_Stockout_Rate > c.Overall_Avg;

-- 24. Calculate the percentage of charging that happens during peak hours for each station.
WITH ChargingStats AS (
    SELECT 
        StationID,
        SUM(CASE WHEN Is_Peak_Hour = 1 THEN Energy_Consumed_kWh ELSE 0 END) AS Peak_Energy,
        SUM(Energy_Consumed_kWh) AS Total_Energy
    FROM vw_clean_charging GROUP BY StationID
)
SELECT 
    StationID, 
    ROUND((Peak_Energy / Total_Energy) * 100, 2) AS Peak_Energy_Pct
FROM ChargingStats ORDER BY Peak_Energy_Pct DESC;

-- 25. Compare the grid cost of each city against the city with the lowest overall cost.
WITH CityCosts AS (
    SELECT s.City, SUM(c.Total_Cost_INR) AS Total_Cost
    FROM vw_clean_charging c
    JOIN VOLT_FLEET_DB.RAW.Dim_Stations s ON c.StationID = s.StationID
    GROUP BY s.City
)
SELECT 
    City, 
    Total_Cost, 
    Total_Cost - MIN(Total_Cost) OVER() AS Cost_Difference_From_Lowest
FROM CityCosts;

-- 26. Create an Executive Summary View combining swap volume, stockouts, and total cost per swap.
CREATE OR REPLACE VIEW vw_station_executive_summary AS
WITH SwapVols AS (
    SELECT StationID, COUNT(TransactionID) AS Total_Swaps, SUM(Is_Stockout_Proxy) AS Total_Stockouts
    FROM vw_clean_swaps GROUP BY StationID
),
ChargeCosts AS (
    SELECT StationID, SUM(Total_Cost_INR) AS Total_Grid_Cost
    FROM vw_clean_charging GROUP BY StationID
)
SELECT 
    v.StationID, 
    v.Total_Swaps, 
    v.Total_Stockouts, 
    c.Total_Grid_Cost,
    ROUND(c.Total_Grid_Cost / v.Total_Swaps, 2) AS Cost_Per_Swap
FROM SwapVols v
JOIN ChargeCosts c ON v.StationID = c.StationID;