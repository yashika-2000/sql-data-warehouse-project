--CHECK 1
--CHECK FOR NULLS & DUPLICATES IN PRIMARY KEY
--EXPECTATION: NO RESULT
Select cst_id,COUNT(*) 
from silver.crm_cust_info 
GROUP BY cst_id 
HAVING COUNT(*)>1 OR cst_id IS NULL;


--CHECK 2
--CHECK FOR UNWANTED SPACES
--cst_firstname
SELECT cst_firstname FROM silver.crm_cust_info WHERE cst_firstname!=TRIM(cst_firstname);
--cst_lastname
SELECT cst_lastname FROM silver.crm_cust_info WHERE cst_lastname!=TRIM(cst_lastname);
--cst_gndr
SELECT cst_gndr FROM silver.crm_cust_info WHERE cst_gndr!=TRIM(cst_gndr);
--cst_marital_status
SELECT cst_marital_status FROM bronze.crm_cust_info WHERE cst_marital_status!=TRIM(cst_marital_status);
--cst_key
SELECT cst_key FROM bronze.crm_cust_info WHERE cst_key!=TRIM(cst_key)


--CHECK 3
--DATA STANDARDIZATION & CONSISTENCY
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info;
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;

