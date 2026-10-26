-- Pattern 07: Geometry and identifier quality gates
-- Run these checks before spatial joins, distance calculations, or export.
-- Failures are surfaced as rows; the final status is PASS only when each
-- layer has unique non-null identifiers and non-null, non-empty, valid geometry.

WITH layer_checks AS (
    SELECT
        'service_areas' AS layer,
        count(*) AS feature_count,
        count(*) FILTER (WHERE area_id IS NULL) AS null_id_count,
        count(DISTINCT area_id) AS distinct_id_count,
        count(*) FILTER (WHERE geom IS NULL) AS null_geometry_count,
        count(*) FILTER (
            WHERE geom IS NOT NULL AND ST_IsEmpty(geom)
        ) AS empty_geometry_count,
        count(*) FILTER (
            WHERE geom IS NOT NULL AND NOT ST_IsValid(geom)
        ) AS invalid_geometry_count
    FROM service_areas

    UNION ALL

    SELECT
        'service_sites',
        count(*),
        count(*) FILTER (WHERE site_id IS NULL),
        count(DISTINCT site_id),
        count(*) FILTER (WHERE geom IS NULL),
        count(*) FILTER (
            WHERE geom IS NOT NULL AND ST_IsEmpty(geom)
        ),
        count(*) FILTER (
            WHERE geom IS NOT NULL AND NOT ST_IsValid(geom)
        )
    FROM service_sites

    UNION ALL

    SELECT
        'parcels',
        count(*),
        count(*) FILTER (WHERE parcel_id IS NULL),
        count(DISTINCT parcel_id),
        count(*) FILTER (WHERE geom IS NULL),
        count(*) FILTER (
            WHERE geom IS NOT NULL AND ST_IsEmpty(geom)
        ),
        count(*) FILTER (
            WHERE geom IS NOT NULL AND NOT ST_IsValid(geom)
        )
    FROM parcels
)
SELECT
    layer,
    feature_count,
    null_id_count,
    feature_count - distinct_id_count AS duplicate_id_count,
    null_geometry_count,
    empty_geometry_count,
    invalid_geometry_count,
    CASE
        WHEN null_id_count = 0
         AND feature_count = distinct_id_count
         AND null_geometry_count = 0
         AND empty_geometry_count = 0
         AND invalid_geometry_count = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM layer_checks
ORDER BY layer;
