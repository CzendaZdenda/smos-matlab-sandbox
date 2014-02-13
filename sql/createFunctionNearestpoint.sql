-- Function: public.nearestpoint(numeric, numeric)

-- DROP FUNCTION public.nearestpoint(numeric, numeric);

CREATE OR REPLACE FUNCTION public.nearestpoint(lat numeric, lon numeric)
  RETURNS integer AS
$BODY$
	select smos_id           -- !!!!! CHANGE !!!!!
	from points 
	order by ST_Distance(smos_point, ST_SetSRID(ST_MakePoint(lon,lat),4326))
	limit 1
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION public.nearestpoint(numeric, numeric)
  OWNER TO postgres;
