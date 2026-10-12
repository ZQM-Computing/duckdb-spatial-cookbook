-- Pattern 03: Coordinate systems -- and the axis-order traps
-- Trap 1: DuckDB follows the EPSG authority axis order. For EPSG:4326 that
-- order is (latitude, longitude), while GeoJSON and ST_Point use
-- (longitude, latitude). Transforming with 'EPSG:4326' as the source on
-- lon/lat data silently produces garbage coordinates.
--
-- The fix: name the lon/lat order explicitly with 'OGC:CRS84'.

-- Garbage (axis-swapped) -- shown so you can recognize it:
SELECT ST_AsText(
    ST_Transform(ST_Point(-81.10, 29.28), 'EPSG:4326', 'EPSG:2236')
) AS wrong_axis_order;

-- Correct: CRS84 declares (longitude, latitude) order.
-- Florida State Plane East (EPSG:2236, US survey feet):
SELECT ST_AsText(
    ST_Transform(ST_Point(-81.10, 29.28), 'OGC:CRS84', 'EPSG:2236')
) AS florida_state_plane_east;

-- Trap 2a: ST_Distance on lon/lat geometry measures in *degrees* --
-- a meaningless unit for reporting.
SELECT round(ST_Distance(
    ST_Point(-81.10, 29.28),
    ST_Point(-81.02, 29.22)
), 4) AS distance_in_degrees_do_not_report;

-- Trap 2b: the sphere functions share the axis-order stance -- they read a
-- geometry's x as *latitude*. Fed ordinary (lon, lat) points, this returns
-- a confidently wrong 8,956 m for a pair that is really 10,235 m apart
-- (verified against a hand-computed haversine):
SELECT round(ST_Distance_Sphere(
    ST_Point(-81.10, 29.28),
    ST_Point(-81.02, 29.22)
)) AS sphere_distance_wrong_axis_order;

-- The idiom: rebuild each point as (lat, lon) for the sphere functions.
SELECT round(ST_Distance_Sphere(
    ST_Point(ST_Y(ST_Point(-81.10, 29.28)), ST_X(ST_Point(-81.10, 29.28))),
    ST_Point(ST_Y(ST_Point(-81.02, 29.22)), ST_X(ST_Point(-81.02, 29.22)))
)) AS sphere_distance_meters_correct;

-- ...or sidestep both traps: transform to a projected CRS and measure
-- there (State Plane feet -> miles).
WITH projected AS (
    SELECT
        ST_Transform(geom, 'OGC:CRS84', 'EPSG:2236') AS g,
        name
    FROM service_sites
)
SELECT round(
    ST_Distance(
        (SELECT g FROM projected WHERE name = 'North depot'),
        (SELECT g FROM projected WHERE name = 'North library')
    ) / 5280.0, 2
) AS distance_miles_state_plane;
