# Pattern guide: DuckDB or PostGIS

These two engines are complements, not competitors. This repo and
[postgis-cookbook](https://github.com/ZQM-Computing/postgis-cookbook) use the
same sample dataset so the patterns translate directly.

| Question | DuckDB Spatial (this repo) | PostGIS |
|---|---|---|
| Where does the data live? | Files: GeoParquet, GeoJSON, CSV, S3/GCS | A managed PostgreSQL database |
| Concurrency model | One analyst process, embarrassingly parallel reads | Many simultaneous writers/readers |
| Best at | Ad-hoc analysis, data-lake queries, ETL, prototyping, CI-friendly analytics | System of record, transactional edits, serving (APIs, tiles) |
| Spatial indexing | Engine-managed join strategies; no user GiST to tune | GiST/SP-GiST/BRIN you design and maintain |
| Setup cost | `pip install duckdb` | A database server (or Docker) |

Rule of thumb from production work: **explore and analyze in DuckDB, persist
and serve from PostGIS.** A common flow is to prototype a spatial join here,
then promote the proven SQL into the database — the pattern files are
deliberately parallel so the translation is visible (spatial joins, CRS
handling, nearest neighbor appear in both repos).

## Extension notes

- `spatial` is an official DuckDB extension (`INSTALL spatial`). It bundles
  GDAL for file reading and PROJ for transforms.
- `h3` is a *community* extension (`INSTALL h3 FROM community`). Pin your
  DuckDB version in production work so extension behavior is reproducible.
- Extensions download on first install; in CI that happens on every run.
  For offline work, pre-install into a local extension directory.

## The two traps these patterns exist to defuse

1. **Axis order — two heads.** DuckDB honors EPSG authority axis order:
   `EPSG:4326` means (lat, lon) to PROJ. Lon/lat data must be transformed
   with `'OGC:CRS84'` as the source (pattern 03). The same stance reaches
   the distance functions: `ST_Distance_Sphere` reads a geometry's x as
   *latitude*, so (lon, lat) points must be rebuilt as
   `ST_Point(ST_Y(g), ST_X(g))` for the call — feeding them raw returns a
   confidently wrong answer (8,956 m instead of 10,235 m on the pattern's
   test pair, both verified against a hand-computed haversine). PostGIS,
   by contrast, always treats geometry as (lon, lat) — so SQL moved
   between the engines needs this one adjustment, in both places.
2. **Degree distances.** `ST_Distance` on lon/lat geometry returns degrees
   in both engines' planar functions. Use the sphere idiom above for
   meters on lon/lat, or transform to a projected CRS first.

## GeoParquet in the wider toolchain

Files written by pattern 05 open directly in QGIS (drag-and-drop), GeoPandas
(`read_parquet`), and cloud engines with GeoParquet support — which is the
point of the format: the analysis artifact *is* the deliverable, no export
step, no shapefile sidecar files, no 10-character column names.
