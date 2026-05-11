select * from bronze.crm_sales_details;

SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price 
FROM bronze.crm_sales_details;

--CHECK 1
--CHECK FOR UNWANTED SPACES
SELECT * FROM bronze.crm_sales_details WHERE sls_ord_num!=TRIM(sls_ord_num);
--No results -No Tranformtion Required


--prd_key & cst_id is connected with other tables
--Check prd_key in Sales Details & Prd info
SELECT * from bronze.crm_sales_details
where sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)
--All prd_key from sales_details can be connected to prd_key in prd info

--Check cust_id in sales_details & cust_info
SELECT * from bronze.crm_sales_details
where sls_cust_id NOT IN (SELECT sls_cust_id FROM silver.crm_cust_info)
--All prd_key from sales_details can be connected to prd_key in prd info
--No transformation required


--sls_ord_date,sls_ship_date,sls_due_dt  -->are integers not dates
--int --> Date
--Checking Quality of Dates
--Negative Numbers or Numbers can't be cast to dates
select sls_order_dt from bronze.crm_sales_details where sls_order_dt<=0;

--Replace zero with nulls
Select NULLIF(sls_order_dt,0) sls_order_dt from bronze.crm_sales_details where sls_order_dt<=0;

--20101229 length is 8
--12345678
Select NULLIF(sls_order_dt,0) sls_order_dt from bronze.crm_sales_details where sls_order_dt<=0 OR LEN(sls_order_dt)!=8;
--THESE EXISTS BUT WE CANNOT USE IT

--CHECK FOR OUTLIERS BY VALIDATING BOUNDARIES OF THE DATE RANGE
Select NULLIF(sls_order_dt,0) sls_order_dt from bronze.crm_sales_details where sls_order_dt>20500101 OR sls_order_dt<19000101;


--Final Query
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt=0 OR LEN(sls_order_dt)!=8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE)
END AS sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price 
FROM bronze.crm_sales_details;



--SAME APPLIED FOR sls_ship_dt,sls_due_dt
Select NULLIF(sls_ship_dt,0) sls_ship_dt from bronze.crm_sales_details where sls_ship_dt<=0 OR LEN(sls_ship_dt)!=8 OR sls_ship_dt>20500101 OR sls_ship_dt<19000101;
Select NULLIF(sls_due_dt,0) sls_due_dt from bronze.crm_sales_details where sls_due_dt<=0 OR LEN(sls_due_dt)!=8 OR sls_due_dt>20500101 OR sls_due_dt<19000101;

--Final Query
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt=0 OR LEN(sls_order_dt)!=8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE)
END AS sls_order_dt,
CASE WHEN sls_ship_dt=0 OR LEN(sls_ship_dt)!=8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE)
END AS sls_ship_dt,
CASE WHEN sls_due_dt=0 OR LEN(sls_due_dt)!=8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE)
END AS sls_due_dt,
sls_sales,
sls_quantity,
sls_price 
FROM bronze.crm_sales_details;

--Order Date must always be earlier than the shipping date or due date
--CHECK FOR INVALID DATES
SELECT * FROM bronze.crm_sales_details WHERE sls_order_dt>sls_ship_dt OR sls_order_dt>sls_due_dt;
--No Transformation Required

--Sales,Quantity,Price
--Business Rules Sales=Quantity* Price
--Negative,Zeroes,Nulls are Not Allowed
--CHECK DATA CONSISTENCY : BETWEEN SALES,QUANTITY & PRICES
--SALES=QUANTITY*PRICE
--VALUES MUST NOT BE NULL,ZERO,NEGATIVE NO.
Select DISTINCT sls_sales,sls_quantity,sls_price
from bronze.crm_sales_details WHERE sls_sales!=sls_quantity*sls_price OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales<=0 OR sls_quantity<=0 OR sls_price<=0 ORDER BY sls_sales,sls_quantity,sls_price;

--sls_sales : zeroes,nulls,negatives,wrong calculation
--sls_quantity : No zeroes,nulls,negatives
--sls_price : Nulls,Negative

--Solution 1: Source System Experts - Data Issues will be fixed direct in source system
--Solution 2: Data issues are to be fixed in DataWarehouse or left as it is
--We'll ask source system expert to help us correct it:-
--Rules:-
--If Sales is negative,zero or null derive it using quantity & price
--If price is zero or null,calculate it using sales & Qty
--If price is negative,convert it to positive value
SELECT DISTINCT
sls_sales AS old_sls_sales,sls_quantity,sls_price AS old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales!=sls_quantity*ABS(sls_price) THEN sls_quantity*ABS(sls_price) 
	ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price<=0 THEN sls_sales/NULLIF(sls_quantity,0)
	ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;

--FINAL QUERY
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt=0 OR LEN(sls_order_dt)!=8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE)
END AS sls_order_dt,
CASE WHEN sls_ship_dt=0 OR LEN(sls_ship_dt)!=8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE)
END AS sls_ship_dt,
CASE WHEN sls_due_dt=0 OR LEN(sls_due_dt)!=8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE)
END AS sls_due_dt,
sls_quantity,
CASE WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales!=sls_quantity*ABS(sls_price) THEN sls_quantity*ABS(sls_price) 
	ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price<=0 THEN sls_sales/NULLIF(sls_quantity,0)
	ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;

--CHANGE DDL COMMAND according to cleaned data
--Datatypes of Dates to DATE from INT


--FINAL INSERT DATA INTO SILVER LAYER TABLE
INSERT INTO silver.crm_sales_details(
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt=0 OR LEN(sls_order_dt)!=8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE)
END AS sls_order_dt,
CASE WHEN sls_ship_dt=0 OR LEN(sls_ship_dt)!=8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE)
END AS sls_ship_dt,
CASE WHEN sls_due_dt=0 OR LEN(sls_due_dt)!=8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE)
END AS sls_due_dt,
sls_quantity,
CASE WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales!=sls_quantity*ABS(sls_price) THEN sls_quantity*ABS(sls_price) 
	ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price<=0 THEN sls_sales/NULLIF(sls_quantity,0)
	ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;














