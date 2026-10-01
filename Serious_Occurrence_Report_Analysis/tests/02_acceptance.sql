:ON ERROR EXIT
-- Post-internship enhancement. Run only in the isolated synthetic demonstration database.
IF DB_NAME() <> N'SOR_Portfolio_Test'
    THROW 52000, 'This script requires SOR_Portfolio_Test.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties
               WHERE class = 0 AND name = N'SORPortfolioDemo' AND CONVERT(nvarchar(20), value) = N'1')
    THROW 52000, 'The database is not marked as this project demonstration.', 1;
GO

SET NOCOUNT ON;
EXEC silver.load_all;
IF (SELECT COUNT(*) FROM silver.SO_status) <> 3 OR (SELECT COUNT(*) FROM silver.SO_category) <> 4
    THROW 52900, 'Fixture load counts are wrong.', 1;
IF (SELECT COUNT(*) FROM gold.fact_events) <> 3 OR (SELECT COUNT(*) FROM gold.fact_categories) <> 4
    THROW 52900, 'Event/detail grains are wrong.', 1;
IF (SELECT COUNT(*) FROM silver.SO_category WHERE client_id='DEMO-P001') <> 3
    THROW 52900, 'Repeated participants must be preserved.', 1;
IF NOT EXISTS (SELECT 1 FROM silver.SO_status WHERE sor_id='DEMO-E001' AND site_name='Demo Site A'
               AND non_funded_licensed_OPR='Yes' AND update_due_date IS NULL AND revision_due_date IS NULL)
    THROW 52900, 'Normalization or optional null handling failed.', 1;
IF NOT EXISTS (SELECT 1 FROM silver.SO_category WHERE sor_id='DEMO-E001'
               AND date_time_report_submit=CONVERT(datetime2(0),'2026-06-02T10:00:00',126))
    THROW 52900, 'Timestamp precision was lost.', 1;
IF NOT EXISTS (SELECT 1 FROM silver.SO_category WHERE client_id='DEMO-P002' AND client_age IS NULL AND client_DOB IS NULL)
    THROW 52900, 'Optional typed fields should allow missing values.', 1;

IF EXISTS (SELECT 1 FROM gold.fact_categories WHERE sor_id='DEMO-E003')
    THROW 52900, 'An event without categories must not create a category record.', 1;
IF (SELECT COUNT(*) FROM gold.fact_categories WHERE age_group='Unknown' AND age_group_order=6) <> 1
    THROW 52900, 'Unknown age classification is wrong.', 1;
IF (SELECT COUNT(*) FROM gold.fact_categories WHERE client_id='DEMO-P001') <> 3
    THROW 52900, 'Repeated participant records must be retained.', 1;
IF (SELECT SUM(report_delay_days) FROM gold.fact_events) <> 2
    THROW 52900, 'Event-level reporting delay is wrong.', 1;
SELECT * INTO #source_status FROM bronze.SO_status;
SELECT * INTO #source_category FROM bronze.SO_category;
CREATE TABLE #expected (status_json nvarchar(max), category_json nvarchar(max));
INSERT #expected SELECT
 (SELECT * FROM silver.SO_status ORDER BY sor_id FOR JSON PATH, INCLUDE_NULL_VALUES),
 (SELECT * FROM silver.SO_category ORDER BY sor_id, category, client_id, program FOR JSON PATH, INCLUDE_NULL_VALUES);
CREATE TABLE #results (test_name varchar(120) NOT NULL, result varchar(10) NOT NULL);
INSERT #results VALUES ('Valid load, normalization, optional nulls and timestamp precision','PASS'),
 ('Unique event grain and preserved repeated participants','PASS');

EXEC silver.load_all;
IF EXISTS (SELECT 1 FROM #expected WHERE status_json <>
 (SELECT * FROM silver.SO_status ORDER BY sor_id FOR JSON PATH, INCLUDE_NULL_VALUES)
 OR category_json <> (SELECT * FROM silver.SO_category ORDER BY sor_id, category, client_id, program FOR JSON PATH, INCLUDE_NULL_VALUES))
    THROW 52900, 'Repeat load changed results.', 1;
INSERT #results VALUES ('Repeated full refresh produces identical output','PASS');
GO

CREATE OR ALTER PROCEDURE #expect_rejection
    @name varchar(120), @mutation nvarchar(max), @expected_error int
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE bronze.SO_status;
    TRUNCATE TABLE bronze.SO_category;
    INSERT bronze.SO_status SELECT * FROM #source_status;
    INSERT bronze.SO_category SELECT * FROM #source_category;
    EXEC sys.sp_executesql @mutation;
    DECLARE @actual_error int = NULL;
    BEGIN TRY
        EXEC silver.load_all;
    END TRY
    BEGIN CATCH
        SET @actual_error = ERROR_NUMBER();
    END CATCH;
    IF @actual_error IS NULL OR @actual_error <> @expected_error
    BEGIN
        DECLARE @message nvarchar(2048) = CONCAT(@name, ': expected error ', @expected_error,
                                                ', actual ', COALESCE(CONVERT(varchar(20),@actual_error), 'none'));
        THROW 52901, @message, 1;
    END;
    IF @@TRANCOUNT <> 0 THROW 52902, 'Loader leaked an open transaction.', 1;
    IF EXISTS (SELECT 1 FROM #expected WHERE status_json <>
       (SELECT * FROM silver.SO_status ORDER BY sor_id FOR JSON PATH, INCLUDE_NULL_VALUES)
       OR category_json <> (SELECT * FROM silver.SO_category ORDER BY sor_id, category, client_id, program FOR JSON PATH, INCLUDE_NULL_VALUES))
        THROW 52903, 'A rejected load changed the previous Silver snapshot.', 1;
    INSERT #results VALUES (@name,'PASS');
END;
GO

EXEC #expect_rejection 'Duplicate event after trimming',
 N'INSERT bronze.SO_status SELECT * FROM bronze.SO_status WHERE TRIM(sor_id)=''DEMO-E001'';', 52004;
EXEC #expect_rejection 'Missing status event ID',
 N'UPDATE bronze.SO_status SET sor_id='' '' WHERE TRIM(sor_id)=''DEMO-E001'';', 52003;
EXEC #expect_rejection 'Missing category event ID',
 N'UPDATE bronze.SO_category SET sor_id=NULL WHERE sor_id=''DEMO-E001'';', 52003;
EXEC #expect_rejection 'Orphan category event',
 N'UPDATE bronze.SO_category SET sor_id=''DEMO-MISSING'' WHERE sor_id=''DEMO-E001'';', 52005;
EXEC #expect_rejection 'Empty status snapshot', N'TRUNCATE TABLE bronze.SO_status;', 52002;
EXEC #expect_rejection 'Empty category snapshot', N'TRUNCATE TABLE bronze.SO_category;', 52002;
EXEC #expect_rejection 'Impossible date',
 N'UPDATE bronze.SO_status SET date_serious_occur=''2026-02-30'';', 52006;
EXEC #expect_rejection 'Ambiguous non-ISO date',
 N'UPDATE bronze.SO_status SET date_serious_occur=''06/01/2026'';', 52006;
EXEC #expect_rejection 'Invalid clock time',
 N'UPDATE bronze.SO_status SET time_serious_occur=''25:00:00'';', 52006;
EXEC #expect_rejection 'Fractional timestamp would lose precision',
 N'UPDATE bronze.SO_category SET date_time_report_submit=''2026-06-02T10:00:00.123'';', 52006;
EXEC #expect_rejection 'Negative participant count',
 N'UPDATE bronze.SO_status SET num_individuals=''-1'';', 52006;
EXEC #expect_rejection 'Fractional integer count',
 N'UPDATE bronze.SO_status SET num_unique_individuals=''1.5'';', 52006;
EXEC #expect_rejection 'Invalid birth date',
 N'UPDATE bronze.SO_category SET client_DOB=''not-a-date'';', 52006;
EXEC #expect_rejection 'Occurrence after submission',
 N'UPDATE bronze.SO_status SET date_report_submit=''2026-05-01'';', 52007;
EXEC #expect_rejection 'Category occurrence after submission',
 N'UPDATE bronze.SO_category SET date_time_report_submit=''2026-05-01T10:00:00'';', 52007;

-- Inject an INSERT failure after both Silver DELETEs and the status INSERT.
-- The preceding 15 rejections exercise validation; this one proves actual write rollback.
ALTER TABLE silver.SO_category ADD CONSTRAINT CK_demo_injected_failure CHECK (program <> 'DEMO_FORCE_FAILURE');
BEGIN TRY
    EXEC #expect_rejection 'Rollback after mid-write constraint failure',
      N'UPDATE bronze.SO_category SET program=''DEMO_FORCE_FAILURE'';', 547;
    ALTER TABLE silver.SO_category DROP CONSTRAINT CK_demo_injected_failure;
END TRY
BEGIN CATCH
    IF OBJECT_ID(N'silver.CK_demo_injected_failure', N'C') IS NOT NULL
        ALTER TABLE silver.SO_category DROP CONSTRAINT CK_demo_injected_failure;
    THROW;
END CATCH;

-- Restore a valid, populated synthetic demonstration after the rejection tests.
TRUNCATE TABLE bronze.SO_status;
TRUNCATE TABLE bronze.SO_category;
INSERT bronze.SO_status SELECT * FROM #source_status;
INSERT bronze.SO_category SELECT * FROM #source_category;
EXEC silver.load_all;
SELECT test_name, result FROM #results ORDER BY test_name;
SELECT COUNT(*) AS passed_tests FROM #results;
SELECT (SELECT COUNT(*) FROM bronze.SO_status) AS bronze_events,
       (SELECT COUNT(*) FROM bronze.SO_category) AS bronze_category_rows,
       (SELECT COUNT(*) FROM silver.SO_status) AS silver_events,
       (SELECT COUNT(*) FROM silver.SO_category) AS silver_category_rows,
       (SELECT COUNT(*) FROM gold.fact_events) AS gold_events,
       (SELECT COUNT(*) FROM gold.fact_categories) AS gold_category_rows;
DROP PROCEDURE #expect_rejection;
GO
