/* Detailed cleaned-data diagnostics. Read-only; review returned issue rows.
   These checks inspect Silver only. Script 13 provides the consolidated scorecard. */
USE DataWarehouse;
GO
SET NOCOUNT ON;

SELECT cst_id, COUNT_BIG(*) AS silver_rows FROM silver.crm_cust_info
GROUP BY cst_id HAVING cst_id IS NULL OR COUNT_BIG(*) > 1;
SELECT cst_id, cst_firstname, cst_lastname FROM silver.crm_cust_info
WHERE DATALENGTH(cst_firstname) <> DATALENGTH(TRIM(cst_firstname))
   OR DATALENGTH(cst_lastname) <> DATALENGTH(TRIM(cst_lastname));
SELECT cst_gndr, COUNT_BIG(*) AS silver_rows FROM silver.crm_cust_info GROUP BY cst_gndr;
SELECT cst_marital_status, COUNT_BIG(*) AS silver_rows
FROM silver.crm_cust_info GROUP BY cst_marital_status;

SELECT prd_id, COUNT_BIG(*) AS silver_rows FROM silver.crm_prd_info
GROUP BY prd_id HAVING prd_id IS NULL OR COUNT_BIG(*) > 1;
SELECT prd_id, prd_key, prd_cost, prd_start_dt, prd_end_dt FROM silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0 OR prd_start_dt IS NULL OR prd_end_dt < prd_start_dt;
SELECT prd_line, COUNT_BIG(*) AS silver_rows FROM silver.crm_prd_info GROUP BY prd_line;

SELECT s.sls_ord_num, s.sls_prd_key FROM silver.crm_sales_details s
WHERE NOT EXISTS (SELECT 1 FROM silver.crm_prd_info p WHERE p.prd_key = s.sls_prd_key);
SELECT s.sls_ord_num, s.sls_cust_id FROM silver.crm_sales_details s
WHERE NOT EXISTS (SELECT 1 FROM silver.crm_cust_info c WHERE c.cst_id = s.sls_cust_id);
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL OR sls_ship_dt IS NULL OR sls_due_dt IS NULL
   OR sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;
SELECT sls_ord_num, sls_sales, sls_quantity, sls_price FROM silver.crm_sales_details
WHERE sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
   OR CONVERT(bigint, sls_sales) <> CONVERT(bigint, sls_quantity) * sls_price;

-- ERP checks inspect normalized Silver identifiers and cleaned attributes.
SELECT e.cid FROM silver.erp_cust_az12 e
WHERE NOT EXISTS (SELECT 1 FROM silver.crm_cust_info c WHERE c.cst_key = e.cid);
SELECT cid, bdate FROM silver.erp_cust_az12 WHERE bdate > CONVERT(date, GETDATE());
SELECT gen, COUNT_BIG(*) AS silver_rows FROM silver.erp_cust_az12 GROUP BY gen;
SELECT e.cid FROM silver.erp_loc_a101 e
WHERE NOT EXISTS (SELECT 1 FROM silver.crm_cust_info c WHERE c.cst_key = e.cid);
SELECT cntry, COUNT_BIG(*) AS silver_rows FROM silver.erp_loc_a101 GROUP BY cntry;
SELECT id, cat, subcat, maintenance FROM silver.erp_px_cat_g1v2
WHERE DATALENGTH(cat) <> DATALENGTH(TRIM(cat))
   OR DATALENGTH(subcat) <> DATALENGTH(TRIM(subcat))
   OR DATALENGTH(maintenance) <> DATALENGTH(TRIM(maintenance));
