"""Example 01: Spatial joins with DuckDB."""

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

con.execute("""
    CREATE TABLE zones AS
    SELECT * FROM (VALUES
        ('north', [[-80.95, 29.05], [-80.90, 29.05], [-80.90, 29.00], [-80.95, 29.00], [-80.95, 29.05]])
    ) AS t(name, coords)
""")

result = con.execute("""
    SELECT p.name, z.name as zone
    FROM points p
    JOIN zones z ON ST_Within(
        ST_Point(p.lon, p.lat),
        ST_Polygon(ST_GeomFromText('LINESTRING(-80.95 29.05, -80.90 29.05, -80.90 29.00, -80.95 29.00, -80.95 29.05)'))
    )
""").fetchdf()
print("Spatial join result:")
print(result)
con.close()
