/*
=============================================================
Execute ETL Procedures
=============================================================
Script Purpose:
    This script executes the main ETL procedures in sequence. It first runs
    'bronze.load_bronze' to load raw source data into the bronze layer, and then
    runs 'silver.load_silver' to cleanse and transform the data into the silver
    layer.

WARNING:
    Running this script will execute both bronze and silver loading procedures.
    These procedures truncate and reload their target tables, meaning existing
    data in the bronze and silver layers will be replaced. Ensure that source
    files, table structures, and transformation rules are correct before running
    this script.
*/

USE DataWarehouse;
GO


EXEC bronze.load_bronze;

EXEC silver.load_silver;
