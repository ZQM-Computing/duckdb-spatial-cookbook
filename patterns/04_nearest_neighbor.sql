-- Pattern 04: Deterministic nearest-neighbor analysis
--
-- sql/00_setup.sql sets geometry_always_xy = true. All geometries in this
-- cookbook therefore use (longitude, latitude) order; do not swap X/Y before
-- ST_Distance_Sphere. Swapping them produces incorrect distances and can
-- move features to the wrong hemisphere.
--
-- This DuckDB example computes exact spherical distances for every
-- parcel/site pair, then ranks the candidates. It is an O(P*S) analytical
-- baseline; for large datasets, prefilter candidates or use a spatial-indexed
-- backend such as PostGIS.

WITH distances AS (
    SELECT
        p.parcel_id,
        p.land_use,
        s.site_id,
        s.name AS nearest_site,
        ST_Distance_Sphere(ST_Centroid(p.geom), s.geom) AS distance_m
    FROM parcels AS p
    CROSS JOIN service_sites AS s
),
ranked AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY parcel_id
            ORDER BY distance_m, site_id
        ) AS rank
    FROM distances
)
SELECT
    parcel_id,
    land_use,
    site_id,
    nearest_site,
    round(distance_m / 1000.0, 2) AS distance_km
FROM ranked
WHERE rank = 1
ORDER BY parcel_id;

-- K-nearest variant. The stable site_id tie-break makes ranking repeatable
-- when two sites have the same computed distance.
WITH distances AS (
    SELECT
        p.parcel_id,
        s.site_id,
        s.name AS nearby_site,
        ST_Distance_Sphere(ST_Centroid(p.geom), s.geom) AS distance_m
    FROM parcels AS p
    CROSS JOIN service_sites AS s
),
ranked AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY parcel_id
            ORDER BY distance_m, site_id
        ) AS rank
    FROM distances
)
SELECT
    parcel_id,
    site_id,
    nearby_site,
    round(distance_m / 1000.0, 2) AS distance_km,
    rank
FROM ranked
WHERE rank <= 2
ORDER BY parcel_id, rank;
