/*
=============================================================
Gold Layer Data Quality Checks
=============================================================
Script Purpose:
    This script performs data quality checks on the gold layer views. It reviews
    the customer and product dimension views and checks foreign key integrity
    between the sales fact view and the related dimension views.

WARNING:
    This script is read-only and does not modify data. If any records are returned
    from the foreign key integrity checks, it may indicate missing or unmatched
    dimension records that should be investigated before reporting or dashboarding.
*/

USE DataWarehouse;
GO


SELECT *
FROM gold.dim_customers


SELECT *
FROM gold.dim_products


-- Foreign Key Integrity (Dimensions)
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
WHERE c.customer_key IS NULL

SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL
