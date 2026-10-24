-- Pattern 07: Spatial join with buffer tolerance
-- Join points to polygons using ST_Intersects(ST_Buffer(point, radius)) to
-- capture near-edge features. Useful for service-area assignment where a
-- point just outside a boundary should still count.
SELECT p.id, z.name
FROM points p
LEFT JOIN zones z ON ST_Intersects(ST_Buffer(p.geom, 0.01), z.geom);
