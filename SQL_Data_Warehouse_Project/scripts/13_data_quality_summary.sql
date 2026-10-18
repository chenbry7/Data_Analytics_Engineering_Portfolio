/*
Data quality scorecard | Independent project extension
Run after scripts 09 and 10 in a populated warehouse. Read-only.
issue_count counts affected rows, except rules explicitly labeled as groups.
REVIEW denotes source issues or incomplete dates; FAIL denotes model defects.
This is a diagnostic report, not an automated publication gate.
*/
USE DataWarehouse;
GO
SET NOCOUNT ON;

;WITH checks AS (
    SELECT 'Source' AS data_layer,
           'Invalid, missing, or out-of-range source sales dates' AS check_name,
           'REVIEW' AS issue_status, COUNT_BIG(*) AS issue_count
    FROM bronze.crm_sales_details
    WHERE TRY_CONVERT(date, CONVERT(varchar(10), sls_order_dt), 112) IS NULL
       OR TRY_CONVERT(date, CONVERT(varchar(10), sls_ship_dt), 112) IS NULL
       OR TRY_CONVERT(date, CONVERT(varchar(10), sls_due_dt), 112) IS NULL
       OR sls_order_dt NOT BETWEEN 19000101 AND 20500101
       OR sls_ship_dt NOT BETWEEN 19000101 AND 20500101
       OR sls_due_dt NOT BETWEEN 19000101 AND 20500101
    UNION ALL
    SELECT 'Silver', 'Duplicate customer ID groups', 'FAIL', COUNT_BIG(*)
    FROM (SELECT cst_id FROM silver.crm_cust_info
          WHERE cst_id IS NOT NULL GROUP BY cst_id HAVING COUNT_BIG(*) > 1) d
    UNION ALL
    SELECT 'Silver', 'Missing customer IDs', 'FAIL', COUNT_BIG(*)
    FROM silver.crm_cust_info WHERE cst_id IS NULL
    UNION ALL
    SELECT 'Silver', 'Sales rows with incomplete dates', 'REVIEW', COUNT_BIG(*)
    FROM silver.crm_sales_details
    WHERE sls_order_dt IS NULL OR sls_ship_dt IS NULL OR sls_due_dt IS NULL
    UNION ALL
    SELECT 'Silver', 'Sales rows with invalid date sequence', 'FAIL', COUNT_BIG(*)
    FROM silver.crm_sales_details
    WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt
    UNION ALL
    SELECT 'Silver', 'Sales rows with invalid or inconsistent amounts', 'FAIL', COUNT_BIG(*)
    FROM silver.crm_sales_details
    WHERE sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
       OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
       OR CONVERT(bigint, sls_sales) <> CONVERT(bigint, sls_quantity) * sls_price
    UNION ALL
    SELECT 'Gold', 'Duplicate customer business-key groups', 'FAIL', COUNT_BIG(*)
    FROM (SELECT customer_id FROM gold.dim_customers
          GROUP BY customer_id HAVING COUNT_BIG(*) > 1) d
    UNION ALL
    SELECT 'Gold', 'Duplicate product business-key groups', 'FAIL', COUNT_BIG(*)
    FROM (SELECT product_number FROM gold.dim_products
          GROUP BY product_number HAVING COUNT_BIG(*) > 1) d
    UNION ALL
    SELECT 'Gold', 'Sales source rows without a current product', 'FAIL', COUNT_BIG(*)
    FROM silver.crm_sales_details s
    WHERE NOT EXISTS (SELECT 1 FROM gold.dim_products p
                      WHERE p.product_number = s.sls_prd_key)
    UNION ALL
    SELECT 'Gold', 'Sales source rows without a customer', 'FAIL', COUNT_BIG(*)
    FROM silver.crm_sales_details s
    WHERE NOT EXISTS (SELECT 1 FROM gold.dim_customers c
                      WHERE c.customer_id = s.sls_cust_id)
    UNION ALL
    SELECT 'Gold', 'Fact rows with unresolved dimension keys', 'FAIL', COUNT_BIG(*)
    FROM gold.fact_sales WHERE product_key IS NULL OR customer_key IS NULL
    UNION ALL
    SELECT 'Gold', 'Absolute fact versus source row-count difference', 'FAIL',
           ABS((SELECT COUNT_BIG(*) FROM gold.fact_sales)
             - (SELECT COUNT_BIG(*) FROM silver.crm_sales_details))
    UNION ALL
    SELECT 'Source', 'Empty sales input (one issue if empty)', 'FAIL',
           CONVERT(bigint, CASE WHEN EXISTS (SELECT 1 FROM bronze.crm_sales_details) THEN 0 ELSE 1 END)
)
SELECT data_layer, check_name, issue_count,
       CASE WHEN issue_count = 0 THEN 'PASS' ELSE issue_status END AS status
FROM checks
ORDER BY CASE WHEN issue_count > 0 AND issue_status = 'FAIL' THEN 0
              WHEN issue_count > 0 THEN 1 ELSE 2 END,
         data_layer, check_name;
