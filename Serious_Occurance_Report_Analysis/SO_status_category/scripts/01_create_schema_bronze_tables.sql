USE MyDatabase
GO

-- Create Schema 'bronze','silver', and 'gold'
CREATE Schema bronze;
GO
CREATE Schema silver;
GO
CREATE Schema gold;
GO

----------------------------------------------
-- create table bronze.SO_status
IF OBJECT_ID('bronze.SO_status', 'U') IS NOT NULL
	DROP TABLE bronze.SO_status;

CREATE TABLE bronze.SO_status(
site_id VARCHAR(100) NULL, 
site_name VARCHAR(200) NULL,
non_funded_licensed_OPR VARCHAR(100) NULL,
sor_id VARCHAR(100) NULL,
confidential_sor VARCHAR(100) NULL,
"status" VARCHAR(100) NULL,
sor_initiator VARCHAR(100) NULL,
date_serious_occur VARCHAR(100) NULL,
time_serious_occur VARCHAR(100) NULL,
date_report_submit VARCHAR(100) NULL,
time_report_submit VARCHAR(100) NULL,
last_update_date VARCHAR(100) NULL,
last_update_time VARCHAR(100) NULL,
update_due_date VARCHAR(100) NULL,
revision_due_date VARCHAR(100) NULL,
sor_level VARCHAR(100) NULL,
media_attention VARCHAR(100) NULL,
num_individuals VARCHAR(100) NULL,
num_unique_individuals VARCHAR(100) NULL,
num_unique_categories VARCHAR(100) NULL,
categories VARCHAR(300) NULL,
);

SELECT * FROM bronze.SO_status


---- create table bronze.SO_category
IF OBJECT_ID('bronze.SO_category', 'U') IS NOT NULL
	DROP TABLE bronze.SO_category;

CREATE TABLE bronze.SO_category(
site_id VARCHAR(100) NULL, 
site_name VARCHAR(200) NULL,
related_OPR VARCHAR(100) NULL,
sor_id VARCHAR(100) NULL,
confidential_sor VARCHAR(100) NULL,
"status" VARCHAR(100) NULL,
sor_initiator VARCHAR(100) NULL,
date_time_serious_occur VARCHAR(100) NULL,
date_time_report_submit VARCHAR(100) NULL,
last_update_date_time VARCHAR(100) NULL,
sor_level VARCHAR(100) NULL,
media_attention VARCHAR(100) NULL,
category VARCHAR(200) NULL,
sub_category VARCHAR(200) NULL,
"type" VARCHAR(300) NULL,
claim VARCHAR(100) NULL,
"role" VARCHAR(200) NULL,
category_level VARCHAR(100) NULL,
"location" VARCHAR(200) NULL,
client_id VARCHAR(100) NULL,
client_DOB VARCHAR(100) NULL,
client_age VARCHAR(100) NULL,
YOTIS VARCHAR(100) NULL,
DSCIS VARCHAR(200) NULL,
CPIN VARCHAR(100) NULL,
guardian_status VARCHAR(2000) NULL,
CSC VARCHAR(100) NULL,
ISC VARCHAR(100) NULL,
TCA VARCHAR(100) NULL,
cont_for_youth VARCHAR(100) NULL,
customary_care VARCHAR(100) NULL,
parent_guardian_care VARCHAR(100) NULL,
indep_adult VARCHAR(100) NULL,
office_guardian_trustee VARCHAR(100) NULL,
other VARCHAR(100) NULL,
program VARCHAR(200) NULL,
YP_factors VARCHAR(100) NULL,
OC VARCHAR(100) NULL,
OD VARCHAR(100) NULL,
SC VARCHAR(100) NULL,
SD VARCHAR(100) NULL,
PB VARCHAR(100) NULL,
PD VARCHAR(100) NULL,
EM VARCHAR(100) NULL,
ES VARCHAR(100) NULL,
CP VARCHAR(100) NULL,
provider_notification VARCHAR(300) NULL,
noti_coroner VARCHAR(100) NULL,
noti_ombudsman VARCHAR(100) NULL,
noti_parent_guardian VARCHAR(100) NULL,
noti_local_health VARCHAR(100) NULL,
noti_placing_agency VARCHAR(100) NULL,
noti_police VARCHAR(100) NULL,
noti_other_ministry VARCHAR(100) NULL,
noti_emergency_DS VARCHAR(100) NULL,
noti_other VARCHAR(100) NULL
);

SELECT * FROM bronze.SO_category