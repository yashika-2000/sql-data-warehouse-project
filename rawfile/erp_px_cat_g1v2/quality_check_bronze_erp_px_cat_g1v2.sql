select * from bronze.erp_px_cat_g1v2;

select 
	id,
	cat,
	subcat,
	maintenance
from bronze.erp_px_cat_g1v2;

--erp_px_cat_g1v2(id) ----> crm_prd_info(prd_key)

Select cat_id from silver.crm_prd_info;

--crm_prd_info(cat_id)		erp_px_cat_g1v2(id)

--CHECK IN prd_info
SELECT id,cat,subcat,maintenance FROM bronze.erp_px_cat_g1v2
WHERE id
NOT IN(SELECT DISTINCT cat_id FROM silver.crm_prd_info);
--CO_PD does not exists in prd_info

--cat-string

--CHECK FOR UNWANTED SPACES
Select * FROM bronze.erp_px_cat_g1v2
WHERE cat!=TRIM(cat) OR subcat!=TRIM(subcat) OR maintenance!=TRIM(maintenance)
--no transformation required

--Data Standardization & & Consistency
SELECT DISTINCT cat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT subcat FROM bronze.erp_px_cat_g1v2;
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;




--FINAL QUERY
select 
	id,
	cat,
	subcat,
	maintenance
from bronze.erp_px_cat_g1v2;

--NO CHANGE IN DDL COMMAND

--INSERT DATA INTO SILVER LAYER
INSERT INTO silver.erp_px_cat_g1v2(
id,cat,subcat,maintenance)
select 
	id,
	cat,
	subcat,
	maintenance
from bronze.erp_px_cat_g1v2;
