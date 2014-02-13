-- Function: public.gettimeseriedata1(numeric, date, integer, integer)

-- DROP FUNCTION public.gettimeseriedata1(numeric, date, integer, integer);

CREATE OR REPLACE FUNCTION public.gettimeseriedata1(numeric, date, integer, integer)
  RETURNS numeric AS
$BODY$
DECLARE
	x0 numeric;
	y0 numeric;
	x1 numeric;
	y1 numeric;
	x  numeric;
	y  numeric;
BEGIN
	SELECT INTO x0, y0 incidence_angle, bt_real 
	FROM smos_records
	   WHERE grid_point_id = $4 
	   AND date_trunc('day', observ_date) = $2
	   AND incidence_angle <= $1 AND polarization = $3
	   ORDER BY incidence_angle desc
	   LIMIT 1;

	SELECT INTO x1, y1 incidence_angle, bt_real 
	FROM smos_records
	   WHERE grid_point_id = $4 
	   AND date_trunc('day', observ_date) = $2
	   AND incidence_angle >= $1  
	   AND polarization = $3
	   ORDER BY incidence_angle asc
	   LIMIT 1;

	SELECT INTO y interpol2(x0, y0, x1, y1, $1);

	RETURN y;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
ALTER FUNCTION public.gettimeseriedata1(numeric, date, integer, integer)
  OWNER TO postgres;
