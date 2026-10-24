"""DuckDB spatial example."""
import duckdb
con = duckdb.connect()
con.execute("INSTALL spatial; LOAD spatial;")
con.execute("SET geometry_always_xy = true;")
print("ok")
con.close()
