-- ================================================
-- E-Commerce Cohort & Revenue Analysis
-- Dataset: Online Retail II (UCI ML Repository)
-- Author: Andrew Wilding
-- ================================================

-- ================================================
-- Step 1: Create and import data
-- ================================================
-- Create and select database
CREATE DATABASE ecommerce;
USE ecommerce;

-- Create transations table
CREATE TABLE transactions (
	invoice      VARCHAR(20),
	stock_code   VARCHAR(20),
    description  VARCHAR(255),
    quantity     INT,
    invoice_date DATETIME,
    unit_price   DECIMAL(10,2),
    customer_id  VARCHAR(20),
    country      VARCHAR(50)
);

-- Import data from CSV
LOAD DATA LOCAL INFILE "C:/Users/HoldT/Documents/SQL Projects/online+retail+ii/online_retail_II.csv"
INTO TABLE transactions
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@invoice, @stock_code, @description, @quantity, @invoice_date, @unit_price, @customer_id, @country)
SET
    invoice = TRIM(REPLACE(@invoice, '\r', '')),
    stock_code = @stock_code,
    description = @description,
    quantity = @quantity,
    invoice_date = @invoice_date,
    unit_price = @unit_price,
    customer_id = @customer_id,
    country = @country;
    
-- Verify import
SELECT COUNT(*) FROM transactions; -- 525461
SELECT * FROM transactions LIMIT 10;

ALTER TABLE transactions
ADD COLUMN transaction_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- ================================================
-- Step 2: Data Cleaning
-- ================================================
-- Disable Safe Mode temporarily for cleaning
SET SQL_SAFE_UPDATES = 0;

-- Remove instances of cancellations
DELETE FROM transactions
WHERE invoice LIKE 'C%';
SELECT COUNT(*) FROM transactions; -- 515255

-- Remove rows with no customer ID
DELETE FROM transactions
WHERE customer_id IS NULL OR customer_id = '';
SELECT COUNT(*) FROM transactions; -- 407695

-- Remove bad prices and quantities
DELETE FROM transactions
WHERE unit_price <= 0 OR quantity <=0;
SELECT COUNT(*) FROM transactions; -- 407650

-- Find stock codes that don't look like real product codes
SELECT DISTINCT stock_code, description, COUNT(*) as row_count
FROM transactions
WHERE stock_code REGEXP '[^0-9]'
GROUP BY stock_code, description
ORDER BY row_count DESC;

SELECT DISTINCT stock_code, description, COUNT(*) as row_count
FROM transactions
WHERE stock_code IN ('POST', 'D', 'M', 'BANK CHARGES', 'PADS', 'C2', 'ADJUST', 'TEST001')
GROUP BY stock_code, description
ORDER BY row_count DESC;

DELETE FROM transactions
WHERE stock_code IN ('POST', 'D', 'M', 'BANK CHARGES', 'PADS', 'C2', 'ADJUST', 'TEST001');

SELECT COUNT(*) FROM transactions; -- 406301

-- Final check to confirm everything looks healthy
SELECT
	SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customers,
	SUM(CASE WHEN invoice_date IS NULL THEN 1 ELSE 0 END) AS null_dates,
	SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_prices
FROM transactions;

SELECT
	MIN(invoice_date) AS earliest_date,
    MAX(invoice_date) AS latest_date,
    ROUND(MIN(unit_price), 2) AS min_price,
    ROUND(MAX(unit_price), 2) AS max_price,
    MIN(quantity) as min_qty,
    MAX(quantity) as max_qty
FROM transactions;

-- Enable safe updates now that cleaning is done
SET SQL_SAFE_UPDATES = 1;

-- ================================================
-- Step 3: Analysis
-- ================================================

-- Monthly Revenue Trend
SELECT
	DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    ROUND(SUM(quantity * unit_price), 2) AS revenue,
    COUNT(DISTINCT invoice) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM transactions
GROUP BY month
ORDER BY month;

-- Top 10 Customers by Revenue
SELECT
    customer_id,
    ROUND(SUM(quantity * unit_price), 2) AS total_spent,
    COUNT(DISTINCT invoice) AS total_orders,
    ROUND(SUM(quantity * unit_price) / COUNT(DISTINCT invoice), 2) AS avg_order_value
FROM transactions
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- Cohort Analysis
WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(invoice_date), '%Y-%m') AS cohort_month
    FROM transactions
    GROUP BY customer_id
),
customer_activity AS (
    SELECT
        t.customer_id,
        fp.cohort_month,
        DATE_FORMAT(t.invoice_date, '%Y-%m') AS activity_month
    FROM transactions t
    JOIN first_purchase fp ON t.customer_id = fp.customer_id
)
SELECT
    cohort_month,
    activity_month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM customer_activity
GROUP BY cohort_month, activity_month
ORDER BY cohort_month, activity_month;