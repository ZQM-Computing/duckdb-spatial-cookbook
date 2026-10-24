"""Example 03: ST_Distance in DuckDB spatial."""

import duckdb

con = duckdb.connect()
con.execute("INSTALL spatial; LOAD spatial;")
con.execute("SET geometry_always_xy = true;")

con.execute("""
    CREATE TABLE points AS
    SELECT * FROM (VALUES
        ('A', -80.93, 29.02),
        ('B', -80.92, 29.03),
        ('C', -80.91, 29.01)
    ) AS t(name, lon, lat)
""")

result = con.execute("""
    SELECT a.name AS from_pt, b.name AS to_pt,
           round(ST_Distance_Sphere(
               ST_Point(a.lon, a.lat), ST_Point(b.lon, b.lat)
           ), 2) AS dist_m
    FROM points a CROSS JOIN points b
    WHERE a.name < b.name
    ORDER BY dist_m
""").fetchdf()
print("Pairwise distances (m):")
print(result)
con.close()
""">