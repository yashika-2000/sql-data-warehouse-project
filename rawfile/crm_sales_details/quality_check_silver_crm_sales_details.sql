--Order Date must always be earlier than the shipping date or due date
--CHECK FOR INVALID DATES
SELECT * FROM silver.crm_sales_details WHERE sls_order_dt>sls_ship_dt OR sls_order_dt>sls_due_dt;

--DATA STANDARDIZATION
Select DISTINCT sls_sales,sls_quantity,sls_price
from silver.crm_sales_details WHERE sls_sales!=sls_quantity*sls_price OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales<=0 OR sls_quantity<=0 OR sls_price<=0 ORDER BY sls_sales,sls_quantity,sls_price;


select * from silver.crm_sales_details;

--Transformations Done:
--date : Handling Invalid data,data type casting
--sales : Handling missing & Invalid data by deriving data from existing ones
