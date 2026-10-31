"""Run every pattern in order against a fresh in-memory DuckDB, then the
checks in tests/checks.sql.

Usage (from the repository root):
    pip install -r requirements.txt
    python scripts/run_examples.py

Each SQL file is split into statements; SELECT results are printed so the
run doubles as a readable transcript. Any error or failed check exits
nonzero.
"""

from __future__ import annotations

import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent.parent
DISPLAY_ROW_LIMIT = 12

FILES = [
    "sql/00_setup.sql",
    "patterns/01_reading_data.sql",
    "patterns/02_spatial_joins.sql",
    "patterns/03_coordinate_systems.sql",
    "patterns/04_nearest_neighbor.sql",
    "patterns/05_geoparquet_workflows.sql",
    "patterns/06_h3_aggregation.sql",
    "patterns/07_geometry_quality.sql",
]


def statements(sql: str) -> list[str]:
    """Split a .sql file into executable statements (comments kept with the
    statement that follows them; comment-only chunks are dropped)."""
    out = []
    for chunk in sql.split(";\n"):
        code = "\n".join(
            line for line in chunk.splitlines() if not line.strip().startswith("--")
        ).strip()
        if code:
            out.append(chunk.strip() + ";")
    return out


def run_file(con: duckdb.DuckDBPyConnection, rel: str) -> None:
    """Execute a SQL file while bounding memory used for printed result rows."""
    print(f"\n==> {rel}")
    for stmt in statements((ROOT / rel).read_text(encoding="utf-8")):
        result = con.execute(stmt)
        if result.description is not None:
            # Fetch one sentinel row beyond the display limit. Do not fetchall():
            # spatial joins and analytical queries can return millions of rows.
            rows = result.fetchmany(DISPLAY_ROW_LIMIT + 1)
            for row in rows[:DISPLAY_ROW_LIMIT]:
                print("   ", row)
            if len(rows) > DISPLAY_ROW_LIMIT:
                print(
                    f"    ... additional rows omitted "
                    f"(display capped at {DISPLAY_ROW_LIMIT})"
                )


def run_checks(con: duckdb.DuckDBPyConnection) -> None:
    print("\n==> tests/checks.sql")
    rows = con.execute(
        (ROOT / "tests/checks.sql").read_text(encoding="utf-8")
    ).fetchall()
    failures = []
    for name, expected, actual in rows:
        status = "ok" if expected == actual else "FAIL"
        print(f"    [{status}] {name}: expected {expected}, got {actual}")
        if expected != actual:
            failures.append(name)
    if failures:
        raise SystemExit(f"checks failed: {failures}")


def main() -> int:
    (ROOT / "build").mkdir(exist_ok=True)
    con = duckdb.connect()
    # Pattern files reference data/ and build/ relative to the repo root.
    import os

    os.chdir(ROOT)
    for rel in FILES:
        run_file(con, rel)
    run_checks(con)
    print("\nduckdb-spatial-cookbook: all examples and checks completed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
