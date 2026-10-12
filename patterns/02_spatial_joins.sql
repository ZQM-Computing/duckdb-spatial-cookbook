-- Pattern 02: Spatial joins and per-area summaries
-- The analytical twin of the PostGIS spatial-join patterns: assign points to
-- polygons, then aggregate. DuckDB's query engine parallelizes these joins
-- and can push the spatial predicate into its join planning.

-- Sites per service area, with a LEFT JOIN so empty areas still report.
SELECT
    a.name AS service_area,
    count(s.site_id) AS site_count
FROM service_areas AS a
LEFT JOIN service_sites AS s
    ON ST_Within(s.geom, a.geom)
GROUP BY a.name
ORDER BY a.name;

-- Which sites fall outside every service area? (West depot, by design --
-- the orphan check every spatial join should ship with.)
SELECT s.name
FROM service_sites AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM service_areas AS a
    WHERE ST_Within(s.geom, a.geom)
);

-- Parcels intersecting each area, summarized by land use.
SELECT
    a.name AS service_area,
    p.land_use,
    count(*) AS parcels,
    round(sum(p.acres), 1) AS total_acres
FROM parcels AS p
JOIN service_areas AS a
    ON ST_Intersects(p.geom, a.geom)
GROUP BY a.name, p.land_use
ORDER BY a.name, p.land_use;
