-- Pattern 01: Reading geospatial data
-- DuckDB's strength is meeting data where it already lives: files on disk,
-- object storage, or a data lake -- no import pipeline, no server.

-- GeoJSON via the GDAL-backed ST_Read (used in sql/00_setup.sql).
SELECT name, category, ST_AsText(geom) AS location
FROM service_sites
ORDER BY site_id
LIMIT 3;

-- Any GeoJSON can also be inspected before loading: ST_Read exposes the
-- layer's columns, and ST_Extent summarizes its footprint.
SELECT ST_AsText(ST_Extent(geom)) AS footprint
FROM service_areas;

-- CSV with coordinate columns -> real geometry in one expression.
-- (Swap the VALUES list for read_csv('your_file.csv') in real work.)
WITH raw(name, lon, lat) AS (
    VALUES
        ('Field check A', -81.221, 29.121),
        ('Field check B', -80.812, 29.301)
)
SELECT name, ST_AsText(ST_Point(lon, lat)) AS geom_wkt
FROM raw;

-- GeoParquet is read natively -- geometry columns come back typed as
-- GEOMETRY, not blobs, because the file carries GeoParquet metadata.
-- (This file is written by pattern 05; the read is shown here for the
-- shape -- run the patterns in order.)
-- SELECT * FROM read_parquet('build/sites_by_area.parquet');
