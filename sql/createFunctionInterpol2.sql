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
