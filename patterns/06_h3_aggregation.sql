-- Pattern 06: Hexagon aggregation with H3
-- Administrative boundaries answer "which district?"; hexagons answer
-- "where is it dense?" -- with uniform cell sizes that don't bake a
-- jurisdiction's shape into the analysis. The h3 community extension
-- provides the indexing functions.

-- Assign each site to its resolution-8 H3 cell (~0.74 km2 per cell).
-- NOTE the argument order: h3_latlng_to_cell(latitude, longitude, res).
SELECT
    name,
    h3_latlng_to_cell(ST_Y(geom), ST_X(geom), 8) AS h3_cell
FROM service_sites
ORDER BY site_id
LIMIT 3;

-- Site counts per cell -- the hexagon summary table.
SELECT
    h3_latlng_to_cell(ST_Y(geom), ST_X(geom), 8) AS h3_cell,
    count(*) AS sites
FROM service_sites
GROUP BY h3_cell
ORDER BY sites DESC, h3_cell;

-- Emit cell boundaries as WKT so the summary can be drawn in QGIS or any
-- other tool: aggregate once, map anywhere.
SELECT
    h3_cell,
    count(*) AS sites,
    h3_cell_to_boundary_wkt(h3_cell) AS boundary_wkt
FROM (
    SELECT h3_latlng_to_cell(ST_Y(geom), ST_X(geom), 8) AS h3_cell
    FROM service_sites
)
GROUP BY h3_cell
ORDER BY h3_cell;
