--IDENTIFY OUT OF RANGE DATES
SELECT DISTINCT bdate FROM silver.erp_cust_az12
WHERE bdate<'1924-01-01' and bdate>GETDATE();

--Data Standardization & Consistency
select DISTINCT gen from silver.erp_cust_az12;

--Transformations Done:
--Handling Invalid values --Remove NAS prefix if present
--SET future birthdates to NULL
--Normalize gender values & handle uknown cases