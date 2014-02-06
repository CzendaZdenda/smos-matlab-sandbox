-- Function: public.interpol2(numeric, numeric, numeric, numeric, numeric)

-- DROP FUNCTION public.interpol2(numeric, numeric, numeric, numeric, numeric);

CREATE OR REPLACE FUNCTION public.interpol2(x0 numeric, y0 numeric, x1 numeric, y1 numeric, x numeric)
  RETURNS numeric AS
$BODY$
	SELECT ($4-$2)*($5-$1)/($3-$1) + $2
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION public.interpol2(numeric, numeric, numeric, numeric, numeric)
  OWNER TO postgres;
COMMENT ON FUNCTION public.interpol2(numeric, numeric, numeric, numeric, numeric) IS 'get y value';

-- Function: public.gettimeseriedata(numeric, date, integer, integer)

-- DROP FUNCTION public.gettimeseriedata(numeric, date, integer, integer);

CREATE OR REPLACE FUNCTION public.gettimeseriedata(numeric, date, integer, integer)
  RETURNS numeric AS
$BODY$
DECLARE
	x0 numeric; --double precision;
	y0 numeric; --double precision;
	x1 numeric; --double precision;
	y1 numeric; --double precision;
	x  numeric; --double precision;
	y  numeric; --double precision;
BEGIN
	SELECT INTO x0, y0 incidence_angle, bt_real 
	FROM smos_records
	   WHERE grid_point_id = $4 AND observ_date = $2 AND incidence_angle <= $1 AND polarization = $3
	   ORDER BY incidence_angle desc
	   LIMIT 1;

	SELECT INTO x1, y1 incidence_angle, bt_real 
	FROM smos_records
	   WHERE grid_point_id = $4 AND observ_date = $2 AND incidence_angle >= $1  AND polarization = $3
	   ORDER BY incidence_angle
	   LIMIT 1;

	SELECT INTO y interpol2(x0, y0, x1, y1, $1);

	RETURN y;
	--RETURN 'BT at ' || $1 || ' := ' || y || ' <= [' || x0 || ',' || y0 || '], [' || x1 || ',' || y1 || ']';
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
ALTER FUNCTION public.gettimeseriedata(numeric, date, integer, integer)
  OWNER TO postgres;
