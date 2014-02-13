--COPY smos_test_csv_import FROM 'D:\skola\phd\tym\project02\smos-matlab-sandbox\data\csv\SM_REPR_MIR_SCLF1C_20100116T053510_20100115T062822_505_001_1.csv' CSV HEADER DELIMITER ';';
--delete from points_test
select ST_AsText(smos_point) from points_test where smos_id = 17025
--select pg_size_pretty(pg_total_relation_size('smos_test'));
--SELECT pg_size_pretty(pg_database_size('smos'));

--REINDEX TABLE smos_bt_point

/*
START TRANSACTION
delete from smos_records where observ_date = '2010-01-17'
ROLLBACK 
COMMIT
*/

--select i from generate_series(1,4) g(i);

--COMMENT ON FUNCTION interpol2( x0 numeric, y0 numeric, x1 numeric, y1 numeric, x numeric ) IS 'get y value'

