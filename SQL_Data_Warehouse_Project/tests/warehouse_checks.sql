/* Read-only assertions for a populated warehouse. Run after scripts 09 and 10.
   Unlike the scorecard, these checks raise an error on structural/amount failures.
   Missing source dates are documented review items and do not fail this test. */
USE DataWarehouse;
GO
SET NOCOUNT ON;

-- Materialize once to avoid repeatedly expanding the nested analytical views.
SELECT * INTO #validation_sales FROM gold.fact_sales;

IF NOT EXISTS (SELECT 1 FROM bronze.crm_sales_details)
    THROW 51100, 'Sales input is empty.', 1;
IF EXISTS (SELECT cst_id FROM silver.crm_cust_info GROUP BY cst_id
           HAVING cst_id IS NULL OR COUNT_BIG(*) > 1)
    THROW 51101, 'Silver customer keys are missing or duplicated.', 1;
IF EXISTS (SELECT customer_id FROM gold.dim_customers GROUP BY customer_id
           HAVING customer_id IS NULL OR COUNT_BIG(*) > 1)
    THROW 51102, 'Gold customer business keys are missing or duplicated.', 1;
IF EXISTS (SELECT product_number FROM gold.dim_products GROUP BY product_number
           HAVING product_number IS NULL OR COUNT_BIG(*) > 1)
    THROW 51103, 'Gold product business keys are missing or duplicated.', 1;
IF EXISTS (SELECT 1 FROM #validation_sales WHERE customer_key IS NULL OR product_key IS NULL)
    THROW 51104, 'Fact records contain unresolved dimension keys.', 1;
IF (SELECT COUNT_BIG(*) FROM #validation_sales) <> (SELECT COUNT_BIG(*) FROM silver.crm_sales_details)
    THROW 51105, 'Gold joins changed the sales row count.', 1;
IF (SELECT COUNT_BIG(*) FROM bronze.crm_sales_details) <> (SELECT COUNT_BIG(*) FROM silver.crm_sales_details)
    THROW 51106, 'Sales records were lost or added during Silver loading.', 1;
IF EXISTS (SELECT 1 FROM silver.crm_sales_details
           WHERE sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
              OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
              OR CONVERT(bigint, sls_sales) <> CONVERT(bigint, sls_quantity) * sls_price)
    THROW 51107, 'Sales amounts are missing, nonpositive, or inconsistent.', 1;
IF EXISTS (SELECT 1 FROM silver.crm_sales_details
           WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt)
    THROW 51108, 'Sales dates are out of sequence.', 1;
IF (SELECT SUM(CONVERT(bigint,sales_amount)) FROM #validation_sales)
    <> (SELECT SUM(CONVERT(bigint,sls_sales)) FROM silver.crm_sales_details)
    THROW 51109, 'Gold sales total does not reconcile to Silver.', 1;
PRINT 'PASS: warehouse key integrity, row counts, amount consistency, date ordering, and revenue reconciliation.';

DROP TABLE #validation_sales;
