select * from bronze.crm_cust_info;
--CHECK 1
--CHECK FOR NULLS & DUPLICATES IN PRIMARY KEY
--EXPECTATION: NO RESULT
Select cst_id,COUNT(*) from bronze.crm_cust_info GROUP BY cst_id HAVING COUNT(*)>1 OR cst_id IS NULL;

--AS DATA EXISTS WE NEED TO CLEAN & TRANSFORM THIS
SELECT * FROM BRONZE.crm_cust_info WHERE cst_id=29466;

--APPLYING WINDOW FUNCTION ROW_NUMBER()
SELECT *,ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last FROM bronze.crm_cust_info WHERE cst_id=29466;

SELECT *,ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last FROM bronze.crm_cust_info;

--NULLS & DUPLICATES TO BE REMOVED
SELECT * FROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last FROM bronze.crm_cust_info)t WHERE flag_last!=1;

--CHECK 2
--CHECK FOR UNWANTED SPACES
--cst_firstname
SELECT cst_firstname FROM bronze.crm_cust_info WHERE cst_firstname!=TRIM(cst_firstname);
--cst_lastname
SELECT cst_lastname FROM bronze.crm_cust_info WHERE cst_lastname!=TRIM(cst_lastname);
--cst_gndr
SELECT cst_gndr FROM bronze.crm_cust_info WHERE cst_gndr!=TRIM(cst_gndr);
--cst_marital_status
SELECT cst_marital_status FROM bronze.crm_cust_info WHERE cst_marital_status!=TRIM(cst_marital_status);
--cst_key
SELECT cst_key FROM bronze.crm_cust_info WHERE cst_key!=TRIM(cst_key)

--Final query
SELECT cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname) as cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date FROM 
(SELECT *,ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL)t WHERE flag_last=1;

--CHECK 3
--DATA STANDARDIZATION & CONSISTENCY
SELECT DISTINCT cst_gndr FROM bronze.crm_cust_info;
SELECT DISTINCT cst_marital_status FROM bronze.crm_cust_info;

--Final query
SELECT cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname) as cst_lastname,
CASE WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'Single'
	 WHEN UPPER(TRIM(cst_marital_status))='M' THEN 'Married'
	 ELSE 'N/A'
END cst_marital_status,
CASE WHEN UPPER(TRIM(cst_gndr))='M' THEN 'Male'
	 WHEN UPPER(TRIM(cst_gndr))='F' THEN 'Female'
	 ELSE 'N/A'
END cst_gndr,
cst_create_date FROM 
(SELECT *,ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last 
FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL)t WHERE flag_last=1;


