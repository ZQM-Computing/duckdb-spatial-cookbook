# Contributing

Thanks for helping make these patterns more useful.

## Ground rules

1. **Everything must run.** `python scripts/run_examples.py` passes from a clean checkout, in CI and locally. If a pattern needs a new extension or data file, wire it into the setup and the runner.
2. **Pin the behavior.** Any pattern whose result could drift between DuckDB versions gets a matching row in `tests/checks.sql`.
3. **Synthetic data only.** No real parcel, utility, customer, infrastructure-sensitive, or personally identifying data in examples, fixtures, or screenshots.
4. **Document the trap, not just the trick.** If a pattern exists because a naive approach silently misleads (axis order, degree distances), show the wrong result and label it.
5. **State versions.** Note the DuckDB version you verified on — extension behavior, especially community extensions, moves fast.

## Style

- Pattern files are numbered in reading order and runnable in sequence after `sql/00_setup.sql`.
- SQL keywords uppercase; comments explain *why*, in the voice of the existing files.
