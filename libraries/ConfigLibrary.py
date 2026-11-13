"""Keywords to read settings that are not exported by the variable file (secrets)."""

from robot.api.deco import keyword, library
from robot.api.types import Secret

import config_resolver


@library(scope="GLOBAL", auto_keywords=False)
class ConfigLibrary:
    @keyword("Get Required Config")
    def get_required_config(self, name: str) -> Secret:
        """Returns ``name`` wrapped in a ``Secret`` or fails explaining how to provide it.

        ``Secret`` (Robot Framework 7.4+) is shown as ``<secret>`` in logs and
        reports. Unwrap it with ``${value.value}`` only when passing it to a
        keyword that does not accept ``Secret``, and never log the unwrapped value."""
        return Secret(config_resolver.required(name))
