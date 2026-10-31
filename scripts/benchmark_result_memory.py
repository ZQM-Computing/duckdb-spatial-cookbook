"""Compare peak process RSS for full versus bounded DuckDB result fetching.

Run from the repository root:
    python scripts/benchmark_result_memory.py --rows 2000000

Each strategy runs in a fresh subprocess so its peak-RSS high-water mark is
isolated. This benchmark is opt-in and is not part of routine CI. It uses the
standard-library resource module and therefore supports Unix-like platforms;
Windows is rejected with an actionable message rather than reporting
incomparable or misleading memory figures.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time

DISPLAY_ROW_LIMIT = 12


def peak_rss_mib() -> float:
    import resource

    value = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    # Linux reports KiB; macOS reports bytes.
    if sys.platform == "darwin":
        return value / (1024 * 1024)
    return value / 1024


def worker(strategy: str, rows: int) -> dict[str, float | int | str]:
    import duckdb

    connection = duckdb.connect(":memory:")
    result = connection.execute(f"SELECT i FROM range({rows}) AS t(i)")
    started = time.perf_counter()
    if strategy == "fetchall":
        fetched = result.fetchall()
        fetched_count = len(fetched)
    else:
        fetched = result.fetchmany(DISPLAY_ROW_LIMIT + 1)
        fetched_count = len(fetched)
    elapsed = time.perf_counter() - started
    # Keep the fetched object alive until after the high-water mark is read.
    peak = peak_rss_mib()
    return {
        "strategy": strategy,
        "rows_requested": rows,
        "rows_fetched": fetched_count,
        "elapsed_seconds": round(elapsed, 6),
        "peak_rss_mib": round(peak, 2),
    }


def main() -> int:
    if os.name == "nt":
        raise SystemExit(
            "This benchmark currently requires a Unix-like platform "
            "(resource.getrusage); run it on Linux or macOS."
        )
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rows", type=int, default=2_000_000)
    parser.add_argument("--worker", choices=("fetchall", "bounded"))
    args = parser.parse_args()
    if args.rows < 1:
        parser.error("--rows must be a positive integer")
    if args.worker:
        print(json.dumps(worker(args.worker, args.rows)))
        return 0

    results = []
    for strategy in ("fetchall", "bounded"):
        completed = subprocess.run(
            [sys.executable, __file__, "--worker", strategy, "--rows", str(args.rows)],
            check=True,
            capture_output=True,
            text=True,
        )
        results.append(json.loads(completed.stdout))
    print(json.dumps({
        "note": "Peak RSS is process-wide and includes Python/DuckDB baseline memory.",
        "results": results,
        "peak_rss_difference_mib": round(
            results[0]["peak_rss_mib"] - results[1]["peak_rss_mib"], 2
        ),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
