-- Setup: extensions and the sample dataset.
--
-- DuckDB is an embedded analytical database: there is no server to start.
-- The spatial extension provides the ST_* functions and GDAL-backed readers;
-- the h3 community extension provides hexagon binning (pattern 06).

INSTALL spatial;
LOAD spatial;
INSTALL h3 FROM community;
LOAD h3;

-- The sample data is the same synthetic Volusia-shaped dataset used across
-- the ZQM geospatial portfolio repos: 3 service areas, 9 sites, 4 parcels.
-- No real property, infrastructure, or personal data.
CREATE OR REPLACE TABLE service_areas AS
SELECT area_id, name, geom
FROM ST_Read('data/service_areas.geojson');

CREATE OR REPLACE TABLE service_sites AS
SELECT site_id, name, category, observed_on, geom
FROM ST_Read('data/service_sites.geojson');

CREATE OR REPLACE TABLE parcels AS
SELECT parcel_id, land_use, acres, geom
FROM ST_Read('data/parcels.geojson');

SELECT 'service_areas' AS layer, count(*) AS features FROM service_areas
UNION ALL
SELECT 'service_sites', count(*) FROM service_sites
UNION ALL
SELECT 'parcels', count(*) FROM parcels;
