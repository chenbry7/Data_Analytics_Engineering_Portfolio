CREATE OR ALTER VIEW gold.fact_status_category AS
SELECT
    -- main SOR identifiers
    ROW_NUMBER() OVER (ORDER BY s.sor_id) AS sor_key,
    s.sor_id,

    -- site information
    s.site_id,
    s.site_name,
    CASE WHEN s.site_name LIKE '%Program%' THEN 'Children & Family Services for York Region'
         WHEN s.site_name LIKE '%Office%' THEN 'Children & Family Services of York Region'
    END AS society_name,
    CASE WHEN s.site_name LIKE '%Program%' THEN 'Foster Care Program_NS000348'
         WHEN s.site_name LIKE '%Office%' THEN '16915 Leslie, non-licensed Head Office_PL102331'
    END AS office_name,
    s.non_funded_licensed_OPR,

    -- SOR status information
    s.confidential_sor,
    s.[status] AS sor_status,
    s.sor_initiator,
    s.sor_level,
    s.media_attention,

    -- date / time information
    s.date_serious_occur,
    DATEFROMPARTS(
    YEAR(TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM(s.date_serious_occur), ''), 'n/a'))),
    MONTH(TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM(s.date_serious_occur), ''), 'n/a'))),
    1
    ) AS month_serious_occur,
    CONVERT(CHAR(7), TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM(s.date_serious_occur), ''), 'n/a')), 120) AS month_occur_label,
    s.time_serious_occur,
    s.date_report_submit,
    DATEFROMPARTS(
    YEAR(TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM(s.date_report_submit), ''), 'n/a'))),
    MONTH(TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM(s.date_report_submit), ''), 'n/a'))),
    1
    ) AS month_report_submit,
    CONVERT(CHAR(7), TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM(s.date_report_submit), ''), 'n/a')), 120) AS month_submit_label,
    s.time_report_submit,
    s.last_update_date,
    DATEFROMPARTS(
    YEAR(TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM(s.last_update_date), ''), 'n/a'))),
    MONTH(TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM(s.last_update_date), ''), 'n/a'))),
    1
    ) AS month_last_update,
    CONVERT(CHAR(7), TRY_CONVERT(DATE, NULLIF(NULLIF(TRIM(s.last_update_date), ''), 'n/a')), 120) AS month_last_update_label,
    s.last_update_time,
    s.update_due_date,
    s.revision_due_date,

    -- SOR summary measures
    s.num_individuals,
    s.num_unique_individuals,
    s.num_unique_categories,
    

    -- category detail information
    c.category,
    c.sub_category,
    c.[type] AS category_type,
    c.claim,
    c.[role]AS client_role,
    c.category_level,
    c.[location] AS occurance_location,

    -- client information
    c.client_id,
    c.client_DOB,
    TRY_CONVERT(INT,NULLIF(NULLIF(TRIM(c.client_age),''),'n/a')) AS client_age,
    c.CPIN,

    -- guardian / care information
    c.guardian_status,
    c.CSC,
    c.ISC,
    c.TCA,
    c.parent_guardian_care,
    c.indep_adult,

    -- program / youth factors
    c.program,
    
    -- notification information
    c.provider_notification,
    c.noti_coroner AS notification_coroner,
    c.noti_ombudsman AS notification_ombudsman,
    c.noti_parent_guardian AS notification_parent_guardian,
    c.noti_local_health AS notification_local_health,
    c.noti_placing_agency AS notification_placing_agency,
    c.noti_police AS notification_police,
    c.noti_other_ministry AS notification_other_ministry,
    c.noti_emergency_DS AS notification_emergency_DS,
    c.noti_other AS notification_other

FROM silver.SO_status s
LEFT JOIN silver.SO_category c
    ON s.sor_id = c.sor_id;
GO

SELECT *
FROM gold.fact_status_category;