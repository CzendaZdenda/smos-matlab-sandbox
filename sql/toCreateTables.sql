-- Table: public.smos_records

-- DROP TABLE public.smos_records;

CREATE TABLE public.smos_records
(
  grid_point_id integer,
  observ_date date,
  bt_real double precision,
  bt_imag double precision,
  polarization integer,
  incidence_angle double precision,
  azimuth_angle double precision,
  pixel_radiometric_accuracy double precision,
  faraday_rotation_angle double precision,
  geometric_rotation_angle double precision,
  footprint_axis1 double precision,
  footprint_axis2 double precision,
  origin text,
  CONSTRAINT "grid_point_id_FK" FOREIGN KEY (grid_point_id)
      REFERENCES public.points (smos_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.smos_records
  OWNER TO smos;

-- Index: public."fki_grid_point_id_FK"

-- DROP INDEX public."fki_grid_point_id_FK";

CREATE INDEX "fki_grid_point_id_FK"
  ON public.smos_records
  USING btree
  (grid_point_id);

-- Index: public."observ_date_Idx"

-- DROP INDEX public."observ_date_Idx";

CREATE INDEX "observ_date_Idx"
  ON public.smos_records
  USING btree
  (observ_date);

-- Index: public."polarization_Idx"

-- DROP INDEX public."polarization_Idx";

CREATE INDEX "polarization_Idx"
  ON public.smos_records
  USING btree
  (polarization);


  -- Table: public.points

-- DROP TABLE public.points;

CREATE TABLE public.points
(
  smos_point geometry(Point,4326) NOT NULL,
  smos_id integer NOT NULL,
  CONSTRAINT "smos_id_PK" PRIMARY KEY (smos_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.points
  OWNER TO smos;

-- Index: public."smos_id_Idx"

-- DROP INDEX public."smos_id_Idx";

CREATE INDEX "smos_id_Idx"
  ON public.points
  USING btree
  (smos_id);

-- Index: public.smos_point

-- DROP INDEX public.smos_point;

CREATE INDEX smos_point
  ON public.points
  USING gist
  (smos_point);

