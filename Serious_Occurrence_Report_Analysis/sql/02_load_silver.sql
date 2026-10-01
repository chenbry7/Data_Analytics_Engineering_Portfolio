:ON ERROR EXIT
-- Post-internship enhancement. Run only in the isolated synthetic demonstration database.
IF DB_NAME() <> N'SOR_Portfolio_Test'
    THROW 52000, 'This script requires SOR_Portfolio_Test.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties
               WHERE class = 0 AND name = N'SORPortfolioDemo' AND CONVERT(nvarchar(20), value) = N'1')
    THROW 52000, 'The database is not marked as this project demonstration.', 1;
GO

CREATE OR ALTER PROCEDURE silver.load_all
AS
BEGIN
    SET NOCOUNT ON;
    -- This procedure owns the transaction; avoid rolling back an unrelated caller transaction.
    IF @@TRANCOUNT <> 0
        THROW 52001, 'Run silver.load_all outside an existing transaction.', 1;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Stabilize each Bronze snapshot during this load. One ingestion writer at a time is required.
        SELECT * INTO #raw_status FROM bronze.SO_status WITH (TABLOCK, HOLDLOCK);
        SELECT * INTO #raw_category FROM bronze.SO_category WITH (TABLOCK, HOLDLOCK);

        IF NOT EXISTS (SELECT 1 FROM #raw_status) OR NOT EXISTS (SELECT 1 FROM #raw_category)
            THROW 52002, 'Both source snapshots must be nonempty.', 1;
        IF EXISTS (SELECT 1 FROM #raw_status WHERE NULLIF(NULLIF(TRIM(sor_id), ''), 'n/a') IS NULL)
           OR EXISTS (SELECT 1 FROM #raw_category WHERE NULLIF(NULLIF(TRIM(sor_id), ''), 'n/a') IS NULL)
            THROW 52003, 'Event identifiers must be populated in both sources.', 1;
        IF EXISTS (SELECT TRIM(sor_id) FROM #raw_status GROUP BY TRIM(sor_id) HAVING COUNT(*) > 1)
            THROW 52004, 'Status event identifiers must be unique after trimming.', 1;
        IF EXISTS (SELECT 1 FROM #raw_category c WHERE NOT EXISTS
                   (SELECT 1 FROM #raw_status s WHERE TRIM(s.sor_id) = TRIM(c.sor_id)))
            THROW 52005, 'Every category record must reference a status event.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([date_serious_occur]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([date_serious_occur]), ''), 'n/a'), 23) IS NULL OR LEN(NULLIF(NULLIF(TRIM([date_serious_occur]), ''), 'n/a')) <> 10 OR CONVERT(char(10), TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([date_serious_occur]), ''), 'n/a'), 23), 23) <> NULLIF(NULLIF(TRIM([date_serious_occur]), ''), 'n/a'))))
            THROW 52006, 'Invalid SO_status.date_serious_occur: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([date_report_submit]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([date_report_submit]), ''), 'n/a'), 23) IS NULL OR LEN(NULLIF(NULLIF(TRIM([date_report_submit]), ''), 'n/a')) <> 10 OR CONVERT(char(10), TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([date_report_submit]), ''), 'n/a'), 23), 23) <> NULLIF(NULLIF(TRIM([date_report_submit]), ''), 'n/a'))))
            THROW 52006, 'Invalid SO_status.date_report_submit: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([last_update_date]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([last_update_date]), ''), 'n/a'), 23) IS NULL OR LEN(NULLIF(NULLIF(TRIM([last_update_date]), ''), 'n/a')) <> 10 OR CONVERT(char(10), TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([last_update_date]), ''), 'n/a'), 23), 23) <> NULLIF(NULLIF(TRIM([last_update_date]), ''), 'n/a'))))
            THROW 52006, 'Invalid SO_status.last_update_date: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([update_due_date]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([update_due_date]), ''), 'n/a'), 23) IS NULL OR LEN(NULLIF(NULLIF(TRIM([update_due_date]), ''), 'n/a')) <> 10 OR CONVERT(char(10), TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([update_due_date]), ''), 'n/a'), 23), 23) <> NULLIF(NULLIF(TRIM([update_due_date]), ''), 'n/a'))))
            THROW 52006, 'Invalid SO_status.update_due_date: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([revision_due_date]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([revision_due_date]), ''), 'n/a'), 23) IS NULL OR LEN(NULLIF(NULLIF(TRIM([revision_due_date]), ''), 'n/a')) <> 10 OR CONVERT(char(10), TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([revision_due_date]), ''), 'n/a'), 23), 23) <> NULLIF(NULLIF(TRIM([revision_due_date]), ''), 'n/a'))))
            THROW 52006, 'Invalid SO_status.revision_due_date: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([time_serious_occur]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(TIME(0), NULLIF(NULLIF(TRIM([time_serious_occur]), ''), 'n/a'), 108) IS NULL OR LEN(NULLIF(NULLIF(TRIM([time_serious_occur]), ''), 'n/a')) <> 8 OR CONVERT(char(8), TRY_CONVERT(TIME(0), NULLIF(NULLIF(TRIM([time_serious_occur]), ''), 'n/a'), 108), 108) <> NULLIF(NULLIF(TRIM([time_serious_occur]), ''), 'n/a'))))
            THROW 52006, 'Invalid SO_status.time_serious_occur: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([time_report_submit]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(TIME(0), NULLIF(NULLIF(TRIM([time_report_submit]), ''), 'n/a'), 108) IS NULL OR LEN(NULLIF(NULLIF(TRIM([time_report_submit]), ''), 'n/a')) <> 8 OR CONVERT(char(8), TRY_CONVERT(TIME(0), NULLIF(NULLIF(TRIM([time_report_submit]), ''), 'n/a'), 108), 108) <> NULLIF(NULLIF(TRIM([time_report_submit]), ''), 'n/a'))))
            THROW 52006, 'Invalid SO_status.time_report_submit: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([last_update_time]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(TIME(0), NULLIF(NULLIF(TRIM([last_update_time]), ''), 'n/a'), 108) IS NULL OR LEN(NULLIF(NULLIF(TRIM([last_update_time]), ''), 'n/a')) <> 8 OR CONVERT(char(8), TRY_CONVERT(TIME(0), NULLIF(NULLIF(TRIM([last_update_time]), ''), 'n/a'), 108), 108) <> NULLIF(NULLIF(TRIM([last_update_time]), ''), 'n/a'))))
            THROW 52006, 'Invalid SO_status.last_update_time: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([num_individuals]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([num_individuals]), ''), 'n/a')) IS NULL OR TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([num_individuals]), ''), 'n/a')) < 0 OR NULLIF(NULLIF(TRIM([num_individuals]), ''), 'n/a') COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9]%')))
            THROW 52006, 'Invalid SO_status.num_individuals: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([num_unique_individuals]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([num_unique_individuals]), ''), 'n/a')) IS NULL OR TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([num_unique_individuals]), ''), 'n/a')) < 0 OR NULLIF(NULLIF(TRIM([num_unique_individuals]), ''), 'n/a') COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9]%')))
            THROW 52006, 'Invalid SO_status.num_unique_individuals: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_status WHERE (NULLIF(NULLIF(TRIM([num_unique_categories]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([num_unique_categories]), ''), 'n/a')) IS NULL OR TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([num_unique_categories]), ''), 'n/a')) < 0 OR NULLIF(NULLIF(TRIM([num_unique_categories]), ''), 'n/a') COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9]%')))
            THROW 52006, 'Invalid SO_status.num_unique_categories: use the documented ISO or nonnegative integer format.', 1;

        SELECT
            NULLIF(NULLIF(TRIM([site_id]), ''), 'n/a') AS [site_id],
            NULLIF(NULLIF(TRIM([site_name]), ''), 'n/a') AS [site_name],
            CASE UPPER(TRIM([non_funded_licensed_OPR])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [non_funded_licensed_OPR],
            NULLIF(NULLIF(TRIM([sor_id]), ''), 'n/a') AS [sor_id],
            NULLIF(NULLIF(TRIM([confidential_sor]), ''), 'n/a') AS [confidential_sor],
            NULLIF(NULLIF(TRIM([status]), ''), 'n/a') AS [status],
            NULLIF(NULLIF(TRIM([sor_initiator]), ''), 'n/a') AS [sor_initiator],
            TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([date_serious_occur]), ''), 'n/a'), 23) AS [date_serious_occur],
            TRY_CONVERT(TIME(0), NULLIF(NULLIF(TRIM([time_serious_occur]), ''), 'n/a'), 108) AS [time_serious_occur],
            TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([date_report_submit]), ''), 'n/a'), 23) AS [date_report_submit],
            TRY_CONVERT(TIME(0), NULLIF(NULLIF(TRIM([time_report_submit]), ''), 'n/a'), 108) AS [time_report_submit],
            TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([last_update_date]), ''), 'n/a'), 23) AS [last_update_date],
            TRY_CONVERT(TIME(0), NULLIF(NULLIF(TRIM([last_update_time]), ''), 'n/a'), 108) AS [last_update_time],
            TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([update_due_date]), ''), 'n/a'), 23) AS [update_due_date],
            TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([revision_due_date]), ''), 'n/a'), 23) AS [revision_due_date],
            NULLIF(NULLIF(TRIM([sor_level]), ''), 'n/a') AS [sor_level],
            CASE UPPER(TRIM([media_attention])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [media_attention],
            TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([num_individuals]), ''), 'n/a')) AS [num_individuals],
            TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([num_unique_individuals]), ''), 'n/a')) AS [num_unique_individuals],
            TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([num_unique_categories]), ''), 'n/a')) AS [num_unique_categories]
        INTO #clean_status
        FROM #raw_status;

        IF EXISTS (SELECT 1 FROM #raw_category WHERE (NULLIF(NULLIF(TRIM([date_time_serious_occur]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(DATETIME2(0), REPLACE(NULLIF(NULLIF(TRIM([date_time_serious_occur]), ''), 'n/a'), ' ', 'T'), 126) IS NULL OR LEN(NULLIF(NULLIF(TRIM([date_time_serious_occur]), ''), 'n/a')) <> 19 OR CONVERT(char(19), TRY_CONVERT(DATETIME2(0), REPLACE(NULLIF(NULLIF(TRIM([date_time_serious_occur]), ''), 'n/a'), ' ', 'T'), 126), 126) <> REPLACE(NULLIF(NULLIF(TRIM([date_time_serious_occur]), ''), 'n/a'), ' ', 'T'))))
            THROW 52006, 'Invalid SO_category.date_time_serious_occur: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_category WHERE (NULLIF(NULLIF(TRIM([date_time_report_submit]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(DATETIME2(0), REPLACE(NULLIF(NULLIF(TRIM([date_time_report_submit]), ''), 'n/a'), ' ', 'T'), 126) IS NULL OR LEN(NULLIF(NULLIF(TRIM([date_time_report_submit]), ''), 'n/a')) <> 19 OR CONVERT(char(19), TRY_CONVERT(DATETIME2(0), REPLACE(NULLIF(NULLIF(TRIM([date_time_report_submit]), ''), 'n/a'), ' ', 'T'), 126), 126) <> REPLACE(NULLIF(NULLIF(TRIM([date_time_report_submit]), ''), 'n/a'), ' ', 'T'))))
            THROW 52006, 'Invalid SO_category.date_time_report_submit: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_category WHERE (NULLIF(NULLIF(TRIM([last_update_date_time]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(DATETIME2(0), REPLACE(NULLIF(NULLIF(TRIM([last_update_date_time]), ''), 'n/a'), ' ', 'T'), 126) IS NULL OR LEN(NULLIF(NULLIF(TRIM([last_update_date_time]), ''), 'n/a')) <> 19 OR CONVERT(char(19), TRY_CONVERT(DATETIME2(0), REPLACE(NULLIF(NULLIF(TRIM([last_update_date_time]), ''), 'n/a'), ' ', 'T'), 126), 126) <> REPLACE(NULLIF(NULLIF(TRIM([last_update_date_time]), ''), 'n/a'), ' ', 'T'))))
            THROW 52006, 'Invalid SO_category.last_update_date_time: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_category WHERE (NULLIF(NULLIF(TRIM([client_DOB]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([client_DOB]), ''), 'n/a'), 23) IS NULL OR LEN(NULLIF(NULLIF(TRIM([client_DOB]), ''), 'n/a')) <> 10 OR CONVERT(char(10), TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([client_DOB]), ''), 'n/a'), 23), 23) <> NULLIF(NULLIF(TRIM([client_DOB]), ''), 'n/a'))))
            THROW 52006, 'Invalid SO_category.client_DOB: use the documented ISO or nonnegative integer format.', 1;

        IF EXISTS (SELECT 1 FROM #raw_category WHERE (NULLIF(NULLIF(TRIM([client_age]), ''), 'n/a') IS NOT NULL AND (TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([client_age]), ''), 'n/a')) IS NULL OR TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([client_age]), ''), 'n/a')) < 0 OR NULLIF(NULLIF(TRIM([client_age]), ''), 'n/a') COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9]%')))
            THROW 52006, 'Invalid SO_category.client_age: use the documented ISO or nonnegative integer format.', 1;

        SELECT
            NULLIF(NULLIF(TRIM([site_id]), ''), 'n/a') AS [site_id],
            NULLIF(NULLIF(TRIM([site_name]), ''), 'n/a') AS [site_name],
            CASE UPPER(TRIM([related_OPR])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [related_OPR],
            NULLIF(NULLIF(TRIM([sor_id]), ''), 'n/a') AS [sor_id],
            NULLIF(NULLIF(TRIM([confidential_sor]), ''), 'n/a') AS [confidential_sor],
            NULLIF(NULLIF(TRIM([status]), ''), 'n/a') AS [status],
            NULLIF(NULLIF(TRIM([sor_initiator]), ''), 'n/a') AS [sor_initiator],
            TRY_CONVERT(DATETIME2(0), REPLACE(NULLIF(NULLIF(TRIM([date_time_serious_occur]), ''), 'n/a'), ' ', 'T'), 126) AS [date_time_serious_occur],
            TRY_CONVERT(DATETIME2(0), REPLACE(NULLIF(NULLIF(TRIM([date_time_report_submit]), ''), 'n/a'), ' ', 'T'), 126) AS [date_time_report_submit],
            TRY_CONVERT(DATETIME2(0), REPLACE(NULLIF(NULLIF(TRIM([last_update_date_time]), ''), 'n/a'), ' ', 'T'), 126) AS [last_update_date_time],
            NULLIF(NULLIF(TRIM([sor_level]), ''), 'n/a') AS [sor_level],
            CASE UPPER(TRIM([media_attention])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [media_attention],
            NULLIF(NULLIF(TRIM([category]), ''), 'n/a') AS [category],
            NULLIF(NULLIF(TRIM([sub_category]), ''), 'n/a') AS [sub_category],
            COALESCE(NULLIF(NULLIF(TRIM([type]), ''), 'n/a'), 'n/a') AS [type],
            COALESCE(NULLIF(NULLIF(TRIM([claim]), ''), 'n/a'), 'n/a') AS [claim],
            COALESCE(NULLIF(NULLIF(TRIM([role]), ''), 'n/a'), 'n/a') AS [role],
            NULLIF(NULLIF(TRIM([category_level]), ''), 'n/a') AS [category_level],
            CASE WHEN [location] IN (N'At the service providerâ€™s site', N'At the service provider’s site') THEN 'At the service provider site' ELSE NULLIF(NULLIF(TRIM([location]), ''), 'n/a') END AS [location],
            NULLIF(NULLIF(TRIM([client_id]), ''), 'n/a') AS [client_id],
            TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM([client_DOB]), ''), 'n/a'), 23) AS [client_DOB],
            TRY_CONVERT(INT, NULLIF(NULLIF(TRIM([client_age]), ''), 'n/a')) AS [client_age],
            NULLIF(NULLIF(TRIM([CPIN]), ''), 'n/a') AS [CPIN],
            COALESCE(NULLIF(NULLIF(TRIM([guardian_status]), ''), 'n/a'), 'n/a') AS [guardian_status],
            CASE UPPER(TRIM([CSC])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [CSC],
            CASE UPPER(TRIM([ISC])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [ISC],
            CASE UPPER(TRIM([TCA])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [TCA],
            CASE UPPER(TRIM([parent_guardian_care])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [parent_guardian_care],
            CASE UPPER(TRIM([indep_adult])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [indep_adult],
            COALESCE(NULLIF(NULLIF(TRIM([program]), ''), 'n/a'), 'n/a') AS [program],
            COALESCE(NULLIF(NULLIF(TRIM([provider_notification]), ''), 'n/a'), 'n/a') AS [provider_notification],
            CASE UPPER(TRIM([noti_coroner])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [noti_coroner],
            CASE UPPER(TRIM([noti_ombudsman])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [noti_ombudsman],
            CASE UPPER(TRIM([noti_parent_guardian])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [noti_parent_guardian],
            CASE UPPER(TRIM([noti_local_health])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [noti_local_health],
            CASE UPPER(TRIM([noti_placing_agency])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [noti_placing_agency],
            CASE UPPER(TRIM([noti_police])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [noti_police],
            CASE UPPER(TRIM([noti_other_ministry])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [noti_other_ministry],
            CASE UPPER(TRIM([noti_emergency_DS])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [noti_emergency_DS],
            CASE UPPER(TRIM([noti_other])) WHEN 'Y' THEN 'Yes' WHEN 'N' THEN 'No' ELSE 'n/a' END AS [noti_other]
        INTO #clean_category
        FROM #raw_category;

        -- Compare dates as dates; preserve category timestamp precision.
        IF EXISTS (SELECT 1 FROM #clean_status
                   WHERE date_serious_occur > date_report_submit OR date_serious_occur > last_update_date)
           OR EXISTS (SELECT 1 FROM #clean_category
                      WHERE date_time_serious_occur > date_time_report_submit
                         OR date_time_serious_occur > last_update_date_time)
            THROW 52007, 'Occurrence cannot be later than report submission or last update.', 1;

        -- Full replacement, child first because Silver now enforces the event relationship.
        DELETE FROM silver.SO_category;
        DELETE FROM silver.SO_status;

        INSERT INTO silver.SO_status ([site_id], [site_name], [non_funded_licensed_OPR], [sor_id], [confidential_sor], [status], [sor_initiator], [date_serious_occur], [time_serious_occur], [date_report_submit], [time_report_submit], [last_update_date], [last_update_time], [update_due_date], [revision_due_date], [sor_level], [media_attention], [num_individuals], [num_unique_individuals], [num_unique_categories])
        SELECT [site_id], [site_name], [non_funded_licensed_OPR], [sor_id], [confidential_sor], [status], [sor_initiator], [date_serious_occur], [time_serious_occur], [date_report_submit], [time_report_submit], [last_update_date], [last_update_time], [update_due_date], [revision_due_date], [sor_level], [media_attention], [num_individuals], [num_unique_individuals], [num_unique_categories] FROM #clean_status;

        INSERT INTO silver.SO_category ([site_id], [site_name], [related_OPR], [sor_id], [confidential_sor], [status], [sor_initiator], [date_time_serious_occur], [date_time_report_submit], [last_update_date_time], [sor_level], [media_attention], [category], [sub_category], [type], [claim], [role], [category_level], [location], [client_id], [client_DOB], [client_age], [CPIN], [guardian_status], [CSC], [ISC], [TCA], [parent_guardian_care], [indep_adult], [program], [provider_notification], [noti_coroner], [noti_ombudsman], [noti_parent_guardian], [noti_local_health], [noti_placing_agency], [noti_police], [noti_other_ministry], [noti_emergency_DS], [noti_other])
        SELECT [site_id], [site_name], [related_OPR], [sor_id], [confidential_sor], [status], [sor_initiator], [date_time_serious_occur], [date_time_report_submit], [last_update_date_time], [sor_level], [media_attention], [category], [sub_category], [type], [claim], [role], [category_level], [location], [client_id], [client_DOB], [client_age], [CPIN], [guardian_status], [CSC], [ISC], [TCA], [parent_guardian_care], [indep_adult], [program], [provider_notification], [noti_coroner], [noti_ombudsman], [noti_parent_guardian], [noti_local_health], [noti_placing_agency], [noti_police], [noti_other_ministry], [noti_emergency_DS], [noti_other] FROM #clean_category;

        IF (SELECT COUNT_BIG(*) FROM silver.SO_status) <> (SELECT COUNT_BIG(*) FROM #raw_status)
           OR (SELECT COUNT_BIG(*) FROM silver.SO_category) <> (SELECT COUNT_BIG(*) FROM #raw_category)
            THROW 52008, 'Bronze and Silver row counts must reconcile.', 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
