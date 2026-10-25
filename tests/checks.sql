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
SELECT 'nearest_site_to_parcel_1', 'Central depot', (
    SELECT s.name
    FROM parcels p CROSS JOIN service_sites s
    WHERE p.parcel_id = 1
    ORDER BY ST_Distance_Sphere(ST_Centroid(p.geom), s.geom), s.site_id
    LIMIT 1
)
UNION ALL
SELECT 'nearest_site_to_parcel_3', 'Coastal depot', (
    SELECT s.name
    FROM parcels p CROSS JOIN service_sites s
    WHERE p.parcel_id = 3
    ORDER BY ST_Distance_Sphere(ST_Centroid(p.geom), s.geom), s.site_id
    LIMIT 1
)
UNION ALL
SELECT 'nearest_site_to_parcel_4', 'West depot', (
    SELECT s.name
    FROM parcels p CROSS JOIN service_sites s
    WHERE p.parcel_id = 4
    ORDER BY ST_Distance_Sphere(ST_Centroid(p.geom), s.geom), s.site_id
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
FROM service_sites
UNION ALL
SELECT 'nearest_k_two_rows', '8', count(*)::VARCHAR
FROM (
    SELECT p.parcel_id, s.site_id,
           row_number() OVER (
               PARTITION BY p.parcel_id
               ORDER BY ST_Distance_Sphere(ST_Centroid(p.geom), s.geom), s.site_id
           ) AS rank
    FROM parcels p CROSS JOIN service_sites s
) ranked
WHERE rank <= 2
UNION ALL
SELECT 'nearest_k_two_rank_values', '1,2', (
    SELECT string_agg(DISTINCT rank::VARCHAR, ',' ORDER BY rank::VARCHAR)
    FROM (
        SELECT row_number() OVER (
            PARTITION BY p.parcel_id
            ORDER BY ST_Distance_Sphere(ST_Centroid(p.geom), s.geom), s.site_id
        ) AS rank
        FROM parcels p CROSS JOIN service_sites s
    ) ranked
    WHERE rank <= 2
)
UNION ALL
SELECT 'sites_by_area_roundtrip_count', '9', count(*)::VARCHAR
FROM read_parquet('build/sites_by_area.parquet')
UNION ALL
SELECT 'sites_by_area_roundtrip_preserved', '9', count(*)::VARCHAR
FROM read_parquet('build/sites_by_area.parquet') AS exported
JOIN service_sites AS source USING (site_id)
WHERE exported.name = source.name
  AND exported.category = source.category
  AND ST_Equals(exported.geom, source.geom)
UNION ALL
SELECT 'sites_by_area_orphan_count', '1', count(*)::VARCHAR
FROM read_parquet('build/sites_by_area.parquet')
WHERE service_area IS NULL
UNION ALL
SELECT 'sites_by_area_roundtrip_unique_ids', '9', count(DISTINCT site_id)::VARCHAR
FROM read_parquet('build/sites_by_area.parquet')
UNION ALL
SELECT 'sites_by_area_source_loss', '0', count(*)::VARCHAR
FROM service_sites AS source
WHERE NOT EXISTS (
    SELECT 1 FROM read_parquet('build/sites_by_area.parquet') AS exported
    WHERE exported.site_id = source.site_id
)
UNION ALL
SELECT 'sites_by_area_unexpected_ids', '0', count(*)::VARCHAR
FROM read_parquet('build/sites_by_area.parquet') AS exported
WHERE NOT EXISTS (
    SELECT 1 FROM service_sites AS source
    WHERE source.site_id = exported.site_id
)
UNION ALL
SELECT 'sites_by_area_assignment_mismatches', '0', count(*)::VARCHAR
FROM (
    SELECT source.site_id, area.name AS expected_area, exported.service_area
    FROM service_sites AS source
    LEFT JOIN service_areas AS area
        ON ST_Within(source.geom, area.geom)
    JOIN read_parquet('build/sites_by_area.parquet') AS exported
        ON exported.site_id = source.site_id
    WHERE exported.service_area IS DISTINCT FROM area.name
) AS mismatches
UNION ALL
SELECT 'partitioned_sites_roundtrip_count', '9', count(*)::VARCHAR
FROM read_parquet('build/sites_by_category/**/*.parquet', hive_partitioning = true);
UNION ALL
SELECT 'h3_assigned_sites', '9', count(*)::VARCHAR
FROM service_sites
WHERE h3_latlng_to_cell(ST_Y(geom), ST_X(geom), 8) IS NOT NULL
UNION ALL
SELECT 'h3_aggregation_conserves_sites', '9', sum(cell_count)::BIGINT::VARCHAR
FROM (
    SELECT h3_latlng_to_cell(ST_Y(geom), ST_X(geom), 8) AS h3_cell,
           count(*) AS cell_count
    FROM service_sites
    GROUP BY h3_cell
) AS cells
UNION ALL
SELECT 'h3_boundary_wkt_shape', '9', count(*)::VARCHAR
FROM (
    SELECT h3_cell_to_boundary_wkt(h3_latlng_to_cell(ST_Y(geom), ST_X(geom), 8)) AS boundary_wkt
    FROM service_sites
) AS boundaries
WHERE starts_with(boundary_wkt, 'POLYGON((')
  AND ends_with(boundary_wkt, '))');\n