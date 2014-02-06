COPY smos_test_csv_import FROM '<PATH>\<FILE>' CSV HEADER DELIMITER ';';

select count(*) from smos_test_csv_import;
select pg_size_pretty(pg_total_relation_size('smos_test_csv_import'));

REINDEX TABLE smos_bt_point

/*
START TRANSACTION
delete from smos_records where observ_date = '2010-01-17'
ROLLBACK 
COMMIT
*/

select i from generate_series(1,4) g(i);

--COMMENT ON FUNCTION interpol2( x0 numeric, y0 numeric, x1 numeric, y1 numeric, x numeric ) IS 'get y value'

