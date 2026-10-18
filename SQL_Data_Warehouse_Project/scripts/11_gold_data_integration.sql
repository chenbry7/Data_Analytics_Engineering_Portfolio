/*
=============================================================
Gold Layer Data Integration Check
=============================================================
Script Purpose:
    This script checks gender integration logic between CRM customer data and ERP
    customer data. It compares gender values from both sources and applies the
    business rule that CRM is the master source when available, while ERP gender
    is used as a fallback.

WARNING:
    This script is read-only and is used to validate data integration logic before
    applying it to gold layer views. It does not modify data. Review the output to
    ensure that the selected business rule produces consistent and reliable results.
*/

USE DataWarehouse;
GO


SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender info
		 ELSE COALESCE(ca.gen,'n/a') -- 1 way to handle NULL value
	END AS new_gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON        ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON		  ci.cst_key = la.cid
ORDER BY 1,2
