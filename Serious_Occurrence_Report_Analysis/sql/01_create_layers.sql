:ON ERROR EXIT
-- Post-internship enhancement. Run only in the isolated synthetic demonstration database.
IF DB_NAME() <> N'SOR_Portfolio_Test'
    THROW 52000, 'This script requires SOR_Portfolio_Test.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties
               WHERE class = 0 AND name = N'SORPortfolioDemo' AND CONVERT(nvarchar(20), value) = N'1')
    THROW 52000, 'The database is not marked as this project demonstration.', 1;
GO

IF SCHEMA_ID(N'bronze') IS NULL EXEC(N'CREATE SCHEMA bronze');
IF SCHEMA_ID(N'silver') IS NULL EXEC(N'CREATE SCHEMA silver');
IF SCHEMA_ID(N'gold') IS NULL EXEC(N'CREATE SCHEMA gold');
GO
-- Create-if-missing setup, not an in-place migration of an older schema.

IF OBJECT_ID(N'bronze.SO_status', N'U') IS NULL
CREATE TABLE bronze.SO_status(
    [site_id] VARCHAR(100) NULL,
    [site_name] VARCHAR(200) NULL,
    [non_funded_licensed_OPR] VARCHAR(100) NULL,
    [sor_id] VARCHAR(100) NULL,
    [confidential_sor] VARCHAR(100) NULL,
    [status] VARCHAR(100) NULL,
    [sor_initiator] VARCHAR(100) NULL,
    [date_serious_occur] VARCHAR(100) NULL,
    [time_serious_occur] VARCHAR(100) NULL,
    [date_report_submit] VARCHAR(100) NULL,
    [time_report_submit] VARCHAR(100) NULL,
    [last_update_date] VARCHAR(100) NULL,
    [last_update_time] VARCHAR(100) NULL,
    [update_due_date] VARCHAR(100) NULL,
    [revision_due_date] VARCHAR(100) NULL,
    [sor_level] VARCHAR(100) NULL,
    [media_attention] VARCHAR(100) NULL,
    [num_individuals] VARCHAR(100) NULL,
    [num_unique_individuals] VARCHAR(100) NULL,
    [num_unique_categories] VARCHAR(100) NULL,
    [categories] VARCHAR(300) NULL
);
GO

IF OBJECT_ID(N'bronze.SO_category', N'U') IS NULL
CREATE TABLE bronze.SO_category(
    [site_id] VARCHAR(100) NULL,
    [site_name] VARCHAR(200) NULL,
    [related_OPR] VARCHAR(100) NULL,
    [sor_id] VARCHAR(100) NULL,
    [confidential_sor] VARCHAR(100) NULL,
    [status] VARCHAR(100) NULL,
    [sor_initiator] VARCHAR(100) NULL,
    [date_time_serious_occur] VARCHAR(100) NULL,
    [date_time_report_submit] VARCHAR(100) NULL,
    [last_update_date_time] VARCHAR(100) NULL,
    [sor_level] VARCHAR(100) NULL,
    [media_attention] VARCHAR(100) NULL,
    [category] VARCHAR(200) NULL,
    [sub_category] VARCHAR(200) NULL,
    [type] VARCHAR(300) NULL,
    [claim] VARCHAR(100) NULL,
    [role] VARCHAR(200) NULL,
    [category_level] VARCHAR(100) NULL,
    [location] VARCHAR(200) NULL,
    [client_id] VARCHAR(100) NULL,
    [client_DOB] VARCHAR(100) NULL,
    [client_age] VARCHAR(100) NULL,
    [YOTIS] VARCHAR(100) NULL,
    [DSCIS] VARCHAR(200) NULL,
    [CPIN] VARCHAR(100) NULL,
    [guardian_status] VARCHAR(2000) NULL,
    [CSC] VARCHAR(100) NULL,
    [ISC] VARCHAR(100) NULL,
    [TCA] VARCHAR(100) NULL,
    [cont_for_youth] VARCHAR(100) NULL,
    [customary_care] VARCHAR(100) NULL,
    [parent_guardian_care] VARCHAR(100) NULL,
    [indep_adult] VARCHAR(100) NULL,
    [office_guardian_trustee] VARCHAR(100) NULL,
    [other] VARCHAR(100) NULL,
    [program] VARCHAR(200) NULL,
    [YP_factors] VARCHAR(100) NULL,
    [OC] VARCHAR(100) NULL,
    [OD] VARCHAR(100) NULL,
    [SC] VARCHAR(100) NULL,
    [SD] VARCHAR(100) NULL,
    [PB] VARCHAR(100) NULL,
    [PD] VARCHAR(100) NULL,
    [EM] VARCHAR(100) NULL,
    [ES] VARCHAR(100) NULL,
    [CP] VARCHAR(100) NULL,
    [provider_notification] VARCHAR(300) NULL,
    [noti_coroner] VARCHAR(100) NULL,
    [noti_ombudsman] VARCHAR(100) NULL,
    [noti_parent_guardian] VARCHAR(100) NULL,
    [noti_local_health] VARCHAR(100) NULL,
    [noti_placing_agency] VARCHAR(100) NULL,
    [noti_police] VARCHAR(100) NULL,
    [noti_other_ministry] VARCHAR(100) NULL,
    [noti_emergency_DS] VARCHAR(100) NULL,
    [noti_other] VARCHAR(100) NULL
);
GO

IF OBJECT_ID(N'silver.SO_status', N'U') IS NULL
CREATE TABLE silver.SO_status(
    [site_id] VARCHAR(100) NULL,
    [site_name] VARCHAR(200) NULL,
    [non_funded_licensed_OPR] VARCHAR(100) NULL,
    [sor_id] VARCHAR(100) NOT NULL,
    [confidential_sor] VARCHAR(100) NULL,
    [status] VARCHAR(100) NULL,
    [sor_initiator] VARCHAR(100) NULL,
    [date_serious_occur] DATE NULL,
    [time_serious_occur] TIME(0) NULL,
    [date_report_submit] DATE NULL,
    [time_report_submit] TIME(0) NULL,
    [last_update_date] DATE NULL,
    [last_update_time] TIME(0) NULL,
    [update_due_date] DATE NULL,
    [revision_due_date] DATE NULL,
    [sor_level] VARCHAR(100) NULL,
    [media_attention] VARCHAR(100) NULL,
    [num_individuals] INT NULL,
    [num_unique_individuals] INT NULL,
    [num_unique_categories] INT NULL,
    [categories] VARCHAR(300) NULL,
    CONSTRAINT PK_SO_status PRIMARY KEY (sor_id),
    CONSTRAINT CK_SO_status_num_individuals CHECK ([num_individuals] >= 0),
    CONSTRAINT CK_SO_status_num_unique_individuals CHECK ([num_unique_individuals] >= 0),
    CONSTRAINT CK_SO_status_num_unique_categories CHECK ([num_unique_categories] >= 0)
);
GO

IF OBJECT_ID(N'silver.SO_category', N'U') IS NULL
CREATE TABLE silver.SO_category(
    [site_id] VARCHAR(100) NULL,
    [site_name] VARCHAR(200) NULL,
    [related_OPR] VARCHAR(100) NULL,
    [sor_id] VARCHAR(100) NOT NULL,
    [confidential_sor] VARCHAR(100) NULL,
    [status] VARCHAR(100) NULL,
    [sor_initiator] VARCHAR(100) NULL,
    [date_time_serious_occur] DATETIME2(0) NULL,
    [date_time_report_submit] DATETIME2(0) NULL,
    [last_update_date_time] DATETIME2(0) NULL,
    [sor_level] VARCHAR(100) NULL,
    [media_attention] VARCHAR(100) NULL,
    [category] VARCHAR(200) NULL,
    [sub_category] VARCHAR(200) NULL,
    [type] VARCHAR(300) NULL,
    [claim] VARCHAR(100) NULL,
    [role] VARCHAR(200) NULL,
    [category_level] VARCHAR(100) NULL,
    [location] VARCHAR(200) NULL,
    [client_id] VARCHAR(100) NULL,
    [client_DOB] DATE NULL,
    [client_age] INT NULL,
    [YOTIS] VARCHAR(100) NULL,
    [DSCIS] VARCHAR(200) NULL,
    [CPIN] VARCHAR(100) NULL,
    [guardian_status] VARCHAR(2000) NULL,
    [CSC] VARCHAR(100) NULL,
    [ISC] VARCHAR(100) NULL,
    [TCA] VARCHAR(100) NULL,
    [cont_for_youth] VARCHAR(100) NULL,
    [customary_care] VARCHAR(100) NULL,
    [parent_guardian_care] VARCHAR(100) NULL,
    [indep_adult] VARCHAR(100) NULL,
    [office_guardian_trustee] VARCHAR(100) NULL,
    [other] VARCHAR(100) NULL,
    [program] VARCHAR(200) NULL,
    [YP_factors] VARCHAR(100) NULL,
    [OC] VARCHAR(100) NULL,
    [OD] VARCHAR(100) NULL,
    [SC] VARCHAR(100) NULL,
    [SD] VARCHAR(100) NULL,
    [PB] VARCHAR(100) NULL,
    [PD] VARCHAR(100) NULL,
    [EM] VARCHAR(100) NULL,
    [ES] VARCHAR(100) NULL,
    [CP] VARCHAR(100) NULL,
    [provider_notification] VARCHAR(300) NULL,
    [noti_coroner] VARCHAR(100) NULL,
    [noti_ombudsman] VARCHAR(100) NULL,
    [noti_parent_guardian] VARCHAR(100) NULL,
    [noti_local_health] VARCHAR(100) NULL,
    [noti_placing_agency] VARCHAR(100) NULL,
    [noti_police] VARCHAR(100) NULL,
    [noti_other_ministry] VARCHAR(100) NULL,
    [noti_emergency_DS] VARCHAR(100) NULL,
    [noti_other] VARCHAR(100) NULL,
    CONSTRAINT FK_SO_category_status FOREIGN KEY (sor_id) REFERENCES silver.SO_status(sor_id),
    CONSTRAINT CK_SO_category_client_age CHECK ([client_age] >= 0)
);
GO
