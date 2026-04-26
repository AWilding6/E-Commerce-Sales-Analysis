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

-- Revenue by Country
SELECT
    country,
    ROUND(SUM(quantity * unit_price), 2) AS revenue,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT invoice) AS total_orders
FROM transactions
GROUP BY country
ORDER BY revenue DESC;