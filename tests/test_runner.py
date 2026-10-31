"""Regression tests for bounded DuckDB result rendering."""
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from unittest.mock import patch

from scripts import run_examples


class FakeResult:
    description = [("value",)]

    def __init__(self):
        self.fetchmany_size = None

    def fetchmany(self, size):
        self.fetchmany_size = size
        return [(value,) for value in range(size)]

    def fetchall(self):
        raise AssertionError("run_file must not materialize the complete result")


class FakeConnection:
    def __init__(self, result):
        self.result = result
        self.statement = None

    def execute(self, statement):
        self.statement = statement
        return self.result


def test_run_file_fetches_only_display_limit_plus_one_rows(tmp_path: Path):
    sql_file = tmp_path / "large-result.sql"
    sql_file.write_text("SELECT value FROM synthetic_large_result;\n", encoding="utf-8")
    result = FakeResult()
    connection = FakeConnection(result)
    output = StringIO()

    with patch.object(run_examples, "ROOT", tmp_path), redirect_stdout(output):
        run_examples.run_file(connection, sql_file.name)

    assert result.fetchmany_size == run_examples.DISPLAY_ROW_LIMIT + 1
    assert connection.statement == "SELECT value FROM synthetic_large_result;"
    rendered = output.getvalue()
    assert "(11,)" in rendered
    assert "(12,)" not in rendered
    assert "additional rows omitted" in rendered
