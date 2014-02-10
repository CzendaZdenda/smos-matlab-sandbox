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

