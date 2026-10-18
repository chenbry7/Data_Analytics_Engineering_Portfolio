/*
=============================================================
Load Bronze Layer Tables
=============================================================
Script Purpose:
    This script executes the stored procedure 'bronze.load_bronze' to load raw
    CRM and ERP source data into the bronze layer tables.

WARNING:
    Running this script will execute the bronze loading procedure, which truncates
    and reloads the bronze tables. Existing bronze layer data will be replaced.
    Ensure that the loading procedure and source files are correct before running
    this script.
*/

USE DataWarehouse;
GO


EXEC bronze.load_bronze;
