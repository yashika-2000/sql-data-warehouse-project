--Data Standardization & Consistency
select DISTINCT cntry from silver.erp_loc_a101 order by cntry;

select * from silver.erp_loc_a101;

--Transformations Done:
--Normalize & Handle missing or blank country codes