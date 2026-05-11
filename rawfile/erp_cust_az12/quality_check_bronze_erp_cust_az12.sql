select * from bronze.erp_cust_az12;

select 
	cid,
	bdate,
	gen 
from bronze.erp_cust_az12;


--erp_cust_az12(cid) ----> crm_cust_info(cst_key)

Select * from silver.crm_cust_info;

--cid [NAS	cst_key AW0001105]

SELECT * from bronze.erp_cust_az12 where cid like '%AW000%';
--There exists some data which contains NAS & some do not
--This may be due to old & new data

--REMOVING NAS from cid
SELECT cid,
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
	ELSE cid
END AS cid,
bdate,gen
FROM bronze.erp_cust_az12;

--CHECK IN cust_info
SELECT cid,
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
	ELSE cid
END AS cid,
bdate,gen
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
	ELSE cid
END NOT IN(SELECT DISTINCT cst_key FROM silver.crm_cust_info);
--NO UNMATCHED DATA

--bdate:IDENTIFY OUT OF RANGE DATES
--CHECK FOR VERY OLD CUSTOMER & BIRTH DATE IN FUTURE
SELECT DISTINCT bdate FROM bronze.erp_cust_az12
WHERE bdate<'1924-01-01' and bdate>GETDATE();
--DATE EXISTS FOR FUTURE --> INFORM TO SOURCE OR LEAVE IT
--REPLACE WITH NULL OR CURRENT DATE
SELECT 
CASE WHEN bdate>GETDATE() THEN NULL
	ELSE bdate
END AS bdate
FROM bronze.erp_cust_az12;

--gen: Find distinct gender values
SELECT DISTINCT gen FROM bronze.erp_cust_az12;
--Blank,NULL,F,M,Female,Male
SELECT
CASE WHEN UPPER(TRIM(gen)) IN ('F','Female') THEN 'FEMALE'
	 WHEN UPPER(TRIM(gen)) IN ('M','Male') THEN 'MALE'
	 ELSE 'N/A'
END AS gen
FROM bronze.erp_cust_az12;

--FINAL QUERY
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
	ELSE cid
END AS cid,
CASE WHEN bdate>GETDATE() THEN NULL
	ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F','Female') THEN 'FEMALE'
	 WHEN UPPER(TRIM(gen)) IN ('M','Male') THEN 'MALE'
	 ELSE 'N/A'
END AS gen
FROM bronze.erp_cust_az12;

--NO CHANGE IN DDL COMMAND

--INSERT DATA INTO SILVER LAYER
INSERT INTO silver.erp_cust_az12(
	cid,
	bdate,
	gen)
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
	ELSE cid
END AS cid,	--REMOVE 'NAS' PREFIX IF PRESENT
CASE WHEN bdate>GETDATE() THEN NULL
	ELSE bdate
END AS bdate,	--SET FUTURE BIRTHDATES TO NULL
CASE WHEN UPPER(TRIM(gen)) IN ('F','Female') THEN 'FEMALE'
	 WHEN UPPER(TRIM(gen)) IN ('M','Male') THEN 'MALE'
	 ELSE 'N/A'
END AS gen	--NORMALIZE GENDER VALUES & HANDLE UNKNOWN CASES
FROM bronze.erp_cust_az12;


