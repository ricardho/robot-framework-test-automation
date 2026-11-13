"""JSON Schema (draft 2020-12) validation for API responses."""

import json
from pathlib import Path

from jsonschema import Draft202012Validator
from referencing import Registry, Resource
from robot.api.deco import keyword, library

from config_resolver import PROJECT_ROOT

SCHEMA_DIR = PROJECT_ROOT / "resources" / "schemas"


def _load_registry(schema_dir: Path) -> tuple[Registry, dict[str, dict]]:
    """Every schema declares an ``$id`` (``urn:serverest:<name>``) so schemas can
    reference each other with ``$ref`` regardless of file location."""
    schemas = {path.name: json.loads(path.read_text(encoding="utf-8")) for path in schema_dir.glob("*.json")}
    registry = Registry().with_resources(
        (schema["$id"], Resource.from_contents(schema)) for schema in schemas.values()
    )
    return registry, schemas


@library(scope="GLOBAL", auto_keywords=False)
class JsonSchemaLibrary:
    def __init__(self) -> None:
        self._registry, self._schemas = _load_registry(SCHEMA_DIR)

    @keyword("Json Should Match Schema")
    def json_should_match_schema(self, data: object, schema_file: str) -> None:
        """Fails listing every violation when ``data`` does not match ``schema_file``
        (a file name inside ``resources/schemas``)."""
        if schema_file not in self._schemas:
            raise ValueError(f"Schema '{schema_file}' not found in {SCHEMA_DIR}. "
                             f"Available: {', '.join(sorted(self._schemas))}.")
        validator = Draft202012Validator(self._schemas[schema_file], registry=self._registry)
        errors = sorted(validator.iter_errors(data), key=lambda error: list(error.absolute_path))
        if errors:
            details = "\n".join(
                f"- {'/'.join(map(str, error.absolute_path)) or '<root>'}: {error.message}" for error in errors
            )
            raise AssertionError(f"Response does not match schema '{schema_file}':\n{details}")
