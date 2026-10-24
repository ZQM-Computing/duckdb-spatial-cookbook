-- Pattern 08: CRS transform with ST_Transform
-- Reproject geometry between EPSG codes. DuckDB follows EPSG axis order;
-- set geometry_always_xy=true to force (lon,lat) ordering.
SET geometry_always_xy = true;
SELECT ST_Transform(geom, 'EPSG:4326', 'EPSG:3857') AS geom_webmercator
FROM features;
