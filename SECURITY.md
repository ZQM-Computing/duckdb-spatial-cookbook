# Security policy

## Supported version

Security fixes are applied to the `main` branch. This repository contains examples and a local runner; it is not a hosted service.

## Reporting a vulnerability

Email **zqmcomputing@gmail.com** with the subject `duckdb-spatial-patterns security` if you find a vulnerability in the example code or workflow configuration. Please do not open a public issue for a sensitive report.

Include the affected file, the impact you observed, and reproduction steps when available.

## Extension note

The patterns install DuckDB's official `spatial` extension and the `h3` community extension at runtime. Community extensions are third-party code: in your own environment, pin the DuckDB version and source extensions from the official repositories, as the examples do.
