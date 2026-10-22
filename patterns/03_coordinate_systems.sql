-- Pattern 03: Coordinate systems -- and the axis-order traps
-- DuckDB follows the EPSG authority axis order. For EPSG:4326 that order
-- is (latitude, longitude), while GeoJSON and ST_Point use (longitude,
-- latitude). That mismatch is the root of every trap in this file.
--
-- Current DuckDB (>= 2.0) refuses to guess: any axis-sensitive function
-- (ST_Transform, ST_Distance_Sphere, ...) called on geometry without an
-- explicit CRS errors out unless 'geometry_always_xy' is enabled. The
-- setting is DuckDB's sanctioned switch -- "always assume my coordinates
-- are (longitude, latitude)" -- and every example in this file uses
-- lon/lat data, so the file enables it for the session.
SET geometry_always_xy = true;

-- Trap 1: naming the wrong source CRS. Transforming lon/lat data with
-- 'EPSG:4326' (authority order: lat, lon) as the source used to produce
-- silently axis-swapped garbage; current DuckDB raises the axis-order
-- error instead. Kept as a commented snippet so this file stays
-- runnable -- do not run:
-- SELECT ST_AsText(
--     ST_Transform(ST_Point(-81.10, 29.28), 'EPSG:4326', 'EPSG:2236')
-- ) AS wrong_axis_order;

-- Correct: CRS84 declares (longitude, latitude) order explicitly.
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

-- Trap 2b: the sphere functions share the axis-order stance. Historically
-- they read a geometry's x as *latitude*, so fed ordinary (lon, lat)
-- points this pair measured a confidently wrong 8,956 m (verified against
-- a hand-computed haversine). Current DuckDB errors on the call without
-- 'geometry_always_xy'; with it set (above), the sphere functions read
-- (lon, lat) like everything else and return the correct 10,235 m:
SELECT round(ST_Distance_Sphere(
    ST_Point(-81.10, 29.28),
    ST_Point(-81.02, 29.22)
)) AS sphere_distance_meters_correct;

-- The pre-2.0 idiom -- rebuild each point as (lat, lon) for the sphere
-- functions -- is obsolete under 'geometry_always_xy' and would now
-- produce the wrong value; it survives only as this note.

-- ...and the other sidestep still works: transform to a projected CRS
-- and measure there (State Plane feet -> miles).
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
