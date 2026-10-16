# duckdb-spatial-patterns — DuckDB Spatial Patterns for Analytical Geospatial SQL

<!-- ZQM-START -->
<p align="center">
  <strong>ZQM Labs — Z's Quests & Mischief</strong><br>
  <a href="https://zqmlabs.com">zqmlabs.com</a> •
  <a href="https://github.com/ZQM-Labs">GitHub</a>
</p>
<!-- ZQM-END -->



[![Validate examples](https://github.com/ZQM-Computing/duckdb-spatial-patterns/actions/workflows/validate.yml/badge.svg)](https://github.com/ZQM-Computing/duckdb-spatial-patterns/actions/workflows/validate.yml)

Runnable **DuckDB Spatial** patterns for analytical geospatial work: reading **GeoJSON, GeoParquet, and CSV** in place, **spatial joins**, **nearest-neighbor** queries, coordinate-system handling (including the **EPSG axis-order trap**), **GeoParquet export and partitioning**, and **H3 hexagon aggregation** — all with **no database server to run**. DuckDB is embedded: `pip install duckdb` and the patterns execute.

This is the analytical companion to [postgis-patterns](https://github.com/ZQM-Computing/postgis-patterns): the same synthetic dataset and the same questions, answered with the embedded engine instead of the server database. Explore in DuckDB, persist and serve from PostGIS — the [pattern guide](docs/pattern-guide.md) maps when each engine earns its place.

## Quick start

```bash
git clone https://github.com/ZQM-Computing/duckdb-spatial-patterns.git
cd duckdb-spatial-patterns
pip install -r requirements.txt
python scripts/run_examples.py
```

The runner executes every pattern against a fresh in-memory database and finishes with the checks in `tests/checks.sql` (row counts, join results, distances, transform accuracy, GeoParquet round-trip, H3 cell counts). It runs in CI on every push.

You can also explore interactively: install the [DuckDB CLI](https://duckdb.org/docs/installation/), open a database, and paste any pattern after running `sql/00_setup.sql`.

## The patterns

| # | Pattern | What it teaches |
|---|---|---|
| 01 | Reading geospatial data | `ST_Read` on GeoJSON, CSV coordinates → geometry, typed GeoParquet reads |
| 02 | Spatial joins | Points-in-polygons with `ST_Within`, orphan detection, per-area land-use summaries |
| 03 | Coordinate systems | The EPSG:4326 axis-order trap and the `OGC:CRS84` fix; sphere vs. planar distances; State Plane transforms |
| 04 | Nearest neighbor | KNN without a spatial index: `row_number()` + `QUALIFY` ranking over `ST_Distance_Sphere` |
| 05 | GeoParquet workflows | `COPY TO` GeoParquet export, hive-style partitioned writes, partition pruning on read |
| 06 | H3 aggregation | Hexagon binning with the `h3` community extension, boundary WKT for mapping the result anywhere |

## Who this is for

Data engineers and GIS analysts who keep spinning up a server database for what is really a file-and-notebook problem — or who are evaluating DuckDB Spatial and GeoParquet for a data-lake workflow and want patterns that run, not slides. If you already think in PostGIS, the parallel structure (same data, same questions) makes the mental translation explicit: no GiST index to design, axis order handled differently, KNN as a window function instead of an operator.

## Design principles

1. **No server, no fixtures service.** Everything runs from files in the repo with one pip install — including in CI.
2. **Verified numbers.** `tests/checks.sql` pins the expected results (distances to the meter, State Plane coordinates to the foot) so an engine upgrade that changes behavior fails loudly.
3. **Traps documented, not hidden.** The axis-order and degree-distance pitfalls are demonstrated with the wrong answer shown and labeled — the fastest way to learn to recognize them.
4. **Formats are the interface.** Pattern outputs are GeoParquet files that open in QGIS, GeoPandas, and PostGIS pipelines unchanged.

## Repository layout

```text
.
├── sql/00_setup.sql     # extensions + sample tables from data/
├── patterns/            # the six patterns, in reading order
├── data/                # synthetic GeoJSON (3 areas, 9 sites, 4 parcels)
├── scripts/             # run_examples.py — full suite + checks
├── tests/checks.sql     # expected-value checks
├── docs/pattern-guide.md# DuckDB vs. PostGIS: when each earns its place
└── .github/workflows/   # CI: pip install + run the suite
```

## Data note

All data is synthetic. Coordinates fall around Volusia County, Florida for realism; nothing here represents real property, infrastructure, or people.

## Companion repositories

- [postgis-patterns](https://github.com/ZQM-Computing/postgis-patterns) — the same patterns as production PostGIS: indexing, tiling with `ST_AsMVT`, partitioning.
- [geospatial-api-reference](https://github.com/ZQM-Computing/geospatial-api-reference) — serving spatial data over REST (OGC API – Features, FastAPI + PostGIS).
- [qgis-resources](https://github.com/ZQM-Computing/qgis-resources) — the desktop side: QGIS expressions, PyQGIS, styles, QField.

## Contributing

Issues and pull requests are welcome. Contributions should keep the suite green via `python scripts/run_examples.py`, state the DuckDB version they were verified on, and keep all data synthetic. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Maintainer

Maintained by [ZQM Computing](https://github.com/ZQM-Computing). Distilled from production geospatial data-engineering and analysis work by Alex Zelenski, GISP.

## More from this series

- [postgis-patterns](https://github.com/ZQM-Computing/postgis-patterns) — Production PostGIS patterns: spatial indexing, joins & KNN, SRID management, vector tiles, data quality, partitioning
- [pgrouting-patterns](https://github.com/ZQM-Computing/pgrouting-patterns) — pgRouting network analysis on PostGIS: shortest path, driving distance, isochrones, turn restrictions, traffic-aware routing
- [geopandas-patterns](https://github.com/ZQM-Computing/geopandas-patterns) — GeoPandas/Shapely patterns for Python geospatial workflows: spatial joins, CRS handling, overlays, interpolation, performance
- [gdal-patterns](https://github.com/ZQM-Computing/gdal-patterns) — GDAL/OGR command-line patterns: conversion, reprojection, clipping, mosaicking — production-tested, runnable examples
- [stac-patterns](https://github.com/ZQM-Computing/stac-patterns) — STAC patterns for geospatial data discovery: catalogs, item validation, search API, bulk operations, cloud deployment
- [maplibre-patterns](https://github.com/ZQM-Computing/maplibre-patterns) — MapLibre GL JS patterns for frontend vector tile rendering: custom layers, 3D terrain, performance tuning, interactive maps
- [cog-patterns](https://github.com/ZQM-Computing/cog-patterns) — Cloud Optimized GeoTIFF patterns: creation, validation, TiTiler serving, xarray integration, performance benchmarking
- [geoparquet-patterns](https://github.com/ZQM-Computing/geoparquet-patterns) — GeoParquet patterns for columnar geospatial analytics: partitioning, predicate pushdown, DuckDB/Spark integration
- [h3-patterns](https://github.com/ZQM-Computing/h3-patterns) — H3 hexagonal grid patterns: indexing, aggregation, visualization, grid comparisons, performance benchmarks
- [qgis-resources](https://github.com/ZQM-Computing/qgis-resources) — QGIS expressions, PyQGIS snippets, Processing scripts, styles, and QField field-collection guides
- [geospatial-api-reference](https://github.com/ZQM-Computing/geospatial-api-reference) — OGC API – Features reference implementation with FastAPI and PostGIS backends
- [ollama-fleet-patterns](https://github.com/ZQM-Computing/ollama-fleet-patterns) — Ollama fleet operations: model management, health checks, load-spreading, VRAM budgeting, dependency-light RAG
- [proxmox-ceph-operations](https://github.com/ZQM-Computing/proxmox-ceph-operations) — Proxmox VE + Ceph operations runbooks: health checks, backup discipline, OSD replacement, upgrade checklists
- [geospatial-patterns](https://github.com/ZQM-Computing/geospatial-patterns) — Umbrella index for all ZQM geospatial pattern repos

## License

MIT — see [`LICENSE`](LICENSE).

## Related repositories

- [geospatial-patterns](https://github.com/ZQM-Computing/geospatial-patterns) — umbrella index of all geospatial pattern repos
- [gdal-patterns](https://github.com/ZQM-Computing/gdal-patterns) — GDAL/OGR CLI patterns for raster/vector conversion
- [geopandas-patterns](https://github.com/ZQM-Computing/geopandas-patterns) — GeoPandas/Shapely patterns for Python geospatial workflows
- [pgrouting-patterns](https://github.com/ZQM-Computing/pgrouting-patterns) — pgRouting patterns for PostGIS network analysis
- [stac-patterns](https://github.com/ZQM-Computing/stac-patterns) — STAC patterns for geospatial data discovery
- [cog-patterns](https://github.com/ZQM-Computing/cog-patterns) — Cloud Optimized GeoTIFF patterns
- [maplibre-patterns](https://github.com/ZQM-Computing/maplibre-patterns) — MapLibre GL JS patterns for frontend vector tiles
- [geoparquet-patterns](https://github.com/ZQM-Computing/geoparquet-patterns) — GeoParquet patterns for columnar analytics
- [h3-patterns](https://github.com/ZQM-Computing/h3-patterns) — H3 hexagonal grid patterns

*Part of [ZQM Labs](https://github.com/ZQM-Labs) — games, gear & a little mischief.*


<!-- ZQM-FOOTER-START -->
---

<p align="center">
  <em>Play more. Plan less.</em><br>
  <a href="https://zqmlabs.com">zqmlabs.com</a> •
  <a href="https://github.com/ZQM-Labs">ZQM Labs</a> •
  <a href="https://github.com/ZQM-Computing">ZQM Computing</a>
</p>
<!-- ZQM-FOOTER-END -->
