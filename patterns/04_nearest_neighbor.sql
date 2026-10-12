-- Pattern 04: Nearest neighbor (KNN) with window functions
-- The PostGIS version of this pattern uses the KNN operator (<->) and a
-- GiST index. Embedded DuckDB has no spatial index to lean on, so the
-- pattern is: compute candidate distances, rank with a window function,
-- keep rank 1 with QUALIFY. On analytical data volumes this is fast --
-- and the shape works in any SQL engine.
--
-- Distances use the sphere idiom from pattern 03: the ST_Distance_Sphere
-- function reads x as latitude, so each (lon, lat) geometry is rebuilt as
-- ST_Point(ST_Y(g), ST_X(g)) before the call.

-- Nearest service site to every parcel centroid, with distance in km.
SELECT
    p.parcel_id,
    p.land_use,
    s.name AS nearest_site,
    round(ST_Distance_Sphere(
        ST_Point(ST_Y(ST_Centroid(p.geom)), ST_X(ST_Centroid(p.geom))),
        ST_Point(ST_Y(s.geom), ST_X(s.geom))
    ) / 1000.0, 2) AS distance_km
FROM parcels AS p
CROSS JOIN service_sites AS s
QUALIFY row_number() OVER (
    PARTITION BY p.parcel_id
    ORDER BY ST_Distance_Sphere(
        ST_Point(ST_Y(ST_Centroid(p.geom)), ST_X(ST_Centroid(p.geom))),
        ST_Point(ST_Y(s.geom), ST_X(s.geom))
    )
) = 1
ORDER BY p.parcel_id;

-- The same ranking generalizes to K nearest: change the QUALIFY filter to
-- <= 3 and every parcel gets its three closest sites, ranked.
SELECT
    p.parcel_id,
    s.name AS nearby_site,
    round(ST_Distance_Sphere(
        ST_Point(ST_Y(ST_Centroid(p.geom)), ST_X(ST_Centroid(p.geom))),
        ST_Point(ST_Y(s.geom), ST_X(s.geom))
    ) / 1000.0, 2) AS distance_km,
    row_number() OVER (
        PARTITION BY p.parcel_id
        ORDER BY ST_Distance_Sphere(
            ST_Point(ST_Y(ST_Centroid(p.geom)), ST_X(ST_Centroid(p.geom))),
            ST_Point(ST_Y(s.geom), ST_X(s.geom))
        )
    ) AS rank
FROM parcels AS p
CROSS JOIN service_sites AS s
QUALIFY rank <= 2
ORDER BY p.parcel_id, rank;
