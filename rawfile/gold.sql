Select * from silver.crm_cust_info;

SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date
from silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key=la.cid;

--TO CHECK DUPLICATES AFTER JOINING TABLES
SELECT cst_id,COUNT(*) FROM 
(SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date
from silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key=la.cid)t
GROUP BY cst_id
HAVING COUNT(*)>1;
--NO DUPLICATES FOUND

--WE HAVE 2 GENDERS ONE FROM CUST_INFO,OTHER FROM ERP_CUST_AZ12
SELECT DISTINCT 
	ci.cst_gndr,
	ca.gen
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key=la.cid ORDER BY 1,2;

--NULLS OFTEN COME IF SQL FINDS NO MATCH
--THERE ARE CUSTOMERS THAT ARE THERE IN CRM BUT NOT IN ERP

--BUT THE MASTER SOURCE OF DATA IS CRM
SELECT DISTINCT ci.cst_gndr,ca.gen,
CASE WHEN ci.cst_gndr!='N/A' THEN ci.cst_gndr
	 ELSE COALESCE(ca.gen,'N/A')
END AS new_gen
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key=la.cid ;

--NEW GEN IS CORRECT NOW
--FINAL QUERY
SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	cst_marital_status,
	CASE WHEN ci.cst_gndr!='N/A' THEN ci.cst_gndr
		 ELSE COALESCE(ca.gen,'N/A')
	END AS new_gen,
	ci.cst_create_date,
	ca.bdate,
	la.cntry
from silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key=la.cid;


--RENAME & SORT COLUMNS

SELECT 
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_name,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr!='N/A' THEN ci.cst_gndr
		 ELSE COALESCE(ca.gen,'N/A')
	END AS gender,
	ca.bdate AS birth_date,
	ci.cst_create_date AS create_date
from silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key=la.cid;


--Adding a surrogate key 
--To connect Data models & reduce dependency on source system
--DDL Based generation
--Query based using Window function

--SELECT ROW_NUMBER() OVER (ORDERBY cst_id) AS customer_key

--Create virtual objects in gold layer

CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_name,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr!='N/A' THEN ci.cst_gndr
		 ELSE COALESCE(ca.gen,'N/A')
	END AS gender,
	ca.bdate AS birth_date,
	ci.cst_create_date AS create_date
from silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key=la.cid;


--QUALITY CHECK OF THE GOLD TABLE
SELECT * FROM gold.dim_customers;
SELECT DISTINCT gender FROM gold.dim_customers;



--CREATE DIMENSION products using crm.prd_info & erp.px_cat_g1v2

SELECT pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
pn.prd_end_dt,
pc.cat,
pc.subcat,
pc.maintenance
from silver.crm_prd_info pn
LEFT JOIN  silver.erp_px_cat_g1v2 pc 
ON pn.cat_id=pc.id
WHERE prd_end_dt IS NULL;  --FILTER OUT ALL HISTORICAL DATA
--IF END DATE IS NULL THEN IT IS THE CURRENT INFO OF THE PRODUCT

--QUALITY CHECK OF GOLD LAYER
SELECT prd_key,COUNT(*) from (SELECT pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
pn.prd_end_dt,
pc.cat,
pc.subcat,
pc.maintenance
from silver.crm_prd_info pn
LEFT JOIN  silver.erp_px_cat_g1v2 pc 
ON pn.cat_id=pc.id
WHERE prd_end_dt IS NULL)t GROUP BY prd_key HAVING COUNT(*)>1;
--NO DATA EXISTS

--FINAL QUERY
SELECT pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm AS product_name,
pc.cat AS category,
pc.subcat AS subcategory,
pc.maintenance AS maintenance,
pn.prd_cost AS cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS start_date
--pn.prd_end_dt AS 
from silver.crm_prd_info pn
LEFT JOIN  silver.erp_px_cat_g1v2 pc 
ON pn.cat_id=pc.id
WHERE prd_end_dt IS NULL;


--CREATING A SURROGATE KEY FOR THE DIMENSION PRODUCTS
SELECT ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_key) AS product_key,
pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm AS product_name,
pc.cat AS category,
pc.subcat AS subcategory,
pc.maintenance AS maintenance,
pn.prd_cost AS cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS start_date
--pn.prd_end_dt AS 
from silver.crm_prd_info pn
LEFT JOIN  silver.erp_px_cat_g1v2 pc 
ON pn.cat_id=pc.id
WHERE prd_end_dt IS NULL;

CREATE VIEW gold.dim_products AS
SELECT ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_key) AS product_key,
pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm AS product_name,
pc.cat AS category,
pc.subcat AS subcategory,
pc.maintenance AS maintenance,
pn.prd_cost AS cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS start_date
--pn.prd_end_dt AS 
from silver.crm_prd_info pn
LEFT JOIN  silver.erp_px_cat_g1v2 pc 
ON pn.cat_id=pc.id
WHERE prd_end_dt IS NULL;

SELECT * FROM gold.dim_products; 

--CREATE FACT SALES
Select * from silver.crm_sales_details;
SELECT sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details sd;


--FACTS:- Keys, dates, measures
--Using Dimension's surrogate keys instead of ID's  to easily connect facts with dimensions
--Original ID's sls_prd_key,sls_cust_id
--The process of looking silver layer with Gold layer for Original ID' with Surrogate Keys is called Data Lookup
SELECT sls_ord_num,
--sls_prd_key, --remove
pr.product_key,
--sls_cust_id, --remove
cu.customer_key,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key=pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id=cu.customer_id;


--NOW WE HAVE DIMENSION KEYS IN FACT TABLE
--RENAME COLUMNS
SELECT sls_ord_num AS order_number,
pr.product_key,
cu.customer_key,
sls_order_dt AS order_date,
sls_ship_dt AS shipping_date,
sls_due_dt AS due_dt,
sls_sales AS sales_amount,
sls_quantity AS quantity,
sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key=pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id=cu.customer_id;


--FINAL QUERY
CREATE VIEW gold.fact_sales AS
SELECT sls_ord_num AS order_number,
pr.product_key,
cu.customer_key,
sls_order_dt AS order_date,
sls_ship_dt AS shipping_date,
sls_due_dt AS due_dt,
sls_sales AS sales_amount,
sls_quantity AS quantity,
sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key=pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id=cu.customer_id;


--CHECK QUALITY OF GOLD TABLE
Select * from gold.fact_sales;

--FOREIGN KEY INTEGRITY(Dimensions)
--FACT TABLE CHECK
SELECT * FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
 ON c.customer_key=f.customer_key
 LEFT JOIN gold.dim_products p
 ON p.product_key=f.product_key
 WHERE p.product_key IS NULL;


