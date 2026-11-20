"""Render the Padel al Tanto guide from Garmin Connect IQ captures."""

import argparse
import json
from collections import OrderedDict
from functools import lru_cache
from pathlib import Path
from re import sub
from xml.sax.saxutils import escape

from PIL import Image
from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas
from reportlab.platypus import Paragraph


W, H = landscape(A4)
M = 42
CONTENT_W = W - 2 * M
FOOTER_TOP = H - 39
INK = HexColor("#172823")
MUTED = HexColor("#42574E")
ACCENT = HexColor("#076844")
RULE = HexColor("#CBD9D2")
TINT = HexColor("#EDF6F0")
DANGER = HexColor("#AE251F")
READING = HexColor("#185D97")
REGULAR = "Manual-Regular"
BOLD = "Manual-Bold"
DISPLAY = "Manual-Display"
APP_NAME = "Padel al Tanto"
DEFAULT_VERSION = "0.8.0"
FONTS = Path("/System/Library/Fonts/Supplemental")
TOC_TOP = 123
TOC_BOTTOM = FOOTER_TOP - 14
TOC_COL_GAP = 42
TOC_COL_W = (CONTENT_W - TOC_COL_GAP) / 2
TOC_GROUP_H = 29
TOC_GROUP_GAP = 13

# Button positions relative to the center of the illustrated watch.
BUTTON_CENTERS = {
    "LIGHT": (-152, 83),
    "UP": (-169, 0),
    "DOWN": (-152, -83),
    "START": (152, 83),
    "BACK": (152, -83),
}


def load_fonts(font_dir):
    filenames = {
        REGULAR: "Arial.ttf",
        BOLD: "Arial Bold.ttf",
        DISPLAY: "Arial Black.ttf",
    }
    for name, filename in filenames.items():
        pdfmetrics.registerFont(TTFont(name, str(font_dir / filename)))
    pdfmetrics.registerFontFamily(REGULAR, normal=REGULAR, bold=BOLD)


def printable(text):
    return text.translate(str.maketrans({"\u2011": "-", "\u2013": "-", "\u2014": "-"}))


def paragraph(text, width, size, leading, font=REGULAR, color=INK):
    markup = sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", escape(printable(text)))
    markup = markup.replace("\n", "<br/>")
    style = ParagraphStyle(
        name="manual",
        fontName=font,
        fontSize=size,
        textColor=color,
        leading=leading,
        splitLongWords=False,
    )
    flow = Paragraph(markup, style)
    _, height = flow.wrap(width, H)
    return flow, height


def fit_text(text, width, sizes, leading_ratio, max_height, context, **style):
    for size in sizes:
        flow, height = paragraph(text, width, size, size * leading_ratio, **style)
        if height <= max_height:
            return flow, height
    raise ValueError(f"Texto demasiado largo para {context}: {text!r}")


class Paper:
    """Draw on the page using distances measured from its top edge."""

    def __init__(self, pdf):
        self.pdf = pdf

    def label(self, text, x, baseline, size, font=REGULAR, color=INK, align="left"):
        self.pdf.setFillColor(color)
        self.pdf.setFont(font, size)
        text = printable(text)
        if align == "right":
            self.pdf.drawRightString(x, H - baseline, text)
        elif align == "center":
            self.pdf.drawCentredString(x, H - baseline, text)
        else:
            self.pdf.drawString(x, H - baseline, text)

    def place(self, measured, x, top):
        flow, height = measured
        flow.drawOn(self.pdf, x, H - top - height)

    def line(self, x1, y1, x2, y2, color=RULE, width=0.7):
        self.pdf.setStrokeColor(color)
        self.pdf.setLineWidth(width)
        self.pdf.line(x1, H - y1, x2, H - y2)

    def box(self, x, top, width, height, radius, fill=None, outline=None):
        if fill is not None:
            self.pdf.setFillColor(fill)
        if outline is not None:
            self.pdf.setStrokeColor(outline)
            self.pdf.setLineWidth(0.7)
        self.pdf.roundRect(
            x, H - top - height, width, height, radius,
            stroke=int(outline is not None), fill=int(fill is not None),
        )

    def circle(self, x, y, radius, outline, weight):
        self.pdf.setStrokeColor(outline)
        self.pdf.setLineWidth(weight)
        self.pdf.circle(x, H - y, radius, stroke=1, fill=0)

    def link(self, key, x, top, width, height):
        self.pdf.linkRect("", key, (x, H - top - height, x + width, H - top), thickness=0)

    def image(self, reader, x, top, width, height):
        self.pdf.drawImage(reader, x, H - top - height, width, height, mask="auto")

    def arrow(self, start, end, y, color=ACCENT, scale=1):
        direction = 1 if end > start else -1
        shoulder = end - direction * 6 * scale
        half_shaft = 1.18 * scale
        half_head = 3.6 * scale
        points = (
            (start, y - half_shaft),
            (shoulder, y - half_shaft),
            (shoulder, y - half_head),
            (end, y),
            (shoulder, y + half_head),
            (shoulder, y + half_shaft),
            (start, y + half_shaft),
        )
        path = self.pdf.beginPath()
        path.moveTo(points[0][0], H - points[0][1])
        for px, py in points[1:]:
            path.lineTo(px, H - py)
        path.close()
        self.pdf.saveState()
        self.pdf.setLineJoin(1)
        self.pdf.setStrokeColor(white)
        self.pdf.setLineWidth(1.3 * scale)
        self.pdf.setFillColor(color)
        self.pdf.drawPath(path, stroke=1, fill=1)
        self.pdf.restoreState()

    def cross(self, x, y):
        radius = 3.7
        for color, weight in ((white, 5.1), (DANGER, 2.8)):
            self.line(x - radius, y - radius, x + radius, y + radius, color, weight)
            self.line(x - radius, y + radius, x + radius, y - radius, color, weight)

    def focus(self, x, y, half_w, half_h, arm, color, weight=2.05):
        path = self.pdf.beginPath()
        for horizontal in (-1, 1):
            for vertical in (-1, 1):
                corner_x, corner_y = x + horizontal * half_w, y + vertical * half_h
                path.moveTo(corner_x - horizontal * arm, H - corner_y)
                path.lineTo(corner_x, H - corner_y)
                path.lineTo(corner_x, H - corner_y + vertical * arm)
        self.pdf.saveState()
        self.pdf.setLineJoin(1)
        self.pdf.setLineCap(1)
        for stroke, stroke_weight in ((white, weight + 1.5), (color, weight)):
            self.pdf.setStrokeColor(stroke)
            self.pdf.setLineWidth(stroke_weight)
            self.pdf.drawPath(path, stroke=1, fill=0)
        self.pdf.restoreState()


def image_path(imgdir, screen):
    name = str(screen)
    if name.endswith(".png"):
        return imgdir / name
    return imgdir / f"{name}.png"


class Watch:
    width = 432
    height = 570
    display_size = 260

    def __init__(self, captures):
        expected = self.display_size, self.display_size
        self.captures = {}
        for capture in sorted(captures):
            with Image.open(capture) as image:
                if image.size != expected:
                    raise ValueError(f"{capture}: se esperaba esfera de {expected[0]} × {expected[1]} px")
                pixels = image.convert("RGB")
            self.captures[capture] = ImageReader(pixels), pixels

    def draw_case(self, pdf, center, middle, scale):
        pdf.saveState()
        pdf.translate(center, H - middle)
        pdf.scale(scale, scale)
        pdf.setFillColor(HexColor("#40534B"))
        pdf.roundRect(-69, -self.height / 2 + 15, 138, self.height - 30, 24, stroke=0, fill=1)
        pdf.setFillColor(HexColor("#5C6B62"))
        pdf.roundRect(-85, -181, 170, 362, 21, stroke=0, fill=1)
        for x, y in BUTTON_CENTERS.values():
            pdf.roundRect(x - 14, y - 16, 28, 32, 7, stroke=0, fill=1)
        for radius, color in ((166, "#293A34"), (155, "#546860"), (146, "#192722")):
            pdf.setFillColor(HexColor(color))
            pdf.circle(0, 0, radius, stroke=0, fill=1)
        pdf.restoreState()

    def draw(self, sheet, capture, target, center, top, height):
        scale = height / self.height
        middle = top + height / 2
        screen, pixels = self.captures[capture]
        size = self.display_size * scale
        self.draw_case(sheet.pdf, center, middle, scale)
        sheet.pdf.saveState()
        aperture = sheet.pdf.beginPath()
        aperture.circle(center, H - middle, size / 2)
        sheet.pdf.clipPath(aperture, stroke=0, fill=0)
        sheet.image(screen, center - size / 2, middle - size / 2, size, size)
        sheet.pdf.restoreState()
        if target is None:
            return

        def display_point(x, y):
            return center - size / 2 + x * scale, middle - size / 2 + y * scale

        def button(name, avoid=False, label=None):
            if name == "MENU":
                name = "UP"
            if name not in BUTTON_CENTERS:
                raise ValueError(f"Botón desconocido: {name!r}")
            button_x, button_y = BUTTON_CENTERS[name]
            x, y = center + button_x * scale, middle - button_y * scale
            direction = -1 if button_x < 0 else 1
            radius = max(6.0, scale * 14)
            color = DANGER if avoid else ACCENT
            end = x + direction * (radius + 2)
            start = end + direction * (13 if label else 16)
            sheet.circle(x, y, radius, white, 4.0)
            sheet.circle(x, y, radius, color, 2.1)
            sheet.arrow(start, end, y, color)
            if avoid:
                sheet.cross(start + direction * 3, y)
            if label:
                sheet.label(label, start, y - 7, 7.8, BOLD, ACCENT, "center")

        def touch(x, y, bounds=None, avoid=False, read=False):
            if bounds is None:
                half_w, half_h, arm = (value * scale for value in focus_size(pixels, x, y, scale))
            else:
                half_w, half_h = (value * scale for value in bounds)
                arm = 4.5
            target_x, target_y = display_point(x, y)
            color = READING if read else (DANGER if avoid else ACCENT)
            sheet.focus(target_x, target_y, half_w, half_h, arm, color)
            if avoid:
                direction = -1 if x < self.display_size / 2 else 1
                sheet.cross(target_x + direction * (half_w + 6.5), target_y)

        if isinstance(target, str):
            button(target)
        elif target[0] == "buttons":
            for name in target[1]:
                button(name)
        elif target[0] == "controls":
            for name in ("LIGHT", "UP", "DOWN", "START", "BACK"):
                button(name, label="UP/MENU" if name == "UP" else name)
        elif target[0] == "avoid" and len(target) == 2:
            button(target[1], avoid=True)
        elif target[0] == "avoid":
            touch(*target[1:], avoid=True)
        elif target[0] == "read":
            touch(*target[1:], read=True)
        elif target[0] == "touch":
            touch(*target[1:])
        elif target[0] == "left":
            y = swipe_path(pixels)
            start_x, line_y = display_point(238, y)
            end_x, _ = display_point(32, y)
            sheet.arrow(start_x - 3.5, end_x, line_y, scale=1.25)
            sheet.circle(start_x, line_y, 3.5, white, 3.5)
            sheet.circle(start_x, line_y, 3.5, ACCENT, 1.9)
        elif len(target) == 2 and all(isinstance(value, (int, float)) for value in target):
            touch(*target)
        else:
            raise ValueError(f"Indicación desconocida: {target!r} para {capture.name}")


def visible_pixel(pixels, x, y):
    return max(pixels.getpixel((x, y))) > 100


def focus_size(pixels, x, y, scale):
    """Size the corners without moving the supplied center or crossing screen text."""
    width, height = pixels.size
    x, y = round(x), round(y)
    if not (0 <= x < width and 0 <= y < height):
        raise ValueError(f"Coordenadas ({x}, {y}) fuera de la pantalla")
    offset = round(1.5 / scale)
    arm = round(4.5 / scale)
    radius_squared = (width / 2 - 2)**2

    def obstruction(px, py):
        if (px - width / 2)**2 + (py - height / 2)**2 > radius_squared:
            return 4
        return visible_pixel(pixels, px, py)

    def cost(candidate):
        half_w, half_h = candidate
        collisions = 0
        perimeter = 0
        for horizontal in (-1, 1):
            for vertical in (-1, 1):
                cx, cy = x + horizontal * half_w, y + vertical * half_h
                for part in range(0, arm + 1, 2):
                    for side in (-offset, 0, offset):
                        collisions += obstruction(cx - horizontal * part, cy + side)
                        collisions += obstruction(cx + side, cy - vertical * part)
                perimeter += sum(
                    obstruction(cx - horizontal * part, cy)
                    for part in range(arm + 1, half_w + 1, 2)
                )
                perimeter += sum(
                    obstruction(cx, cy - vertical * part)
                    for part in range(arm + 1, half_h + 1, 2)
                )
        return collisions + 0.55 * perimeter + 0.13 * half_w + 0.25 * half_h

    sizes = (
        (w, h)
        for w in (15, 20, 26, 32, 40, 45, 49, 57, 68, 79, 88, 98)
        for h in (11, 15, 19, 24, 28, 31, 35)
    )
    half_w, half_h = min(sizes, key=cost)
    return half_w, half_h, arm


def swipe_path(pixels):
    """Pick a horizontal lane with minimal overlap on the original dial capture."""
    return min(
        range(76, 185),
        key=lambda y: (
            sum(
                visible_pixel(pixels, x, row)
                for x in range(32, 239)
                for row in range(y - 7, y + 8)
            ),
            abs(y - 130),
        ),
    )


def page_header(sheet, section, index_link=True):
    brand = APP_NAME.upper()
    separator = M + pdfmetrics.stringWidth(brand, BOLD, 10) + 12
    sheet.label(brand, M, 29, 10, BOLD, ACCENT)
    sheet.line(separator, 19, separator, 31)
    sheet.label(section, separator + 12, 29, 10, REGULAR, MUTED)
    if index_link:
        sheet.label("Índice", W - M - 13, 29, 9.5, BOLD, ACCENT, "right")
        sheet.arrow(W - M - 8, W - M, 26, scale=0.62)
        sheet.link("indice", W - M - 55, 15, 56, 22)
    sheet.line(M, 42, W - M, 42)


def page_footer(sheet, number, total, version):
    sheet.line(M, FOOTER_TOP, W - M, FOOTER_TOP)
    sheet.label(f"Manual ilustrado  ·  Versión {version}", M, H - 22, 9.2, REGULAR, MUTED)
    sheet.label(f"{number} / {total}", W - M, H - 22, 9.2, BOLD, ACCENT, "right")


def draw_cover(sheet, watch, cover, total, version):
    sheet.pdf.bookmarkPage("portada")
    sheet.pdf.addOutlineEntry("Portada", "portada")
    sheet.line(M, 45, W - M, 45)
    sheet.label("MANUAL ILUSTRADO", M + 15, 163, 11, BOLD, ACCENT)
    sheet.label(APP_NAME, M + 12, 266, 48, DISPLAY)
    sheet.line(M + 16, 294, M + 57, 294, ACCENT, 2.5)
    sheet.label("Garmin fēnix 7 Pro", M + 15, 337, 25)
    sheet.arrow(M + 15, M + 29, 371, scale=0.88)
    sheet.label("Pulsa o desliza", M + 40, 374.5, 10.8, REGULAR, INK)
    sheet.focus(M + 23, 390, 6, 4.6, 2.8, ACCENT, 1.5)
    sheet.label("Toca la zona marcada", M + 40, 393.5, 10.8, REGULAR, INK)
    sheet.focus(M + 23, 409, 6, 4.6, 2.8, READING, 1.5)
    sheet.label("Dato para consultar", M + 40, 412.5, 10.8, REGULAR, INK)
    sheet.cross(M + 23, 428)
    sheet.label("Acción que conviene evitar", M + 40, 431.5, 10.8, REGULAR, INK)
    sheet.box(M + 15, 455, 108, 33, 6, fill=TINT)
    sheet.label("Ir al índice", M + 28, 476, 11, BOLD, ACCENT)
    sheet.arrow(M + 98, M + 112, 472, scale=0.88)
    sheet.link("indice", M + 15, 455, 108, 33)
    watch.draw(sheet, cover, None, W - M - 176, 74, 445)
    sheet.label(
        "Capturas del simulador Connect IQ · fēnix 7 y fēnix 7 Pro",
        W - M - 176, 531, 9, REGULAR, MUTED, "center",
    )
    page_footer(sheet, 1, total, version)
    sheet.pdf.showPage()


def index_groups(pages):
    grouped = OrderedDict()
    for i, page in enumerate(pages):
        row = paragraph(page["title"], TOC_COL_W - 43, 12.2, 15.2)
        grouped.setdefault(page["section"], []).append((i, row, max(24, row[1] + 9)))

    capacity = TOC_BOTTOM - TOC_TOP
    groups = []
    for section, rows in grouped.items():
        part, height = [], TOC_GROUP_H + TOC_GROUP_GAP
        heading = section
        for row in rows:
            if part and height + row[2] > capacity:
                groups.append((heading, part, height))
                part, height = [], TOC_GROUP_H + TOC_GROUP_GAP
                heading = f"{section} (continuación)"
            part.append(row)
            height += row[2]
        groups.append((heading, part, height))
    return groups


def index_columns(groups):
    """Keep section headings with their rows and balance the two-column spreads."""
    capacity = TOC_BOTTOM - TOC_TOP
    num_groups = len(groups)
    total_height = sum(group[2] for group in groups)
    for spread_size in range(2, num_groups + 2, 2):
        num_columns = min(spread_size, num_groups)
        average_height = total_height / num_columns

        @lru_cache
        def partition(start, remaining):
            if remaining == 0:
                return (0, ()) if start == num_groups else None
            best = None
            height = 0
            for end in range(start + 1, num_groups - remaining + 2):
                height += groups[end - 1][2]
                if height > capacity:
                    break
                tail = partition(end, remaining - 1)
                if tail is None:
                    continue
                cost = (height - average_height)**2 + tail[0]
                if best is None or cost < best[0]:
                    best = cost, (end, *tail[1])
            return best

        result = partition(0, num_columns)
        if result is not None:
            edges = (0, *result[1])
            return [groups[start:end] for start, end in zip(edges, edges[1:])]
    raise ValueError("El índice no cabe en el área de impresión.")


def draw_index(sheet, columns, index_count, total, version):
    for index_no in range(index_count):
        if index_no == 0:
            sheet.pdf.bookmarkPage("indice")
            sheet.pdf.addOutlineEntry("Índice", "indice")
        else:
            key = f"indice_{index_no + 1}"
            sheet.pdf.bookmarkPage(key)
            sheet.pdf.addOutlineEntry("Índice (continuación)", key)
        page_header(sheet, "Garmin fēnix 7 Pro", index_link=False)
        sheet.label("Índice" if index_no == 0 else "Índice (continuación)", M, 99, 43, DISPLAY)
        if index_no:
            x = W - M - (124 if index_no + 1 < index_count else 57)
            sheet.arrow(x + 10, x, 92, scale=0.75)
            sheet.label("Anterior", x + 16, 95.5, 10, BOLD, ACCENT)
            prev_key = "indice" if index_no == 1 else f"indice_{index_no}"
            sheet.link(prev_key, x - 4, 82, 63, 23)
        if index_no + 1 < index_count:
            sheet.label("Siguiente", W - M - 16, 95.5, 10, BOLD, ACCENT, "right")
            sheet.arrow(W - M - 10, W - M, 92, scale=0.75)
            sheet.link(f"indice_{index_no + 2}", W - M - 65, 82, 69, 23)
        spread = columns[index_no * 2:index_no * 2 + 2]
        for column, groups in enumerate(spread):
            x = M + column * (TOC_COL_W + TOC_COL_GAP)
            y = TOC_TOP
            for section, rows, _ in groups:
                heading = fit_text(
                    section, TOC_COL_W, (12.5, 11.5), 1.14, 24,
                    f"la sección del índice {section!r}", font=BOLD, color=ACCENT,
                )
                sheet.place(heading, x, y + 1)
                y += TOC_GROUP_H
                for i, row, height in rows:
                    sheet.line(x, y, x + TOC_COL_W, y)
                    sheet.place(row, x, y + (height - row[1]) / 2)
                    sheet.label(
                        str(i + index_count + 2), x + TOC_COL_W - 3,
                        y + (height + 8) / 2, 10.5, BOLD, ACCENT, "right",
                    )
                    sheet.link(f"pagina_{i}", x, y, TOC_COL_W, height)
                    y += height
                y += TOC_GROUP_GAP
        page_footer(sheet, index_no + 2, total, version)
        sheet.pdf.showPage()


def step_copy(steps, width, height, page_title):
    headings = [
        fit_text(
            step[2], width - 25, (15.0, 14.0), 1.16, 47,
            f"el título del paso {i + 1} de {page_title!r}", font=BOLD,
        )
        for i, step in enumerate(steps)
    ]
    for size in (12.2, 11.7, 11.2):
        descriptions = [paragraph(step[3], width, size, size * 1.28) for step in steps]
        tallest = max(title[1] + 6 + body[1] for title, body in zip(headings, descriptions))
        if tallest <= height:
            return list(zip(headings, descriptions)), tallest
    raise ValueError(f"Reduce el texto de los pasos de {page_title!r} para conservar el tamaño de la esfera.")


def place_step(sheet, copy, number, x, y):
    title, body = copy
    sheet.box(x, y - 1, 18, 18, 9, fill=TINT)
    sheet.label(str(number), x + 9, y + 11.7, 9.5, BOLD, ACCENT, "center")
    sheet.place(title, x + 25, y)
    sheet.place(body, x, y + title[1] + 6)


def draw_steps(sheet, watch, imgdir, steps, title, top, bottom):
    count = len(steps)
    if count == 1:
        height = min(bottom - top - 22, 355)
        screen, target, _, _ = steps[0]
        sheet.box(M, top, CONTENT_W, bottom - top, 9, outline=RULE)
        watch.draw(sheet, image_path(imgdir, screen), target, M + CONTENT_W / 4, top + 11, height)
        copy, copy_h = step_copy(steps, CONTENT_W / 2 - 66, height - 10, title)
        place_step(sheet, copy[0], 1, M + CONTENT_W / 2 + 20, top + (bottom - top - copy_h) / 2)
        return

    gap = 13
    width = (CONTENT_W - gap * (count - 1)) / count
    inset = 14
    panel_h = bottom - top
    fixed_gaps = 9 + 8 + 13
    copy, text_height = step_copy(steps, width - 2 * inset, panel_h - fixed_gaps - 190, title)
    width_for_watch = width - 43
    if any(step[1] in (("controls",), ["controls"]) for step in steps):
        width_for_watch = width - 58
    figure_h = min(panel_h - fixed_gaps - text_height, 282, width_for_watch * watch.height / watch.width)
    for i, ((screen, target, _, _), text) in enumerate(zip(steps, copy)):
        x = M + i * (width + gap)
        sheet.box(x, top, width, panel_h, 9, outline=RULE)
        watch.draw(sheet, image_path(imgdir, screen), target, x + width / 2, top + 9, figure_h)
        place_step(sheet, text, i + 1, x + inset, top + 9 + figure_h + 8)


def draw_page(sheet, watch, imgdir, page, i, index_count, total, version, new_section):
    key = f"pagina_{i}"
    if new_section:
        section_key = f"seccion_{i}"
        sheet.pdf.bookmarkPage(section_key)
        sheet.pdf.addOutlineEntry(page["section"], section_key, closed=True)
    sheet.pdf.bookmarkPage(key)
    sheet.pdf.addOutlineEntry(page["title"], key, level=1)

    page_header(sheet, page["section"])
    title = fit_text(
        page["title"], CONTENT_W, (32, 30, 28), 1.12, 65,
        "el título de página", font=DISPLAY,
    )
    sheet.place(title, M, 55)
    top = 55 + title[1] + 9
    if page.get("intro"):
        intro = fit_text(
            page["intro"], CONTENT_W, (12.8, 12, 11.6), 1.32, 39,
            f"la introducción de {page['title']!r}", color=MUTED,
        )
        sheet.place(intro, M, top)
        top += intro[1] + 15
    else:
        top += 8

    bottom = FOOTER_TOP - 14
    if page.get("tip"):
        tip = fit_text(
            page["tip"], CONTENT_W - 30, (11.4, 10.8), 1.32, 46,
            f"la nota de {page['title']!r}",
        )
        tip_h = tip[1] + 16
        tip_top = bottom - tip_h
        sheet.box(M, tip_top, CONTENT_W, tip_h, 6, fill=TINT)
        sheet.line(M + 2.5, tip_top + 7.5, M + 2.5, bottom - 7.5, ACCENT, 2.0)
        sheet.place(tip, M + 13, tip_top + 8)
        bottom = tip_top - 11

    draw_steps(sheet, watch, imgdir, page["steps"], page["title"], top, bottom)
    page_footer(sheet, i + index_count + 2, total, version)
    sheet.pdf.showPage()


def build(
    pages, imgdir, destination, *, version=DEFAULT_VERSION,
    cover_screen="play30", font_dir=FONTS,
):
    """Build a searchable, self-contained PDF with internally linked contents.

    Each page has a title, up to three (capture, target, title, body) step
    tuples, and optional intro, tip and section text. Capture names refer to
    unscaled PNG exports of the dial, without the surrounding device frame.
    """
    load_fonts(Path(font_dir))
    imgdir = Path(imgdir)
    pages = [dict(page, section=page.get("section") or "Guía de uso") for page in pages]
    if not pages:
        raise ValueError("El manual necesita al menos una página de instrucciones.")
    cover = image_path(imgdir, cover_screen)
    captures = {cover}
    for page in pages:
        if not 1 <= len(page["steps"]) <= 3:
            raise ValueError(f"{page['title']!r}: se requieren entre uno y tres pasos.")
        captures.update(image_path(imgdir, step[0]) for step in page["steps"])
    missing = sorted(path.name for path in captures if not path.is_file())
    if missing:
        raise FileNotFoundError(f"Faltan capturas en {imgdir}: {', '.join(missing)}")

    watch = Watch(captures)
    columns = index_columns(index_groups(pages))
    index_count = (len(columns) + 1) // 2
    total = 1 + index_count + len(pages)
    pdf = Canvas(str(destination), pagesize=(W, H), pageCompression=1, lang="es")
    pdf.setTitle(f"{APP_NAME} - Manual ilustrado")
    pdf.setSubject(f"Guía de uso para Garmin fēnix 7 Pro, versión {version}")
    pdf.setAuthor(APP_NAME)
    sheet = Paper(pdf)

    draw_cover(sheet, watch, cover, total, version)
    draw_index(sheet, columns, index_count, total, version)
    previous_section = None
    for i, page in enumerate(pages):
        draw_page(
            sheet, watch, imgdir, page, i, index_count, total, version,
            new_section=page["section"] != previous_section,
        )
        previous_section = page["section"]
    pdf.save()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("data", type=Path, help="archivo JSON con la lista de páginas")
    parser.add_argument("imgdir", type=Path, help="carpeta con las capturas PNG de esfera")
    parser.add_argument("destination", type=Path, help="ruta del PDF de salida")
    parser.add_argument("--version", default=DEFAULT_VERSION)
    parser.add_argument("--cover-screen", default="play30")
    parser.add_argument("--font-dir", type=Path, default=FONTS)
    args = parser.parse_args()
    build(
        json.loads(args.data.read_text(encoding="utf-8")),
        args.imgdir, args.destination, version=args.version,
        cover_screen=args.cover_screen, font_dir=args.font_dir,
    )


if __name__ == "__main__":
    main()
