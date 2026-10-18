/*
Sales analysis | Independent project extension
Run script 13 first. Resolve FAIL results before interpreting these reports.
Read-only; requires populated Gold views. Currency is unspecified.
Revenue means stored sales_amount, not profit. No missing months are fabricated.
*/
USE DataWarehouse;
GO
SET NOCOUNT ON;

-- 1. Monthly sales: How does revenue change across observed months?
-- Rows without order dates cannot be assigned a month and are excluded.
-- LAG compares the previous observed month, which may not be the previous calendar month.
;WITH monthly_sales AS (
    SELECT DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS sales_month,
           SUM(CONVERT(bigint, sales_amount)) AS revenue,
           SUM(CONVERT(bigint, quantity)) AS units_sold,
           COUNT(DISTINCT order_number) AS order_count
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
), comparisons AS (
    SELECT *, LAG(sales_month) OVER (ORDER BY sales_month) AS previous_observed_month,
              LAG(revenue) OVER (ORDER BY sales_month) AS previous_observed_revenue
    FROM monthly_sales
)
SELECT sales_month, revenue, units_sold, order_count,
       CAST(1.0 * revenue / NULLIF(order_count, 0) AS decimal(18,2)) AS average_order_value,
       previous_observed_month,
       CAST(100.0 * (revenue - previous_observed_revenue)
            / NULLIF(previous_observed_revenue, 0) AS decimal(18,2)) AS change_vs_previous_observed_pct
FROM comparisons
ORDER BY sales_month;

-- 2. Category contribution: Which current product categories generate revenue?
-- LEFT JOIN retains unmatched products under an explicit label.
-- Historical sales use current category assignments, matching the Gold model.
;WITH category_sales AS (
    SELECT COALESCE(p.category, 'Unknown / unclassified') AS category,
           SUM(CONVERT(bigint, f.sales_amount)) AS revenue,
           SUM(CONVERT(bigint, f.quantity)) AS units_sold,
           COUNT(DISTINCT f.order_number) AS order_count
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
    GROUP BY COALESCE(p.category, 'Unknown / unclassified')
)
SELECT DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
       category, revenue, units_sold, order_count,
       CAST(100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0) AS decimal(18,2)) AS revenue_share_pct,
       CAST(1.0 * revenue / NULLIF(units_sold, 0) AS decimal(18,2)) AS weighted_unit_price
FROM category_sales
ORDER BY revenue_rank, category;

-- 3. Customer repeat purchasing: How many observed buyers placed multiple orders?
-- Count distinct orders, not sales rows. Only resolved customers with an order number qualify.
-- This describes the supplied observation period, not lifetime retention or a cohort rate.
;WITH customer_orders AS (
    SELECT customer_key, COUNT(DISTINCT order_number) AS order_count
    FROM gold.fact_sales
    WHERE customer_key IS NOT NULL AND order_number IS NOT NULL
    GROUP BY customer_key
)
SELECT COUNT_BIG(*) AS observed_buyers,
       COALESCE(SUM(CONVERT(bigint, CASE WHEN order_count >= 2 THEN 1 ELSE 0 END)), 0) AS repeat_buyers,
       CAST(100.0 * SUM(CONVERT(bigint, CASE WHEN order_count >= 2 THEN 1 ELSE 0 END))
            / NULLIF(COUNT_BIG(*), 0) AS decimal(18,2)) AS repeat_buyer_pct
FROM customer_orders;

-- 4. Coverage: disclose exclusions rather than silently dropping incomplete records.
SELECT COUNT_BIG(*) AS fact_rows,
       COUNT_BIG(*) - COUNT_BIG(order_date) AS rows_without_order_date,
       COUNT_BIG(*) - COUNT_BIG(order_number) AS rows_without_order_number,
       COUNT_BIG(*) - COUNT_BIG(customer_key) AS rows_without_customer_key,
       COUNT_BIG(*) - COUNT_BIG(product_key) AS rows_without_product_key
FROM gold.fact_sales;
