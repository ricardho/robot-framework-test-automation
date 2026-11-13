"""Writes one evidence PDF per test with fpdf2.

Layout: header table (test, suite, status, timing, execution details), failure section,
then numbered steps, each one kept together with its HTTP exchanges and screenshot.
"""

from __future__ import annotations

import io
import re
import unicodedata
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from fpdf import FPDF
from PIL import Image

STATUS_COLORS = {"PASS": (25, 135, 84), "FAIL": (200, 35, 51), "SKIP": (108, 117, 125)}
MAX_IMAGE_WIDTH_PX = 1280
FAILURE_LIMIT = 4000
HTTP_BODY_LIMIT = 1500


@dataclass
class Step:
    title: str
    status: str
    http: list[str] = field(default_factory=list)
    screenshot: bytes | None = None
    note: str | None = None


@dataclass
class TestEvidence:
    test: str
    suite: str
    started: datetime
    details: dict[str, str]
    steps: list[Step] = field(default_factory=list)
    status: str = "NOT RUN"
    message: str = ""
    elapsed_seconds: float = 0.0


def latin1(text: str) -> str:
    """Core PDF fonts are Latin-1 only (enough for Portuguese); other characters become '?'."""
    return str(text).encode("latin-1", "replace").decode("latin-1")


def safe_file_name(text: str, limit: int = 100) -> str:
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    return re.sub(r"[^A-Za-z0-9_-]+", "-", ascii_text).strip("-")[:limit] or "test"


def to_jpeg(png: bytes) -> Image.Image:
    """PNG screenshots make PDFs heavy; embed them as JPEG, downscaled to a sane width."""
    image = Image.open(io.BytesIO(png)).convert("RGB")
    if image.width > MAX_IMAGE_WIDTH_PX:
        ratio = MAX_IMAGE_WIDTH_PX / image.width
        image = image.resize((MAX_IMAGE_WIDTH_PX, int(image.height * ratio)))
    return image


class EvidencePdf(FPDF):
    def __init__(self) -> None:
        super().__init__(orientation="P", unit="pt", format="A4")
        self.set_margins(36, 36, 36)
        self.set_auto_page_break(auto=True, margin=36)
        self.set_image_filter("DCTDecode")  # JPEG inside the PDF
        self.alias_nb_pages()

    def footer(self) -> None:
        self.set_y(-28)
        self.set_font("helvetica", size=7)
        self.set_text_color(120, 120, 120)
        self.cell(0, 10, f"Page {self.page_no()}/{{nb}}", align="R")


def write_pdf(evidence: TestEvidence, output_dir: Path) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    stamp = evidence.started.strftime("%Y%m%d-%H%M%S-%f")[:-3]
    name = safe_file_name(f"{evidence.status}_{evidence.suite}_{evidence.test}")
    path = output_dir / f"{name}_{stamp}.pdf"

    pdf = EvidencePdf()
    pdf.add_page()
    width = pdf.epw

    pdf.set_font("helvetica", "B", 16)
    pdf.cell(0, 22, "Test Evidence", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(4)

    rows = [
        ("Test", evidence.test),
        ("Suite", evidence.suite),
        ("Status", evidence.status),
        ("Started", evidence.started.strftime("%Y-%m-%d %H:%M:%S")),
        ("Duration", f"{evidence.elapsed_seconds:.3f} s"),
        *evidence.details.items(),
    ]
    label_width = 110
    line_height = 14
    for label, value in rows:
        is_status = label == "Status"
        pdf.set_font("helvetica", "B" if is_status else "", 9)
        # Both cells of a row get the height of the value (which may wrap)
        lines = len(pdf.multi_cell(width - label_width, line_height, latin1(value), dry_run=True, output="LINES"))
        row_height = max(lines, 1) * line_height
        y = pdf.get_y()
        pdf.set_font("helvetica", "B", 9)
        pdf.set_text_color(0, 0, 0)
        pdf.set_fill_color(240, 240, 240)
        pdf.cell(label_width, row_height, latin1(label), border=1, fill=True)
        pdf.set_xy(pdf.l_margin + label_width, y)
        pdf.set_font("helvetica", "B" if is_status else "", 9)
        if is_status:
            pdf.set_text_color(*STATUS_COLORS.get(evidence.status, (0, 0, 0)))
        pdf.multi_cell(width - label_width, line_height, latin1(value), border=1, new_x="LMARGIN", new_y="NEXT")
        pdf.set_y(y + row_height)
    pdf.set_text_color(0, 0, 0)

    if evidence.status == "FAIL" or (evidence.status == "SKIP" and evidence.message):
        pdf.ln(10)
        pdf.set_font("helvetica", "B", 12)
        pdf.set_text_color(*STATUS_COLORS[evidence.status])
        pdf.cell(0, 16, "Failure" if evidence.status == "FAIL" else "Skip reason", new_x="LMARGIN", new_y="NEXT")
        pdf.set_font("courier", size=8)
        message = evidence.message[:FAILURE_LIMIT] + ("..." if len(evidence.message) > FAILURE_LIMIT else "")
        pdf.multi_cell(0, 10, latin1(message), new_x="LMARGIN", new_y="NEXT")
        pdf.set_text_color(0, 0, 0)

    pdf.ln(10)
    pdf.set_font("helvetica", "B", 12)
    pdf.cell(0, 16, "Steps and evidence", new_x="LMARGIN", new_y="NEXT")

    for number, step in enumerate(evidence.steps, start=1):
        image = to_jpeg(step.screenshot) if step.screenshot else None
        # Title, HTTP exchanges and screenshot of a step never get split across pages
        with pdf.unbreakable() as block:
            block.ln(4)
            block.set_font("helvetica", "B", 9)
            block.set_text_color(*STATUS_COLORS.get(step.status, (0, 0, 0)))
            block.multi_cell(0, 12, latin1(f"{number}. [{step.status}] {step.title}"), new_x="LMARGIN", new_y="NEXT")
            block.set_text_color(0, 0, 0)
            if step.note:
                block.set_font("helvetica", "I", 8)
                block.multi_cell(0, 10, latin1(step.note), new_x="LMARGIN", new_y="NEXT")
            for exchange in step.http:
                block.set_font("courier", size=7)
                block.set_fill_color(248, 248, 248)
                block.multi_cell(0, 9, latin1(exchange), border=1, fill=True, new_x="LMARGIN", new_y="NEXT")
            if image is not None:
                max_height = block.eph * 0.4
                image_width = min(width, max_height * image.width / image.height)
                block.image(image, w=image_width)
    pdf.output(str(path))
    return path
