-- Table: public.smos_records

-- DROP TABLE public.smos_records;

CREATE TABLE public.smos_records
(
  observ_date timestamp without time zone,
  grid_point_id integer,
  lat double precision,
  lon double precision,
  bt_real double precision,
  bt_imag double precision,
  polarization integer,
  incidence_angle double precision,
  azimuth_angle double precision,
  faraday_rotation_angle double precision,
  geometric_rotation_angle double precision,
  footprint_axis1 double precision,
  footprint_axis2 double precision,
  pixel_radiometric_accuracy double precision
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.smos_records
  OWNER TO smos;

-- Index: public."date_Idx"

-- DROP INDEX public."date_Idx";

CREATE INDEX "observ_date_Idx"
  ON public.smos_records
  USING btree
  (observ_date);

-- Index: public."grid_point_id_Idx"

-- DROP INDEX public."grid_point_id_Idx";

CREATE INDEX "grid_point_id_Idx"
  ON public.smos_records
  USING btree
  (grid_point_id);

-- Index: public."polarization_Idx"

-- DROP INDEX public."polarization_Idx";

CREATE INDEX "polarization_Idx"
  ON public.smos_records
  USING btree
  (polarization);