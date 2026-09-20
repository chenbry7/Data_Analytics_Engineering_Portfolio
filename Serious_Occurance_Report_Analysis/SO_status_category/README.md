# Serious Occurrence Reporting ETL Project

Welcome to my **Serious Occurrence Reporting ETL Project** repository.

This project demonstrates how to build an end-to-end ETL pipeline using **SQL Server**, **SSIS**, and **Power BI**. The project processes Serious Occurrence Report, or SOR, data from raw CSV files into clean, structured, and analytics-ready tables and views.

The project follows a **Bronze, Silver, and Gold** data architecture and is designed as a portfolio project to showcase practical skills in **SSIS development, SQL Server ETL, data cleaning, data quality validation, analytical modeling, and dashboard preparation**.

---

## Data Architecture

The project uses a three-layer data architecture:

1. **Bronze Layer**
   Stores raw CSV data as loaded from the source files.

2. **Silver Layer**
   Cleans and standardizes the raw data using SQL stored procedures.

3. **Gold Layer**
   Creates business-ready analytical views for reporting and dashboarding.

The final Gold layer includes:

* `gold.fact_status_category`

---

## Project Overview

This project uses two Serious Occurrence source files:

* `SO_status`
* `SO_category`

The overall workflow includes:

1. Creating Bronze, Silver, and Gold schemas.
2. Loading raw CSV files into Bronze tables using SSIS.
3. Performing data quality checks on Bronze data.
4. Cleaning and transforming data into Silver tables.
5. Creating a Gold analytical view by joining status and category data.
6. Preparing the final dataset for Power BI dashboarding and further analysis.

---

## Datasets

| Source File   | Description                                                                                |
| ------------- | ------------------------------------------------------------------------------------------ |
| `SO_status`   | Contains status-level information for each Serious Occurrence Report                       |
| `SO_category` | Contains category-level and client-level details related to each Serious Occurrence Report |

The `SO_status` table has one record per `sor_id`, while the `SO_category` table can contain multiple records for the same `sor_id`.

---

## ETL Process

The ETL pipeline is built with **SSIS packages** and **SQL Server scripts**.

### Bronze Layer

The Bronze layer stores raw imported data from CSV files.

Example Bronze tables:

* `bronze.SO_status`
* `bronze.SO_category`

---

### Silver Layer

The Silver layer applies cleaning and standardization logic.

Main transformations include:

* Trimming unwanted spaces
* Standardizing `Y` / `N` values into `Yes` / `No`
* Handling blank and missing values
* Converting date and time fields
* Cleaning inconsistent text values
* Preparing useful fields for analysis

Example Silver tables:

* `silver.SO_status`
* `silver.SO_category`

---

### Gold Layer

The Gold layer creates an analytics-ready view:

* `gold.fact_status_category`

This view joins `silver.SO_status` and `silver.SO_category` using `sor_id`.

The Gold view supports analysis such as:

* SOR count by status and level
* Monthly Serious Occurrence trends
* Category and sub-category distribution
* Site-level analysis
* Media attention analysis
* Client age analysis
* Notification analysis
* Reporting delay analysis

---

## Power BI Dashboard

The final Gold view is used to support a Power BI dashboard.

Suggested dashboard pages include:

* Executive Overview
* Category and Site Analysis
* Reporting and Detail
* Exploration and Drilldown

Example visuals include:

* KPI cards
* Monthly SOR trend chart
* SOR by status and level
* Category distribution
* Site by category matrix
* Average report delay by site
* Notification analysis
* Decomposition tree

---

## Repository Structure

```text
serious-occurrence-reporting-etl/
│
├── scripts/
│   ├── 01_create_schema_bronze_tables.sql
│   ├── 02_create_silver_tables.sql
│   ├── 03_bronze_quality_check.sql
│   ├── 04_bronze_to_silver.sql
│   └── 05_gold_layer.sql
│
├── ssis/
│   ├── SO_solution.slnx
│   ├── SO_status_category.dtproj
│   ├── SO_status.dtsx
│   ├── SO_category.dtsx
│   └── SO_status_category.dtsx
│
├── powerbi/
│   └── SO_status_category.pbix
│
├── README.md
└── LICENSE
```

---

## SQL Scripts

| Script                               | Purpose                                         |
| ------------------------------------ | ----------------------------------------------- |
| `01_create_schema_bronze_tables.sql` | Creates schemas and Bronze tables               |
| `02_create_silver_tables.sql`        | Creates Silver layer tables                     |
| `03_bronze_quality_check.sql`        | Checks raw Bronze data quality                  |
| `04_bronze_to_silver.sql`            | Cleans and loads Bronze data into Silver tables |
| `05_gold_layer.sql`                  | Creates the Gold analytical view                |

---

## SSIS Packages

| Package                   | Purpose                        |
| ------------------------- | ------------------------------ |
| `SO_status.dtsx`          | Loads SO status data           |
| `SO_category.dtsx`        | Loads SO category data         |
| `SO_status_category.dtsx` | Runs the combined ETL workflow |

---

## How to Run

1. Open **SQL Server Management Studio**.
2. Run the SQL scripts in order from `01` to `05`.
3. Open the SSIS project in **Visual Studio / SQL Server Data Tools**.
4. Update the Flat File Connection Managers to local CSV file paths.
5. Update the OLE DB Connection Manager to the target SQL Server database.
6. Run the SSIS package to load data into the Bronze layer.
7. Execute the Silver loading procedures.
8. Refresh the Power BI report using the Gold view.

---

## Tools and Technologies

* SQL Server
* SQL Server Management Studio
* SQL Server Integration Services
* Visual Studio / SQL Server Data Tools
* T-SQL
* Stored Procedures
* SQL Views
* Power BI
* CSV Files
* Git and GitHub

---

## Key Skills Demonstrated

* SSIS ETL pipeline development
* SQL Server data warehouse design
* Bronze, Silver, and Gold layer architecture
* Data cleaning and transformation
* Data quality validation
* Stored procedure development
* Analytical SQL view creation
* One-to-many data modeling
* Power BI dashboard preparation
* Technical documentation

---

## Notes

* This project uses a full-load approach with truncate and insert logic.
* The Gold layer is implemented as a SQL view.
* Since `SO_category` may contain multiple records for the same `sor_id`, Power BI measures should use `DISTINCTCOUNT(sor_id)` for SOR-level counts.
* Local file paths and database connections must be updated before running the SSIS package on another machine.
* Sensitive or personal data should be anonymized before being uploaded to GitHub.

---

## Author

**Bryan Chen**

This project was completed as a SQL Server, SSIS, and Power BI portfolio project, focusing on ETL pipeline development, data cleaning, analytical modeling, and dashboard-ready reporting.

This project was completed as a SQL Server, SSIS, and Power BI portfolio project. It focuses on building a structured ETL pipeline, transforming raw Serious Occurrence data into analytics-ready views, and developing dashboard-ready data models for reporting and analysis.
