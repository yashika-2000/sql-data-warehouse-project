select * from bronze.erp_loc_a101;

select 
	cid,
	cntry
from bronze.erp_loc_a101;

--erp_loc_a101(cid) ----> crm_cust_info(cst_key)

Select cst_key from silver.crm_cust_info;

--cid  AW-00011000   cst_key AW00011000

SELECT REPLACE(cid,'-','') cid,cntry FROM bronze.erp_loc_a101;

--CHECK IN cust_info
SELECT REPLACE(cid,'-','') cid,cntry FROM bronze.erp_loc_a101
WHERE REPLACE(cid,'-','') 
NOT IN(SELECT DISTINCT cst_key FROM silver.crm_cust_info);
--NO UNMATCHED DATA


--cntry
--Data Standardization & & Consistency
SELECT DISTINCT cntry FROM bronze.erp_loc_a101;
--DE,USA,United Kingdom,Australia,NULL,blank,canada,France,Germany

SELECT
CASE WHEN TRIM(cntry)='DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry)='' OR cntry IS NULL THEN 'N/A'
	 WHEN TRIM(cntry)='DE' THEN 'Germany'
	 ELSE TRIM(cntry)
END AS cntry
from bronze.erp_loc_a101;

SELECT DISTINCT cntry AS old_cntry,
CASE WHEN TRIM(cntry)='DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry)='' OR cntry IS NULL THEN 'N/A'
	 WHEN TRIM(cntry)='DE' THEN 'Germany'
	 ELSE TRIM(cntry)
END AS cntry
from bronze.erp_loc_a101 order by cntry;

--NO CHANGE IN DDL COMMAND

--INSERT DATA INTO SILVER LAYER
INSERT INTO silver.erp_loc_a101(
cid,cntry)
SELECT 
REPLACE(cid,'-','') cid,
CASE WHEN TRIM(cntry)='DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry)='' OR cntry IS NULL THEN 'N/A'
	 WHEN TRIM(cntry)='DE' THEN 'Germany'
	 ELSE TRIM(cntry)
END AS cntry	--NORMALIZE & HANDLE BLANK OR MISSING COUNTRY CODES
from bronze.erp_loc_a101 order by cntry;