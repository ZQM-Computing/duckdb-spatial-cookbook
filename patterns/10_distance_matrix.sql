-- Pattern 10: Pairwise distance matrix
-- All-pairs distances; filter to upper triangle to avoid duplicates.
SELECT a.id, b.id, ST_Distance(a.geom, b.geom) AS dist
FROM points a JOIN points b ON a.id < b.id;
