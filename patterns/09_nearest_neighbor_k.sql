-- Pattern 09: K-nearest neighbors (KNN) via QUALIFY
-- Compute distance to all candidates, rank per source point, keep top K.
WITH ranked AS (
  SELECT s.id AS src, t.id AS tgt,
         ST_Distance(s.geom, t.geom) AS dist,
         ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY ST_Distance(s.geom, t.geom)) AS rn
  FROM sources s CROSS JOIN targets t
)
SELECT src, tgt, dist FROM ranked WHERE rn <= 3;
