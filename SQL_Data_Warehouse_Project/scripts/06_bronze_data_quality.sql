/* Detailed source diagnostics. Read-only; source defects are expected here.
   Each query reports a named concern. No Silver tables are required. */
USE DataWarehouse;
GO
SET NOCOUNT ON;

-- Customer candidate keys and text/code profiles.
SELECT cst_id, COUNT_BIG(*) AS source_rows
FROM bronze.crm_cust_info
GROUP BY cst_id HAVING cst_id IS NULL OR COUNT_BIG(*) > 1;

SELECT cst_id, cst_firstname, cst_lastname
FROM bronze.crm_cust_info
WHERE DATALENGTH(cst_firstname) <> DATALENGTH(TRIM(cst_firstname))
   OR DATALENGTH(cst_lastname) <> DATALENGTH(TRIM(cst_lastname));
SELECT cst_gndr, COUNT_BIG(*) AS source_rows FROM bronze.crm_cust_info GROUP BY cst_gndr;
SELECT cst_marital_status, COUNT_BIG(*) AS source_rows
FROM bronze.crm_cust_info GROUP BY cst_marital_status;

-- Product history and costs; later Silver derives end dates from the next start.
SELECT prd_id, COUNT_BIG(*) AS source_rows FROM bronze.crm_prd_info
GROUP BY prd_id HAVING prd_id IS NULL OR COUNT_BIG(*) > 1;
SELECT prd_id, prd_nm, prd_cost FROM bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0
   OR DATALENGTH(prd_nm) <> DATALENGTH(TRIM(prd_nm));
SELECT prd_id, prd_key, prd_start_dt, prd_end_dt FROM bronze.crm_prd_info
WHERE prd_start_dt IS NULL OR prd_end_dt < prd_start_dt;
SELECT prd_line, COUNT_BIG(*) AS source_rows FROM bronze.crm_prd_info GROUP BY prd_line;

-- Check sales references against source-domain keys, not a previously loaded Silver layer.
SELECT s.sls_ord_num, s.sls_prd_key FROM bronze.crm_sales_details s
WHERE NOT EXISTS (SELECT 1 FROM bronze.crm_prd_info p
                  WHERE SUBSTRING(p.prd_key, 7, LEN(p.prd_key)) = s.sls_prd_key);
SELECT s.sls_ord_num, s.sls_cust_id FROM bronze.crm_sales_details s
WHERE NOT EXISTS (SELECT 1 FROM bronze.crm_cust_info c WHERE c.cst_id = s.sls_cust_id);

-- Parse actual calendar dates; length alone cannot validate a date.
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt
FROM bronze.crm_sales_details
WHERE TRY_CONVERT(date, CONVERT(varchar(10), sls_order_dt), 112) IS NULL
   OR TRY_CONVERT(date, CONVERT(varchar(10), sls_ship_dt), 112) IS NULL
   OR TRY_CONVERT(date, CONVERT(varchar(10), sls_due_dt), 112) IS NULL
       OR sls_order_dt NOT BETWEEN 19000101 AND 20500101
       OR sls_ship_dt NOT BETWEEN 19000101 AND 20500101
       OR sls_due_dt NOT BETWEEN 19000101 AND 20500101;

SELECT sls_ord_num, sls_sales, sls_quantity, sls_price
FROM bronze.crm_sales_details
WHERE sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
   OR CONVERT(bigint, sls_sales) <> CONVERT(bigint, sls_quantity) * sls_price;

-- ERP source profiles and normalized-key compatibility.
SELECT e.cid FROM bronze.erp_cust_az12 e
WHERE NOT EXISTS (SELECT 1 FROM bronze.crm_cust_info c
                  WHERE c.cst_key = CASE WHEN e.cid LIKE 'NAS%'
                        THEN SUBSTRING(e.cid, 4, LEN(e.cid)) ELSE e.cid END);
SELECT cid, bdate FROM bronze.erp_cust_az12 WHERE bdate > CONVERT(date, GETDATE());
SELECT gen, COUNT_BIG(*) AS source_rows FROM bronze.erp_cust_az12 GROUP BY gen;
SELECT e.cid FROM bronze.erp_loc_a101 e
WHERE NOT EXISTS (SELECT 1 FROM bronze.crm_cust_info c WHERE c.cst_key = REPLACE(e.cid, '-', ''));
SELECT cntry, COUNT_BIG(*) AS source_rows FROM bronze.erp_loc_a101 GROUP BY cntry;
SELECT id, cat, subcat, maintenance FROM bronze.erp_px_cat_g1v2
WHERE DATALENGTH(cat) <> DATALENGTH(TRIM(cat))
   OR DATALENGTH(subcat) <> DATALENGTH(TRIM(subcat))
   OR DATALENGTH(maintenance) <> DATALENGTH(TRIM(maintenance));
