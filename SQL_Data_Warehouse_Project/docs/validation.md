# Verification Results

## Tested Environment

The publication snapshot was validated on October 17, 2026 using SQL Server Express 2025, engine version `17.0.1000.7`, with Windows integrated authentication and sqlcmd. SQL Server 2017+ remains the documented minimum based on the SQL features used; this run does not establish a tested compatibility matrix across older versions or operating systems.

Validation used a newly created, isolated database. Only the database name and the server-accessible dataset root were substituted in temporary execution copies. No existing warehouse was reset. Repository CSV field values were retained; missing final line terminators were added to prevent omitted final records during bulk ingestion.

## Execution Coverage

| Check | Result |
|---|---|
| Database/schema setup from an absent database | PASS |
| All six CSV files loaded; Bronze counts reconciled with parsed source records | PASS |
| Silver transformations and Gold view creation | PASS |
| Detailed inspection scripts 06, 08, 11, and 12 execute | PASS; source diagnostics can return expected issue rows |
| Scorecard and all four sales report result sets execute | PASS |
| Focused calendar, range-boundary, repeat-buyer, and average-order-value fixtures | PASS |
| Warehouse key, date-ordering, amount, row-count, and revenue assertions | PASS |
| Second full refresh preserves sales row count and revenue | PASS |
| Gold definitions deployed repeatedly | PASS |
| Missing source file propagates an error and prevents dependent Silver execution | PASS; failure injection was rolled back |

## Reconciled Counts

| Object | Records |
|---|---:|
| bronze.crm_cust_info | 18,494 |
| bronze.crm_prd_info | 397 |
| bronze.crm_sales_details | 60,398 |
| bronze.erp_cust_az12 | 18,484 |
| bronze.erp_loc_a101 | 18,484 |
| bronze.erp_px_cat_g1v2 | 37 |
| silver.crm_cust_info | 18,484 |
| silver.crm_prd_info | 397 |
| silver.crm_sales_details | 60,398 |
| gold.dim_customers | 18,484 |
| gold.dim_products | 295 |
| gold.fact_sales | 60,398 |

Customer reduction reflects null-ID exclusion and latest-record deduplication. The Gold product count reflects current-product filtering, rather than lost sales records.

## Data Quality Outcome

The final scorecard returned no FAIL results. Source and Silver date checks each reported **19 affected sales rows** for review. Dates must be valid calendar dates within the inclusive project window **1900-01-01 through 2050-01-01**. One source value has year 5489: it is syntactically a valid date but falls outside that historical-data policy. Invalid or out-of-range dates become null; the sales records and their measures remain available.

The Gold fact contains 19 rows without an order date, zero missing order numbers, and zero unresolved customer/product keys. Sales totals reconcile to **29,356,250 source monetary units**. See [analysis findings](analysis_findings.md) for the resulting reports.

## Reproducing the Checks

Follow the [initial setup sequence](../README.md#first-run), then the [test instructions](../tests/README.md). Compare Bronze counts with the [dataset inventory](../datasets/README.md), inspect script 13, and execute script 14. Repeating script 09 should preserve counts and totals for unchanged source files. Only inject file failures in a disposable database: full refresh is destructive and not globally atomic.

This verification establishes the supplied snapshot's execution path. It does not prove complete business correctness for arbitrary new files, performance at larger scale, concurrent-reader consistency during refresh, recovery from every partial failure, or production readiness. Credentials and file permissions remain environment-specific.
