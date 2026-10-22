-- Checks: every row is (check_name, expected, actual) as text.
-- (Sphere distances use plain lon/lat geometry: sql/00_setup.sql sets
-- geometry_always_xy, so no axis-swap idiom is needed -- or correct.)
-- scripts/run_examples.py compares expected vs actual and fails on a miss.
SELECT 'areas_count', '3', count(*)::VARCHAR FROM service_areas
UNION ALL
SELECT 'sites_count', '9', count(*)::VARCHAR FROM service_sites
UNION ALL
SELECT 'parcels_count', '4', count(*)::VARCHAR FROM parcels
UNION ALL
SELECT 'sites_in_north', '3', count(*)::VARCHAR
FROM service_sites s JOIN service_areas a ON ST_Within(s.geom, a.geom)
WHERE a.name = 'North'
UNION ALL
SELECT 'sites_in_central', '2', count(*)::VARCHAR
FROM service_sites s JOIN service_areas a ON ST_Within(s.geom, a.geom)
WHERE a.name = 'Central'
UNION ALL
SELECT 'sites_in_coastal', '3', count(*)::VARCHAR
FROM service_sites s JOIN service_areas a ON ST_Within(s.geom, a.geom)
WHERE a.name = 'Coastal'
UNION ALL
SELECT 'orphan_sites', '1', count(*)::VARCHAR
FROM service_sites s
WHERE NOT EXISTS (
    SELECT 1 FROM service_areas a WHERE ST_Within(s.geom, a.geom)
)
UNION ALL
SELECT 'nearest_site_to_parcel_2', 'Central depot', (
    SELECT s.name
    FROM parcels p CROSS JOIN service_sites s
    WHERE p.parcel_id = 2
    ORDER BY ST_Distance_Sphere(ST_Centroid(p.geom), s.geom)
    LIMIT 1
)
UNION ALL
SELECT 'sphere_distance_north_pair_m', '10235', round(ST_Distance_Sphere(
    ST_Point(-81.10, 29.28),
    ST_Point(-81.02, 29.22)
))::BIGINT::VARCHAR
UNION ALL
SELECT 'state_plane_x_of_north_depot', '624288', round(ST_X(
    ST_Transform(ST_Point(-81.10, 29.28), 'OGC:CRS84', 'EPSG:2236')
))::BIGINT::VARCHAR
UNION ALL
SELECT 'geoparquet_operations_sites', '4', count(*)::VARCHAR
FROM read_parquet('build/sites_by_category/**/*.parquet', hive_partitioning = true)
WHERE category = 'operations'
UNION ALL
SELECT 'h3_cells_res8', '9', count(DISTINCT h3_latlng_to_cell(ST_Y(geom), ST_X(geom), 8))::VARCHAR
FROM service_sites;
