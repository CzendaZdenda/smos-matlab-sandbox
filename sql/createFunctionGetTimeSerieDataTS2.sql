-- Function: public.gettimeseriedatats2(numeric, timestamp without time zone, integer, integer)

-- DROP FUNCTION public.gettimeseriedatats2(numeric, timestamp without time zone, integer, integer);

CREATE OR REPLACE FUNCTION public.gettimeseriedatats2(numeric, timestamp without time zone, integer, integer)
  RETURNS numeric AS
$BODY$
DECLARE
	x0 numeric;
	y0 numeric;
	x1 numeric;
	y1 numeric;
	ts timestamp;
	foo double precision;
	x  numeric;
	y  numeric;
BEGIN
	SELECT INTO ts, foo observ_date, abs( EXTRACT( epoch FROM observ_date - $2) ) as diff 
	FROM smos_records 
	WHERE grid_point_id = $4 
	AND date_trunc('day', observ_date) = date_trunc('day', $2)
	GROUP BY observ_date
	ORDER BY diff ASC
	LIMIT 1;

	SELECT INTO x0, y0 incidence_angle, bt_real 
	FROM smos_records
	   WHERE grid_point_id = $4 
	   AND observ_date = ts 
	   AND polarization = $3
	   ORDER BY abs(incidence_angle - $1) asc
	   LIMIT 1;

	SELECT INTO x1, y1 incidence_angle, bt_real 
	FROM smos_records
	   WHERE grid_point_id = $4 
	   AND observ_date = ts 
	   AND polarization = $3
	   AND incidence_angle <> x0
	   ORDER BY abs(incidence_angle - $1) asc
	   LIMIT 1;

	SELECT INTO y interpol2(x0, y0, x1, y1, $1);

	RETURN y;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
ALTER FUNCTION public.gettimeseriedatats2(numeric, timestamp without time zone, integer, integer)
  OWNER TO postgres;
