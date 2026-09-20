CREATE OR ALTER PROCEDURE silver.load_status AS
BEGIN
	-- Insert into silver.SO_status
	PRINT '>> TRUNCATING Table: silver.SO_status'
	TRUNCATE TABLE silver.SO_status
	PRINT '>> Inserting Data into: silver.SO_status'
	INSERT INTO silver.SO_status(
	site_id, 
	site_name ,
	non_funded_licensed_OPR ,
	sor_id ,
	confidential_sor ,
	"status" ,
	sor_initiator ,
	date_serious_occur ,
	time_serious_occur ,
	date_report_submit ,
	time_report_submit ,
	last_update_date ,
	last_update_time ,
	update_due_date ,
	revision_due_date ,
	sor_level ,
	media_attention ,
	num_individuals ,
	num_unique_individuals ,
	num_unique_categories
	)
	SELECT
	site_id,
	TRIM(site_name) AS site_name,
	CASE WHEN UPPER(TRIM(non_funded_licensed_OPR)) = 'N' Then 'No'
		 WHEN UPPER(TRIM(non_funded_licensed_OPR)) = 'Y' Then 'Yes'
		 ELSE 'n/a'
	END AS non_funded_licensed_OPR,
	sor_id,
	confidential_sor,
	"status",
    sor_initiator,
	CASE WHEN date_serious_occur IS NULL THEN NULL
	     ELSE CAST(CAST(date_serious_occur AS VARCHAR) AS DATE)
	END AS date_serious_occur,
	CASE WHEN time_serious_occur IS NULL THEN NULL
	     ELSE CAST(CAST(time_serious_occur AS VARCHAR)AS TIME)
	END AS time_serious_occur,
	CASE WHEN date_report_submit IS NULL THEN NULL
	     ELSE CAST(CAST(date_report_submit AS VARCHAR)AS DATE)
	END AS date_report_submit,
	CASE WHEN time_report_submit IS NULL THEN NULL
	     ELSE CAST(CAST(time_report_submit AS VARCHAR) AS TIME)
	END AS time_report_submit,
	CASE WHEN last_update_date IS NULL THEN NULL
	     ELSE CAST(CAST(last_update_date AS VARCHAR) AS DATE)
	END AS last_update_date,
	CASE WHEN last_update_time IS NULL THEN NULL
	     ELSE CAST(CAST(last_update_time AS VARCHAR) AS TIME)
	END AS last_update_time,
	CASE WHEN update_due_date = ''  THEN NULL
	     ELSE CAST(CAST(update_due_date AS VARCHAR) AS DATE)
	END AS update_due_date,
	CASE WHEN revision_due_date = '' THEN NULL
	     ELSE CAST(CAST(revision_due_date AS VARCHAR)AS DATE)
	END AS revision_due_date,
	sor_level,
	CASE WHEN UPPER(TRIM(media_attention)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(media_attention)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS media_attention,
	num_individuals,
	num_unique_individuals,
	num_unique_categories
	FROM bronze.SO_status
	
END;
GO


	-- Insert into silver.SO_category
CREATE OR ALTER PROCEDURE silver.load_category AS
BEGIN
	PRINT '>> TRUNCATING Table: silver.SO_category'
	TRUNCATE TABLE silver.SO_category
	PRINT '>> Inserting Data into: silver.SO_category'
	INSERT INTO silver.SO_category(
	site_id, 
	site_name ,
	related_OPR ,
	sor_id ,
	confidential_sor ,
	"status" ,
	sor_initiator ,
	date_time_serious_occur ,
	date_time_report_submit ,
	last_update_date_time ,
	sor_level ,
	media_attention ,
	category ,
	sub_category ,
	"type" ,
	claim ,
	"role" ,
	category_level ,
	"location" ,
	client_id ,
	client_DOB ,
	client_age ,
	CPIN ,
	guardian_status ,
	CSC ,
	ISC ,
	TCA ,
	parent_guardian_care ,
	indep_adult ,
	program ,
	provider_notification ,
	noti_coroner ,
	noti_ombudsman ,
	noti_parent_guardian ,
	noti_local_health ,
	noti_placing_agency ,
	noti_police ,
	noti_other_ministry ,
	noti_emergency_DS ,
	noti_other 
	)
	SELECT
	site_id,
	TRIM(site_name) AS site_name,
	CASE WHEN UPPER(TRIM(related_OPR)) = 'N' Then 'No'
		 WHEN UPPER(TRIM(related_OPR)) = 'Y' Then 'Yes'
		 ELSE 'n/a'
	END AS related_OPR,
	sor_id,
	confidential_sor,
	"status",
    sor_initiator,
	CASE WHEN date_time_serious_occur IS NULL THEN NULL
	     ELSE CAST(CAST(date_time_serious_occur AS VARCHAR) AS DATETIME)
	END AS date_time_serious_occur,
	CASE WHEN date_time_report_submit IS NULL THEN NULL
	     ELSE CAST(CAST(date_time_report_submit AS VARCHAR)AS DATE)
	END AS date_time_report_submit,
	CASE WHEN last_update_date_time IS NULL THEN NULL
	     ELSE CAST(CAST(last_update_date_time AS VARCHAR) AS DATE)
	END AS last_update_date_time,
	sor_level,
	CASE WHEN UPPER(TRIM(media_attention)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(media_attention)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS media_attention,
	category,
	sub_category,
	CASE WHEN UPPER(TRIM("type")) = '' Then 'n/a'
		 ELSE "type"
	END AS "type",
	CASE WHEN UPPER(TRIM(claim)) = '' Then 'n/a'
		 ELSE claim
	END AS claim,
	CASE WHEN UPPER(TRIM("role")) = '' Then 'n/a'
		 ELSE "role"
	END AS "role",
	category_level,
	CASE WHEN "location" = 'At the service providerâ€™s site' Then 'At the service provider site'
		 ELSE "location"
	END AS "location",
	client_id,
	CASE WHEN client_DOB IS NULL THEN NULL
	     ELSE CAST(CAST(client_DOB AS VARCHAR) AS DATE)
	END AS client_DOB,
	CASE WHEN client_age = '' Then 'n/a'
		 ELSE client_age
	END AS client_age,
	CPIN,
	CASE WHEN guardian_status = '' Then 'n/a'
		 ELSE guardian_status
	END AS guardian_status,
	CASE WHEN UPPER(TRIM(CSC)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(CSC)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS CSC,
	CASE WHEN UPPER(TRIM(ISC)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(ISC)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS ISC,
	CASE WHEN UPPER(TRIM(TCA)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(TCA)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS TCA,
	CASE WHEN UPPER(TRIM(parent_guardian_care)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(parent_guardian_care)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS parent_guardian_care,
	CASE WHEN UPPER(TRIM(indep_adult)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(indep_adult)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS indep_adult,
	CASE WHEN program = '' Then 'n/a'
		 ELSE program
	END AS program,

	CASE WHEN provider_notification = '' Then 'n/a'
		 ELSE provider_notification
	END AS provider_notification,
	CASE WHEN UPPER(TRIM(noti_coroner)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(noti_coroner)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS noti_coroner,
	CASE WHEN UPPER(TRIM(noti_ombudsman)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(noti_ombudsman)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS noti_ombudsman,
	CASE WHEN UPPER(TRIM(noti_parent_guardian)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(noti_parent_guardian)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS noti_parent_guardian,
	CASE WHEN UPPER(TRIM(noti_local_health)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(noti_local_health)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS noti_local_health,
	CASE WHEN UPPER(TRIM(noti_placing_agency)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(noti_placing_agency)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS noti_placing_agency,
	CASE WHEN UPPER(TRIM(noti_police)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(noti_police)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS noti_police,
	CASE WHEN UPPER(TRIM(noti_other_ministry)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(noti_other_ministry)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS noti_other_ministry,
	CASE WHEN UPPER(TRIM(noti_emergency_DS)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(noti_emergency_DS)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS noti_emergency_DS,
	CASE WHEN UPPER(TRIM(noti_other)) = 'Y' Then 'Yes'
		 WHEN UPPER(TRIM(noti_other)) = 'N' Then 'No'
		 ELSE 'n/a'
	END AS noti_other

	FROM bronze.SO_category
END;
GO


--EXEC silver.load_status;
--GO

--EXEC silver.load_category;
--GO

--SELECT distinct site_name
--FROM silver.SO_status

--SELECT *
--FROM silver.SO_category