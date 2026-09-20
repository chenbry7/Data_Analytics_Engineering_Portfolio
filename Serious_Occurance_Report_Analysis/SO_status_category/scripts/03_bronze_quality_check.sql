--bronze.SO_status

SELECT *
FROM bronze.SO_status;


SELECT site_id
FROM bronze.SO_status
WHere site_id != TRIM(site_id)


SELECT site_name,TRIM(site_name)
FROM bronze.SO_status
WHere site_name != TRIM(site_name)


SELECT non_funded_licensed_OPR
FROM bronze.SO_status
WHERE UPPER(TRIM(non_funded_licensed_OPR)) = 'Y'


SELECT sor_id
FROM bronze.SO_status
WHere sor_id != TRIM(sor_id)


SELECT DISTINCT confidential_sor
FROM bronze.SO_status


SELECT DISTINCT "status"
FROM bronze.SO_status

SELECT "status"
FROM bronze.SO_status
where "status" != TRIM(status)


SELECT DISTINCT sor_initiator
FROM bronze.SO_status

SELECT sor_initiator
FROM bronze.SO_status
where sor_initiator != trim(sor_initiator)


SELECT date_serious_occur,date_report_submit,last_update_date
FROM bronze.SO_status
WHERE date_serious_occur > date_report_submit OR date_serious_occur > last_update_date


SELECT DISTINCT sor_level
FROM BRONZE.SO_status


SELECT DISTINCT media_attention
FROM BRONZE.SO_status


SELECT DISTINCT num_individuals
FROM BRONZE.SO_status


SELECT DISTINCT num_unique_individuals
FROM BRONZE.SO_status


SELECT DISTINCT num_unique_categories
FROM BRONZE.SO_status


SELECT DISTINCT categories
FROM bronze.SO_status;




select distinct update_due_date
from bronze.SO_status
--WHERE update_due_date = ''

--------------------------------------------------
--------------------------------------------------

-- bronze.SO_category
SELECT *
FROM bronze.SO_category;

select distinct related_OPR
from bronze.SO_category

select distinct category
from bronze.SO_category

select distinct sub_category
from bronze.SO_category

select distinct "type"
from bronze.SO_category

select distinct claim
from bronze.SO_category

select distinct "role"
from bronze.SO_category

select distinct category_level
from bronze.SO_category

select distinct "location"
from bronze.SO_category

select distinct client_age
from bronze.SO_category

select distinct YOTIS
from bronze.SO_category
where YOTIS = ''

select distinct CPIN
from bronze.SO_category

select distinct guardian_status
from bronze.SO_category

select distinct program
from bronze.SO_category

select distinct YP_factors
from bronze.SO_category

select distinct provider_notification
from bronze.SO_category

