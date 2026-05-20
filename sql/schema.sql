-- ======================================================================================
-- Project 1: E-commerce Sales & Customer Behaviour
-- File: sql/schema.sql
-- Purpose: Create views and indexes for RFM Segmentation
-- Database: ecommerce.db(SQLite)
-- ======================================================================================

-- ======================================================================================
-- STEP 1: Sanity check - verify tables
-- ======================================================================================

SELECT
    name AS table_name,
    type AS object_type
FROM   
    sqlite_master
WHERE 
    type = "table"
ORDER BY   
    name ASC;

-- ======================================================================================
-- STEP 2: Display row counts for each table
-- ======================================================================================

SELECT 'raw_orders'         AS table_name, COUNT(*) AS row_count FROM raw_orders
UNION ALL
SELECT 'raw_order_items',                  COUNT(*)              FROM raw_order_items
UNION ALL
SELECT 'raw_order_payments',               COUNT(*)              FROM raw_order_payments
UNION ALL
SELECT 'raw_order_reviews',                COUNT(*)              FROM raw_order_reviews
UNION ALL
SELECT 'raw_customers',                    COUNT(*)              FROM raw_customers
UNION ALL
SELECT 'raw_products',                     COUNT(*)              FROM raw_products
UNION ALL
SELECT 'raw_sellers',                      COUNT(*)              FROM raw_sellers
UNION ALL
SELECT 'fact_orders',                      COUNT(*)              FROM fact_orders
UNION ALL
SELECT 'dim_customers',                    COUNT(*)              FROM dim_customers
UNION ALL
SELECT 'rfm_scores',                       COUNT(*)              FROM rfm_scores;   

-- ======================================================================================
-- STEP 3: Create indexes for faster seacrhes
-- ======================================================================================

CREATE INDEX IF NOT EXISTS idx_fact_orders_customer
    ON fact_orders(customer_unique_id);

CREATE INDEX IF NOT EXISTS idx_fact_orders_date
    ON fact_orders(order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_fact_orders_state
    ON fact_orders(customer_state);

CREATE INDEX IF NOT EXISTS idx_fact_orders_category
    ON fact_orders(category_en);

CREATE INDEX IF NOT EXISTS idx_fact_orders_payment
    ON fact_orders(payment_type);

CREATE INDEX IF NOT EXISTS idx_dim_customers_segment
    ON dim_customers(customer_segment);

CREATE INDEX IF NOT EXISTS idx_dim_customers_csv
    ON dim_customers(clv_tier);

CREATE INDEX IF NOT EXISTS idx_raw_orders_customer
    ON raw_orders(customer_unique_id);

CREATE INDEX IF NOT EXISTS idx_raw_items_order
    ON raw_order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_raw_items_product
    ON raw_order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_raw_payments_order
    ON raw_order_payments(order_id);

CREATE INDEX IF NOT EXISTS idx_raw_reviews_order
    ON raw_order_reviews(order_id);

-- ======================================================================================
-- STEP 4: Create Views for memory efficiency
-- ======================================================================================

-- View 1: Monthly revenue + KPIs

DROP VIEW IF EXISTS vw_monthly_revenue;

CREATE VIEW vw_monthly_revenue AS 
SELECT
    strftime('%Y', order_purchase_timestamp)        AS year,
    strftime('%m', order_purchase_timestamp)        AS month,
    strftime('%Y-%m', order_purchase_timestamp)     AS year_month,
    COUNT(order_id)                                 AS total_orders,
    ROUND(SUM(total_revenue), 2)                    AS total_revenue,
    ROUND(AVG(total_revenue), 2)                    AS avg_order_value,
    ROUND(AVG(review_score), 2)                     AS avg_review_score,
    SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)    AS late_orders,
    ROUND(
        100.0 * 
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        /COUNT(*), 2)                               AS late_rate_pct
FROM 
    fact_orders
GROUP BY
    year, month
ORDER BY
    year, month;

-- View 2: Performance by state

DROP VIEW IF EXISTS vw_state_performance;

CREATE VIEW vw_state_performance AS
SELECT
    customer_state,
    COUNT(order_id)                                 AS total_orders,
    COUNT(DISTINCT(customer_unique_id))             AS unique_customers,
    ROUND(SUM(total_revenue), 2)                    AS total_revenue,
    ROUND(AVG(total_revenue), 2)                    AS avg_order_value,
    ROUND(AVG(review_score), 2)                     AS avg_review_score,
    SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)    AS late_orders,
    ROUND(
        100.0 *
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)/
        COUNT(*), 2)                                AS late_rate_pct
FROM    
    fact_orders
GROUP BY
    customer_state
ORDER BY
    total_revenue DESC;


-- View 3: Performance by product category

DROP VIEW IF EXISTS vw_category_performance;

CREATE VIEW vw_category_performance AS
SELECT 
    category_en,
    COUNT(order_id)                                 AS total_orders,
    ROUND(SUM(total_revenue), 2)                    AS total_revenue,
    ROUND(AVG(total_revenue), 2)                    AS avg_order_value,
    ROUND(AVG(review_score),  2)                    AS avg_review_score,
    ROUND(AVG(freight_value), 2)                    AS avg_freight,
    SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)    AS late_orders,
    ROUND(
        100.0 *
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)/
        COUNT(*), 2)                                AS late_rate_pct
FROM
    fact_orders
WHERE 
    category_en IS NOT NULL
GROUP BY
    category_en
ORDER BY    
    total_revenue DESC;

-- View 4: Custoer health by segment and CLV tier

DROP VIEW IF EXISTS vw_customer_health;

CREATE VIEW vw_customer_health AS
SELECT
    customer_segment,
    clv_tier,
    COUNT(*)                                        AS customer_count,
    ROUND(AVG(total_spend), 2)                      AS avg_lifetime_spend,
    ROUND(AVG(order_count),2)                       AS avg_orders,
    ROUND(AVG(review_score), 2)                     AS avg_review_score,
    SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END) AS churned_count,
    ROUND(
        100.0 * 
        SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END)/
        COUNT(*), 2)                                AS churn_rate_pct
FROM
    dim_customers
GROUP BY
    customer_segment, clv_tier
ORDER BY
    avg_lifetime_spend DESC;

-- ======================================================================================
-- STEP 5: Confirm that views have been created correctly
-- ======================================================================================

SELECT
    name AS view_name
FROM
    sqlite_master
WHERE
    TYPE = 'view'
ORDER BY    
    view_name;

-- ======================================================================================
-- STEP 6: Print data from all values
-- ======================================================================================

SELECT * FROM vw_category_performance LIMIT 10;
SELECT * FROM vw_customer_health LIMIT 10;
SELECT * FROM vw_monthly_revenue LIMIT 10;
SELECT * FROM vw_state_performance LIMIT 10;
