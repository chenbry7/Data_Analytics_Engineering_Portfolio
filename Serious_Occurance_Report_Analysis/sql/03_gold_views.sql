:ON ERROR EXIT
-- Post-internship enhancement. Run only in the isolated synthetic demonstration database.
IF DB_NAME() <> N'SOR_Portfolio_Test'
    THROW 52000, 'This script requires SOR_Portfolio_Test.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties
               WHERE class = 0 AND name = N'SORPortfolioDemo' AND CONVERT(nvarchar(20), value) = N'1')
    THROW 52000, 'The database is not marked as this project demonstration.', 1;
GO

CREATE OR ALTER VIEW gold.fact_events AS
SELECT sor_id, site_id, site_name, [status] AS sor_status, sor_level, media_attention,
       date_serious_occur, time_serious_occur, date_report_submit, time_report_submit,
       last_update_date, last_update_time, num_individuals, num_unique_individuals,
       num_unique_categories,
       DATEFROMPARTS(YEAR(date_serious_occur), MONTH(date_serious_occur), 1) AS month_start,
       CONVERT(char(7), date_serious_occur, 120) AS year_month,
       CASE WHEN date_serious_occur IS NULL OR date_report_submit IS NULL THEN NULL
            ELSE DATEDIFF(day, date_serious_occur, date_report_submit) END AS report_delay_days
FROM silver.SO_status;
GO
CREATE OR ALTER VIEW gold.fact_categories AS
SELECT sor_id, category, sub_category, [type] AS category_type, claim,
       [role] AS client_role, category_level, [location] AS occurrence_location,
       client_id, client_age,
       CASE WHEN client_age IS NULL THEN 'Unknown' WHEN client_age < 5 THEN '0-4'
            WHEN client_age < 10 THEN '5-9' WHEN client_age < 15 THEN '10-14'
            WHEN client_age < 18 THEN '15-17' ELSE '18+' END AS age_group,
       CASE WHEN client_age IS NULL THEN 6 WHEN client_age < 5 THEN 1
            WHEN client_age < 10 THEN 2 WHEN client_age < 15 THEN 3
            WHEN client_age < 18 THEN 4 ELSE 5 END AS age_group_order,
       guardian_status, program, provider_notification,
       noti_coroner AS notification_coroner,
       noti_ombudsman AS notification_ombudsman,
       noti_parent_guardian AS notification_parent_guardian,
       noti_local_health AS notification_local_health,
       noti_placing_agency AS notification_placing_agency,
       noti_police AS notification_police,
       noti_other_ministry AS notification_other_ministry,
       noti_emergency_DS AS notification_emergency_DS,
       noti_other AS notification_other
FROM silver.SO_category;
GO
-- Retire the former joined view; events without categories stay in fact_events only.
DROP VIEW IF EXISTS gold.fact_status_category;
GO
