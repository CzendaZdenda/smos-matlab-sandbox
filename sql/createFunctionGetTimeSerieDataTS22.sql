-- Function: public.gettimeseriedatats22(numeric, timestamp without time zone, integer, integer)

-- DROP FUNCTION public.gettimeseriedatats22(numeric, timestamp without time zone, integer, integer);

CREATE OR REPLACE FUNCTION public.gettimeseriedatats22(numeric, timestamp without time zone, integer, integer)
  RETURNS text AS
$BODY$
DECLARE
	a iabt[]; -- create type iabt as (ia double precision, bt double precision);
	x0 numeric;
	y0 numeric;
	x1 numeric;
	y1 numeric;
	ts timestamp;
	foo double precision;
	x  numeric;
BEGIN
	SELECT INTO ts, foo observ_date, abs( EXTRACT( epoch FROM observ_date - $2) ) as diff 
	FROM smos_records 
	WHERE grid_point_id = $4 
	AND date_trunc('day', observ_date) = date_trunc('day', $2)
	GROUP BY observ_date
	ORDER BY diff ASC
	LIMIT 1;

	a := array(SELECT row(incidence_angle, bt_real) FROM smos_records WHERE grid_point_id = $4 AND observ_date = ts  AND polarization = $3 
		ORDER BY abs(incidence_angle - $1) asc 
		LIMIT 2);
		
	x0 := a[1].ia;
	x1 := a[2].ia;
	y0 := a[1].bt;
	y1 := a[2].bt;

	RETURN interpol2(x0, y0, x1, y1, $1);
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
ALTER FUNCTION public.gettimeseriedatats22(numeric, timestamp without time zone, integer, integer)
  OWNER TO postgres;
