-- Pattern 05: GeoParquet workflows
-- GeoParquet is the interchange format that makes embedded analytics sing:
-- columnar, compressed, self-describing (geometry type + CRS in the file
-- metadata), and readable by DuckDB, QGIS, GeoPandas, and cloud engines.

-- Export a joined result as GeoParquet.
COPY (
    SELECT
        s.site_id,
        s.name,
        s.category,
        a.name AS service_area,
        s.geom
    FROM service_sites AS s
    LEFT JOIN service_areas AS a
        ON ST_Within(s.geom, a.geom)
) TO 'build/sites_by_area.parquet' (FORMAT PARQUET);

-- Read it back: the geometry column returns typed as GEOMETRY -- proof the
-- GeoParquet metadata survived the round trip.
SELECT service_area, count(*) AS sites
FROM read_parquet('build/sites_by_area.parquet')
GROUP BY service_area
ORDER BY service_area NULLS LAST;

-- Partitioned export: one directory per category, hive-style. Downstream
-- readers can then prune whole partitions with a WHERE clause.
COPY (
    SELECT site_id, name, category, geom
    FROM service_sites
) TO 'build/sites_by_category' (
    FORMAT PARQUET,
    PARTITION_BY (category),
    OVERWRITE_OR_IGNORE
);

-- Partition pruning on read: this only opens the operations partition.
SELECT count(*) AS operations_sites
FROM read_parquet(
    'build/sites_by_category/**/*.parquet',
    hive_partitioning = true
)
WHERE category = 'operations';
