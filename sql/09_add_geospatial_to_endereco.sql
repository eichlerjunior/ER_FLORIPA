CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE endereco 
ADD COLUMN IF NOT EXISTS geom GEOMETRY(Point, 4326),
ADD COLUMN IF NOT EXISTS geocode_source VARCHAR(50),
ADD COLUMN IF NOT EXISTS geocode_confidence NUMERIC(5,2);

CREATE INDEX IF NOT EXISTS idx_endereco_geom ON endereco USING GIST (geom);

ALTER TABLE endereco ADD COLUMN IF NOT EXISTS cep_clean CHAR(8);
UPDATE endereco SET cep_clean = regexp_replace(cep, '[^0-9]', '', 'g') WHERE cep IS NOT NULL AND cep_clean IS NULL;

CREATE OR REPLACE VIEW vw_enderecos_completos AS
SELECT 
    id_endereco,
    tipo_logradouro,
    logradouro,
    numero,
    complemento,
    bairro,
    cidade,
    uf,
    cep,
    ST_AsText(geom) AS wkt_geom,
    ST_X(geom) AS longitude,
    ST_Y(geom) AS latitude,
    geocode_source,
    geocode_confidence
FROM endereco;
