-- ======================================================================================
-- Project 1: E-commerce Sales & Customer Behaviour
-- File: sql/rfm_segmentation.sql
-- Purpose: RFM Analysis - from raw data to segments
-- Database: ecommerce.db(SQLite)
-- ======================================================================================

-- ======================================================================================
-- Query 1: Data sanity check - get top customers by revenue
-- ======================================================================================

SELECT 
    customer_unique_id,
    customer_segment,
    clv_tier,
    order_count,
    ROUND(total_spend,2)            AS total_spend_brl,
    ROUND(average_order_value,2)    AS avg_order_value_brl,
    ROUND(avg_review, 2)            AS avg_review_score,
    is_churned
FROM
    dim_customers
ORDER BY 
    total_spend DESC
LIMIT 20;

-- ======================================================================================
-- Query 2: RFM scores from raw data
-- ======================================================================================

WITH customer_metrics AS (
    -- STEP 1: Compute R, F, M for each customer from raw orders
    SELECT
        o.customer_id,
        CAST(
            julianday(
                (SELECT MAX(order_purchase_timestamp) FROM raw_orders)
            ) 
            - julianday(MAX(o.order_purchase_timestamp))
        AS INTEGER)                                            AS recency_days,
        COUNT(DISTINCT(o.order_id))                            AS frequency,
        ROUND(SUM(p.payment_value), 2)                         AS monetary
    FROM  
        raw_orders o
    JOIN
        raw_order_payments p ON o.order_id = p.order_id
    JOIN
        raw_customers      c ON o.customer_id = c.customer_id    
    WHERE  
        o.order_status = "delivered"
    GROUP BY 
        o.customer_id
),

rfm_ntile AS (
    -- STEP 2: Compute percentile cutpoints for scoring
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_ntile,
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f_ntile,
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_ntile
    FROM   
        customer_metrics
),

rfm_scored AS (
    -- STEP 3: Score each customer 1-5 on R, F, M
    -- NOTE: Recency is reversed; fewer days = better score
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        r_ntile                 AS r_score,
        f_ntile                 AS f_score,
        m_ntile                 AS m_score,
        ROUND(
            r_ntile*0.4 + f_ntile*0.3 + m_ntile*0.3
        , 2)                    AS rfm_combined 

    FROM   
        rfm_ntile
)

-- STEP 4: Final output with segment labels
SELECT 
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_combined,
    CASE
        WHEN r_score>=4 AND f_score>=4 AND m_score>=4 THEN 'Champions'
        WHEN r_score>=3 and f_score>=3                THEN 'Loyal Customers'
        WHEN r_score>=4 and f_score<=2                THEN 'New Customers'
        WHEN r_score>=3 AND f_score<=2 AND m_score>=3 THEN 'Potential Loyalists'
        WHEN r_score=3  AND f_score=3                 THEN 'Needs Attention'
        WHEN r_score<=2 AND f_score>=3 AND m_score>=3 THEN 'At Risk'
        WHEN r_score<=2 AND f_score>=4                THEN 'Cannot Lose Them'
        WHEN r_score=1  AND f_score=1                 THEN 'Lost'
        ELSE 'Hibernating'
    END AS customer_segment
FROM
    rfm_scored
ORDER BY    
    rfm_combined DESC
LIMIT 20;

-- ======================================================================================
-- QUERY 3: Segment Summary
-- ======================================================================================

SELECT  
    customer_segment,
    COUNT(*)                                        AS customer_count,
    ROUND(
        100.0 * COUNT(*)/(SELECT COUNT(*) FROM dim_customers)
    , 3)                                            AS pct_of_total,
    ROUND(AVG(total_spend), 2)                      AS avg_lifetime_spend,
    ROUND(SUM(total_spend), 2)                      AS total_segment_revenue,
    ROUND(
        100.0 * SUM(total_spend)
        /(SELECT SUM(total_spend) FROM dim_customers), 2
    )                                               AS pct_total_revenue,
    ROUND(AVG(order_count), 2)                      AS avg_orders,
    ROUND(AVG(review_score), 2)                     AS avg_review_score,
    SUM(
        CASE WHEN is_churned = 1 THEN 1 ELSE 0 END
    )                                               AS churned_count,
    ROUND(
        100.0 * SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END)/
    COUNT(*), 2)                                    AS churned_rate_pct
FROM
    dim_customers
GROUP BY 
    customer_segment
ORDER BY
    avg_lifetime_spend DESC;
 
 -- =====================================================================================
 -- QUERY 4: Monthly revenue trends
 -- =====================================================================================

SELECT 
    year_month,
    total_orders,
    total_revenue,
    ROUND(SUM(total_revenue) 
        OVER (ORDER BY year_month
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
    , 2)                                            AS cumulatve_revenue,
    ROUND(
        100*0 * 
        (total_revenue - LAG(total_revenue,1) OVER (ORDER BY year_month)) /
        NULLIF(LAG(total_revenue,1) OVER (ORDER BY year_month), 0)
    , 2)                                            AS mom_growth_pct,
    ROUND(
        AVG(total_revenue) OVER(
            ORDER BY year_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
    , 2)                                            AS rolling_3m_avg,
    avg_order_value,
    avg_review_score,
    late_rate_pct
FROM
    vw_monthly_revenue
ORDER BY
    year_month;

-- ======================================================================================
-- QUERY 5: Custmer order histroy with running spend
-- Filtered segment to 'Champions' for output management.

-- Explore other customer segment data by changing customer segment to any of 
-- the following:
-- 1. Loyal Customers
-- 2. New Customers
-- 3. Potential Loyalists
-- 4. Needs Attention
-- 5. At Risk
-- 6. Cannot Lose Them
-- 7. Lost
-- 8. Hibernating
-- ======================================================================================

SELECT
    fo.customer_unique_id,
    dc.customer_segment,
    fo.order_id,
    DATE(fo.order_purchase_timestamp)               AS order_date,
    ROUND(fo.total_revenue, 2)                      AS order_revenue,
    fo.category_en,
    fo.review_score,
    fo.is_late                                       
FROM
    fact_orders fo
JOIN
    dim_customers dc ON fo.customer_unique_id = dc.customer_unique_id
WHERE
    dc.customer_segment = 'Champions'
ORDER BY
    fo.customer_unique_id, fo.order_purchase_timestamp
LIMIT 50;

-- ======================================================================================
-- QUERY 6: Ranked category deep-dive

-- Each category has the following ranking:
-- 1. revenue (1 = highest revenue)
-- 2. review score (1 = best reviewed)
-- 3. late rate (1 = most reliable)
-- ======================================================================================

SELECT 
    category_en,
    total_orders
    total_revenue,
    avg_order_value,
    avg_review_score,
    avg_freight,
    late_rate_pct,

    RANK() OVER (ORDER BY total_revenue DESC)           AS revenue_rank,
    RANK() OVER (ORDER BY avg_review_score DESC)        AS review_rank,
    RANK() OVER (ORDER BY late_rate_pct ASC)            AS reliability_rank
FROM
    vw_category_performance
WHERE 
    total_orders > 100
ORDER BY 
    revenue_rank
LIMIT 50;

-- ======================================================================================
-- QUERY 7: Pull high value customers (Premium and High CLV tiers) for churn win-back
-- ======================================================================================

SELECT
    dc.customer_segment,
    dc.clv_tier,
    dc.total_spend                                  AS lifetime_spend,
    dc.customer_state,
    dc.order_count,
    dc.days_since_last_order,
    dc.avg_review,  
    last_order.category_en                          AS last_category_purchased,
    CASE
        WHEN dc.days_since_last_order BETWEEN 90  AND 100 THEN 'Medium Risk'
        WHEN dc.days_since_last_order BETWEEN 181 AND 365 THEN 'High Risk'
        WHEN dc.days_since_last_order > 365               THEN 'Critical Risk'
    END                                             AS churn_risk_level
FROM 
    dim_customers dc
LEFT JOIN (
    SELECT 
        customer_unique_id,
        category_en,
        ROW_NUMBER() OVER (PARTITION BY customer_unique_id  
        ORDER BY order_purchase_timestamp DESC)         AS rn
    FROM
        fact_orders
) last_order
    ON dc.customer_unique_id = last_order.customer_unique_id
    AND last_order.rn = 1
WHERE
    dc.is_churned = 1 AND 
    dc.clv_tier IN ('Premium', 'High')
ORDER BY
    dc.total_spend DESC
LIMIT 30;

-- ======================================================================================
-- QUERY 8: Credit card usage and installment behaviour by state
-- ======================================================================================

SELECT  
    fo.customer_state,
    COUNT(*)                                        AS credit_card_transactions,
    ROUND(AVG(rp.payment_installments), 2)          AS avg_installments,
    ROUND(AVG(rp.payment_value), 2)                 AS avg_payment_value,
    ROUND(AVG(rp.payment_value), 2)                 AS total_revenue
FROM
    raw_order_payments rp
JOIN
    fact_orders        fo ON rp.order_id = fo.order_id
WHERE
    rp.payment_type = 'credit_card'
GROUP BY
    fo.customer_state
ORDER BY
    total_revenue DESC
LIMIT 20;

-- ======================================================================================
-- QUERY 9: Seller performance scorecard
-- ======================================================================================

SELECT
    oi.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)                     AS total_orders,
    ROUND(SUM(oi.price), 2)                         AS total_price,
    ROUND(AVG(oi.price), 2)                         AS avg_price,
    ROUND(AVG(r.review_score), 2)                   AS avg_review_score,
    ROUND(
        100.0 *
        SUM(CASE WHEN fo.is_late = 1 THEN 1 ELSE 0 END) /
        COUNT(DISTINCT oi.order_id), 2)             AS late_delivery_pct,
    CASE
        WHEN AVG(r.review_score) >= 4.5
            AND(100.0 *
                SUM (CASE WHEN fo.is_late = 1 THEN 1 ELSE 0 END)/
                COUNT(DISTINCT oi.order_id)) < 5    THEN 'Top Performer'
        WHEN AVG(r.review_score) >= 4.0             THEN 'Good'
        WHEN AVG(r.review_score) >= 3.0             THEN 'Average'
        ELSE                                             'Needs Improvement'
    END                                             AS performance_tier
FROM raw_order_items     oi
JOIN raw_sellers         s  ON oi.seller_id = s.seller_id
JOIN raw_order_reviews   r  ON oi.order_id  = r.order_id
JOIN fact_orders         fo ON oi.order_id  = fo.order_id
GROUP BY 
    oi.seller_id, s.seller_state
HAVING 
    total_orders >= 20
ORDER BY
    avg_review_score DESC
LIMIT 50;
