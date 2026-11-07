# DuckDB Spatial: missing coverage is not a zero result

**Question:** If an environmental screening dataset has no observations
over a parcel, can I report **zero hazards**?

**Answer:** No. With absent source coverage, the valid state is
**unknown / not observed**, not zero observed observations and certainly
not "safe." This cookbook provides an **offline, synthetic SQL demonstration**
of retaining NULL for missing coverage while using zero only for covered
areas with no matching records.

## Run the verified fixture

Install the cookbook's documented dependencies and run its existing
full suite (spatial and H3 extensions may need first-use installation):

```bash
python scripts/run_examples.py
```

The runner loads the repo's synthetic **four parcel** and **nine site**
fixtures, executes all eight numbered SQL patterns and runs the golden
checks in `tests/checks.sql`. Pattern 08 lives at
`patterns/08_missing_coverage_vs_zero.sql` (in the repository root).

## What the example actually does

In the synthetic demonstration:

- Parcel IDs 1–3 are deliberately marked **covered** by an illustrative
  `coverage` table.
- Parcel ID 4 is deliberately marked **uncovered**, regardless of
  whether a service-site point might lie within its geometry.
- `ST_Within` counts matches for covered parcel polygons only.
  Covered parcels return an integer, including **zero** where no synthetic
  service-site records match.
- The uncovered parcel returns `NULL` and
  `unknown_missing_coverage`, never the number zero.
- Golden SQL checks assert four rows, three observed rows, one
  unknown row, and no invented zero for unknown coverage.

The lesson demonstrates **record availability and join semantics**,
not actual remote-sensing footprints or a regulatory constraint.
The source uses synthetic sites, **not actual hazards**.
A site count of zero does not prove environmental absence.

## Why a standard LEFT JOIN is not enough

A query that `COALESCE`s every null match to zero obscures two
different circumstances:

1. **Covered with zero recorded events:** the input source covers the
   location, and no qualifying record was found.
2. **Not observed / missing coverage:** no reliable input supports a
   conclusion for the location.

Conflating the cases makes a preliminary screen appear safer and
more complete than the evidence justifies. In a real study, data
coverage must be derived from authoritative metadata or independently
validated imagery footprints, not a hard-coded parcel identifier.

## Moving this pattern toward a real study

1. Keep source/observation coverage as an explicit dataset with source
   name, time period, license, spatial footprint, uncertainty and
   sampling constraints. Absence of recorded sites is not absence
   of environmental risk.
2. Harmonize CRS **before** metric area/distance calculations.
   This example counts points within polygons and does not report
   meters, square meters or measured risk.
3. Verify temporal windows and source-data completeness; classify
   missing/poor-quality intervals as unknown instead of using
   `COALESCE(..., 0)`.
4. Compare against the [GeoPandas Cookbook](https://github.com/ZQM-Computing/geopandas-cookbook)
   for reusable QA overlays and provenance. Include equality checks
   if porting across engines.
5. Publish a map only with appropriate legends for covered-zero,
   covered-positive, and unknown data. Include accessible text.
   No synthetic values may be marketed as observed site outcomes.
6. Treat output as **preliminary GIS screening**, not a certified
   survey, engineering determination, regulatory finding or
   professional environmental clearance.

This is a genuine eighth executable SQL pattern, but **not** evidence
that every other cookbook has reached the new hero content quality
gate or that customer workflows have been validated.
