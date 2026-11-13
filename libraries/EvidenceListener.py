"""Robot Framework listener (API v3) that produces one evidence PDF per test.

EVIDENCE_MODE (config resolver / ``--variable``):
    failure  screenshot, URL and page source of the failing step; PDF only for failed tests
    always   + final screenshot of every test; PDF for every test
    steps    + screenshot after every Gherkin step (top-level keyword of the test)
EVIDENCE_PDF=false disables the PDF (captures still go to Allure).

Each top-level step also lists the HTTP exchanges made while it ran (masked), so API
tests get meaningful evidence too. Screenshots come from Browser Library (web) or
AppiumLibrary (native Android), whichever has an open page/app.

Evidence never changes a test result: every capture is wrapped and only logs a warning.
"""

from __future__ import annotations

import json
import platform
import tempfile
import threading
from datetime import datetime
from pathlib import Path

import requests
import robot
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn

import config_resolver
from evidence.masking import mask
from evidence.pdf_writer import Step, TestEvidence, safe_file_name, write_pdf

try:  # Allure is optional: without its listener these calls are no-ops
    import allure
except ImportError:  # pragma: no cover
    allure = None

HTTP_BODY_LIMIT = 1500
_state = threading.local()


def _record_http(request: requests.PreparedRequest, response: requests.Response) -> None:
    sink = getattr(_state, "sink", None)
    if sink is None:
        return
    body = request.body.decode("utf-8", "replace") if isinstance(request.body, bytes) else (request.body or "")
    try:  # requests escapes non-ASCII characters in JSON bodies (á); show them readable
        body = json.dumps(json.loads(body), ensure_ascii=False)
    except ValueError:
        pass
    text = f"{request.method} {request.url} -> HTTP {response.status_code}"
    if body:
        text += f"\nRequest: {body[:HTTP_BODY_LIMIT]}"
    text += f"\nResponse: {response.text[:HTTP_BODY_LIMIT]}"
    sink.append(mask(text))


_original_send = requests.Session.send


def _send_and_record(session, request, **kwargs):
    response = _original_send(session, request, **kwargs)
    try:
        _record_http(request, response)
    except Exception:  # noqa: BLE001 - evidence must never break a request
        pass
    return response


requests.Session.send = _send_and_record


class EvidenceListener:
    ROBOT_LISTENER_API_VERSION = 3

    def __init__(self) -> None:
        self.output_dir = config_resolver.PROJECT_ROOT / (config_resolver.get("EVIDENCE_DIR") or "results/evidence")
        self.evidence: TestEvidence | None = None
        self.mode = "failure"
        self.pdf_enabled = True
        self.failure_captured = False
        self.final_captured = False

    # ----- lifecycle -------------------------------------------------------------------------
    def start_test(self, data, result) -> None:
        builtin = BuiltIn()
        self.mode = str(builtin.get_variable_value("${EVIDENCE_MODE}", "failure")).lower()
        self.pdf_enabled = bool(builtin.get_variable_value("${EVIDENCE_PDF}", True))
        self.failure_captured = False
        self.final_captured = False
        self.evidence = TestEvidence(
            test=result.name,
            suite=result.parent.full_name if result.parent else "",
            started=datetime.now(),
            details=self._details(builtin, result.tags),
        )
        _state.sink = []

    def start_keyword(self, data, result) -> None:
        # The final screenshot is taken when the test teardown starts: the browser/app is
        # still open there, while end_test runs after the context has been closed.
        if self.evidence and result.type == "TEARDOWN" and self._is_test_level(result):
            self._capture_final()
            _state.sink = None  # cleanup requests are not part of the evidence

    def end_keyword(self, data, result) -> None:
        if not self.evidence or not self._is_test_level(result) or result.type == "TEARDOWN":
            return
        step = Step(title=self._title(result), status=result.status, http=list(_state.sink or []))
        _state.sink = []
        failed_here = result.status == "FAIL" and not self.failure_captured
        if failed_here:
            self.failure_captured = True
            step.screenshot = self._screenshot()
            step.note = self._failure_context()
            self._attach_to_allure(step.screenshot, "Failure screenshot")
        elif self.mode == "steps":
            step.screenshot = self._screenshot()
            self._attach_to_allure(step.screenshot, f"Step: {step.title}")
        self.evidence.steps.append(step)

    def end_test(self, data, result) -> None:
        evidence, self.evidence = self.evidence, None
        _state.sink = None
        if evidence is None:
            return
        if not self.final_captured:  # test without teardown
            self.evidence = evidence
            self._capture_final()
            self.evidence = None
        evidence.status = result.status
        evidence.message = mask(result.message or "")
        evidence.elapsed_seconds = result.elapsed_time.total_seconds()
        wanted = self.mode in ("always", "steps") or result.status == "FAIL"
        if not (self.pdf_enabled and wanted):
            return
        try:
            path = write_pdf(evidence, self.output_dir)
            if allure:
                allure.attach.file(str(path), name="Evidence PDF", attachment_type=allure.attachment_type.PDF)
        except Exception as error:  # noqa: BLE001
            logger.warn(f"Evidence PDF not written for '{evidence.test}': {error}")

    # ----- captures --------------------------------------------------------------------------
    def _capture_final(self) -> None:
        self.final_captured = True
        if self.mode not in ("always", "steps") or self.failure_captured:
            return
        image = self._screenshot()
        if image:
            self.evidence.steps.append(Step(title="Final state", status="INFO", screenshot=image))
            self._attach_to_allure(image, "Final screenshot")

    def _screenshot(self) -> bytes | None:
        return self._browser_screenshot() or self._appium_screenshot()

    @staticmethod
    def _browser_screenshot() -> bytes | None:
        try:
            browser = BuiltIn().get_library_instance("Browser")
        except RuntimeError:
            return None
        try:
            if not browser.get_page_ids("ACTIVE", "ACTIVE", "ACTIVE"):
                return None
            target = Path(tempfile.gettempdir()) / f"rf-evidence-{threading.get_ident()}"
            path = browser.take_screenshot(filename=str(target), log_screenshot=False)
            data = Path(path).read_bytes()
            Path(path).unlink(missing_ok=True)
            return data
        except Exception:  # noqa: BLE001 - no page open, browser closed...
            return None

    @staticmethod
    def _appium_screenshot() -> bytes | None:
        try:
            appium = BuiltIn().get_library_instance("AppiumLibrary")
            return appium._current_application().get_screenshot_as_png()  # noqa: SLF001
        except Exception:  # noqa: BLE001 - library not imported or no app open
            return None

    def _failure_context(self) -> str | None:
        """URL of the failing page; the page source is saved next to the PDF."""
        try:
            browser = BuiltIn().get_library_instance("Browser")
            if not browser.get_page_ids("ACTIVE", "ACTIVE", "ACTIVE"):
                return None
            url = browser.get_url()
            source = browser.get_page_source()
            self.output_dir.mkdir(parents=True, exist_ok=True)
            stamp = self.evidence.started.strftime("%Y%m%d-%H%M%S-%f")[:-3]
            html = self.output_dir / f"{safe_file_name('FAIL_' + self.evidence.test)}_{stamp}.html"
            html.write_text(mask(source), encoding="utf-8")
            return f"URL: {url} (page source saved as {html.name})"
        except Exception:  # noqa: BLE001
            return None

    @staticmethod
    def _attach_to_allure(image: bytes | None, name: str) -> None:
        if allure and image:
            try:
                allure.attach(image, name=name, attachment_type=allure.attachment_type.PNG)
            except Exception:  # noqa: BLE001
                pass

    # ----- helpers ---------------------------------------------------------------------------
    @staticmethod
    def _is_test_level(result) -> bool:
        return type(result.parent).__name__ == "TestCase"

    @staticmethod
    def _title(result) -> str:
        """Step name with embedded variables resolved, followed by its arguments."""
        builtin = BuiltIn()
        try:
            name = builtin.replace_variables(result.name)
        except Exception:  # noqa: BLE001
            name = result.name
        args = []
        for arg in result.args:
            try:
                args.append(str(builtin.replace_variables(arg)))
            except Exception:  # noqa: BLE001
                args.append(str(arg))
        return mask("    ".join([str(name), *args]))

    @staticmethod
    def _details(builtin: BuiltIn, tags) -> dict[str, str]:
        tags = {str(tag).lower() for tag in tags}
        get = builtin.get_variable_value
        details: dict[str, str] = {}
        if tags & {"web", "web-mobile", "hybrid"}:
            details["Application"] = str(get("${BASE_URL}"))
            details["Browser"] = f"{get('${BROWSER}')} (headless={get('${HEADLESS}')})"
        if tags & {"web-mobile"}:
            devices = [str(get("${MOBILE_DEVICE_IOS}")) if "ios" in tags else None,
                       str(get("${MOBILE_DEVICE_ANDROID}")) if "android" in tags else None]
            details["Device emulation"] = ", ".join(d for d in devices if d)
        if tags & {"api", "web", "hybrid", "web-mobile"}:
            details["API"] = str(get("${API_BASE_URL}"))
        if "mobile" in tags:
            details["Appium server"] = str(get("${APPIUM_URL}"))
            details["App"] = Path(str(get("${ANDROID_APP}"))).name
        details["Evidence mode"] = str(get("${EVIDENCE_MODE}"))
        details["Runtime"] = (f"{platform.system()} {platform.release()}, Python {platform.python_version()}, "
                              f"Robot Framework {robot.__version__}")
        return details
