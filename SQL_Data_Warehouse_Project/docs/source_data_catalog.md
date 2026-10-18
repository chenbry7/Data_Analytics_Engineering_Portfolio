# Source and Silver Data Catalog

The definitions below follow the physical table creation scripts. All declared business columns are nullable because the DDL does not specify `NOT NULL`. No physical primary or foreign keys are defined. Object names are qualified with `bronze` or `silver`.

## Source File Headers

### `datasets/source_crm/cust_info.csv`

`cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date`

### `datasets/source_crm/prd_info.csv`

`prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt`

### `datasets/source_crm/sales_details.csv`

`sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price`

### `datasets/source_erp/CUST_AZ12.csv`

`CID, BDATE, GEN`

### `datasets/source_erp/LOC_A101.csv`

`CID, CNTRY`

### `datasets/source_erp/PX_CAT_G1V2.csv`

`ID, CAT, SUBCAT, MAINTENANCE`

## Bronze Tables

### `bronze.crm_cust_info`

| Column | SQL type | Default |
|---|---|---|
| `cst_id` | `INT` | — |
| `cst_key` | `NVARCHAR(50)` | — |
| `cst_firstname` | `NVARCHAR(50)` | — |
| `cst_lastname` | `NVARCHAR(50)` | — |
| `cst_marital_status` | `NVARCHAR(50)` | — |
| `cst_gndr` | `NVARCHAR(50)` | — |
| `cst_create_date` | `DATE` | — |

### `bronze.crm_prd_info`

| Column | SQL type | Default |
|---|---|---|
| `prd_id` | `INT` | — |
| `prd_key` | `NVARCHAR(50)` | — |
| `prd_nm` | `NVARCHAR(50)` | — |
| `prd_cost` | `INT` | — |
| `prd_line` | `NVARCHAR(50)` | — |
| `prd_start_dt` | `DATETIME` | — |
| `prd_end_dt` | `DATETIME` | — |

### `bronze.crm_sales_details`

| Column | SQL type | Default |
|---|---|---|
| `sls_ord_num` | `NVARCHAR(50)` | — |
| `sls_prd_key` | `NVARCHAR(50)` | — |
| `sls_cust_id` | `INT` | — |
| `sls_order_dt` | `INT` | — |
| `sls_ship_dt` | `INT` | — |
| `sls_due_dt` | `INT` | — |
| `sls_sales` | `INT` | — |
| `sls_quantity` | `INT` | — |
| `sls_price` | `INT` | — |

### `bronze.erp_cust_az12`

| Column | SQL type | Default |
|---|---|---|
| `cid` | `NVARCHAR(50)` | — |
| `bdate` | `DATE` | — |
| `gen` | `NVARCHAR(50)` | — |

### `bronze.erp_loc_a101`

| Column | SQL type | Default |
|---|---|---|
| `cid` | `NVARCHAR(50)` | — |
| `cntry` | `NVARCHAR(50)` | — |

### `bronze.erp_px_cat_g1v2`

| Column | SQL type | Default |
|---|---|---|
| `id` | `NVARCHAR(50)` | — |
| `cat` | `NVARCHAR(50)` | — |
| `subcat` | `NVARCHAR(50)` | — |
| `maintenance` | `NVARCHAR(50)` | — |

## Silver Tables

### `silver.crm_cust_info`

| Column | SQL type | Default |
|---|---|---|
| `cst_id` | `INT` | — |
| `cst_key` | `NVARCHAR(50)` | — |
| `cst_firstname` | `NVARCHAR(50)` | — |
| `cst_lastname` | `NVARCHAR(50)` | — |
| `cst_marital_status` | `NVARCHAR(50)` | — |
| `cst_gndr` | `NVARCHAR(50)` | — |
| `cst_create_date` | `DATE` | — |
| `dwh_create_date` | `DATETIME2` | `GETDATE()` |

### `silver.crm_prd_info`

| Column | SQL type | Default |
|---|---|---|
| `prd_id` | `INT` | — |
| `cat_id` | `NVARCHAR(50)` | — |
| `prd_key` | `NVARCHAR(50)` | — |
| `prd_nm` | `NVARCHAR(50)` | — |
| `prd_cost` | `INT` | — |
| `prd_line` | `NVARCHAR(50)` | — |
| `prd_start_dt` | `DATE` | — |
| `prd_end_dt` | `DATE` | — |
| `dwh_create_date` | `DATETIME2` | `GETDATE()` |

### `silver.crm_sales_details`

| Column | SQL type | Default |
|---|---|---|
| `sls_ord_num` | `NVARCHAR(50)` | — |
| `sls_prd_key` | `NVARCHAR(50)` | — |
| `sls_cust_id` | `INT` | — |
| `sls_order_dt` | `DATE` | — |
| `sls_ship_dt` | `DATE` | — |
| `sls_due_dt` | `DATE` | — |
| `sls_sales` | `INT` | — |
| `sls_quantity` | `INT` | — |
| `sls_price` | `INT` | — |
| `dwh_create_date` | `DATETIME2` | `GETDATE()` |

### `silver.erp_cust_az12`

| Column | SQL type | Default |
|---|---|---|
| `cid` | `NVARCHAR(50)` | — |
| `bdate` | `DATE` | — |
| `gen` | `NVARCHAR(50)` | — |
| `dwh_create_date` | `DATETIME2` | `GETDATE()` |

### `silver.erp_loc_a101`

| Column | SQL type | Default |
|---|---|---|
| `cid` | `NVARCHAR(50)` | — |
| `cntry` | `NVARCHAR(50)` | — |
| `dwh_create_date` | `DATETIME2` | `GETDATE()` |

### `silver.erp_px_cat_g1v2`

| Column | SQL type | Default |
|---|---|---|
| `id` | `NVARCHAR(50)` | — |
| `cat` | `NVARCHAR(50)` | — |
| `subcat` | `NVARCHAR(50)` | — |
| `maintenance` | `NVARCHAR(50)` | — |
| `dwh_create_date` | `DATETIME2` | `GETDATE()` |

## Interpretation

Bronze sales dates are integer source values; Silver sales dates are `DATE`. Product dates are `DATETIME` in Bronze and `DATE` in Silver. Product category and normalized product identifiers are derived in Silver. Each Silver table adds `dwh_create_date DATETIME2 DEFAULT GETDATE()` to record insertion time, not source event time or a durable batch identifier.

For field cleaning, see [the transformation matrix](etl_design.md#implemented-transformation-matrix). Business-facing aliases, measures, and key definitions appear in the [Gold catalog](data_catalog.md).
