"""Example 02: Nearest neighbor with DuckDB."""

import duckdb

con = duckdb.connect()
con.execute("INSTALL spatial; LOAD spatial;")

con.execute("""
    CREATE TABLE points AS
    SELECT * FROM (VALUES
        ('A', -80.93, 29.02),
        ('B', -80.92, 29.03),
        ('C', -80.91, 29.01)
    ) AS t(name, lon, lat)
""")

result = con.execute("""
    SELECT name, ST_Distance(
        ST_Point(lon, lat),
        ST_Point(-80.92, 29.02)
    ) AS dist
    FROM points
    ORDER BY dist
    LIMIT 3
""").fetchdf()
print("Nearest neighbors:")
print(result)
con.close()
