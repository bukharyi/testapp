#!/usr/bin/env python3
"""Off-watch stress simulation for the Stress Face / Stress Alert apps.

This does not run the Monkey C code: Garmin's compiler and simulator are needed for that
(see README). It is a line-for-line Python copy of shared/StressLogic.mc. To keep the two
from drifting apart, it reads the thresholds and colours from the .mc file itself. It feeds
a stress scenario through the logic, checks the colours and beep counts, and renders what
the face looks like at each step to sim/output/.

Usage: python3 sim/simulate.py
"""
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
LOGIC_SRC = ROOT / "shared" / "StressLogic.mc"
OUT = Path(__file__).resolve().parent / "output"


def load_constants():
    text = LOGIC_SRC.read_text()
    consts = {k: int(v, 0) for k, v in re.findall(r"const (\w+) = (0x[0-9A-Fa-f]+|\d+);", text)}
    for name in ["STRESS_THRESHOLD", "LEVEL2_THRESHOLD", "LEVEL3_THRESHOLD", "HYSTERESIS",
                 "COLOR_CALM", "COLOR_STRESSED", "COLOR_UNKNOWN"]:
        if name not in consts:
            sys.exit(f"{name} not found in {LOGIC_SRC}")
    return consts


C = load_constants()


def is_valid(s):
    return s is not None and 0 <= s <= 100


def is_stressed(s):
    return is_valid(s) and s >= C["STRESS_THRESHOLD"]


def alert_level(s):
    if not is_stressed(s):
        return 0
    if s >= C["LEVEL3_THRESHOLD"]:
        return 3
    if s >= C["LEVEL2_THRESHOLD"]:
        return 2
    return 1


def background_color(s):
    if not is_valid(s):
        return C["COLOR_UNKNOWN"]
    return C["COLOR_STRESSED"] if is_stressed(s) else C["COLOR_CALM"]


def status_text(s):
    if not is_valid(s):
        return "NO DATA"
    return "STRESSED" if is_stressed(s) else "CALM"


class AlertTracker:
    def __init__(self):
        self.armed = 0

    def update(self, s):
        if not is_valid(s):
            return 0
        level = alert_level(s)
        if level > self.armed:
            self.armed = level
            return level
        relaxed = alert_level(min(s + C["HYSTERESIS"], 100))
        if relaxed < self.armed:
            self.armed = relaxed
        return 0


# (stress reading, expected beeps, expected colour name)
SCENARIO = [
    (20, 0, "blue"), (35, 0, "blue"), (55, 0, "blue"), (59, 0, "blue"),
    (60, 1, "red"), (66, 0, "red"), (58, 0, "blue"), (61, 0, "red"),   # wobble near 60: no repeat
    (76, 2, "red"), (82, 0, "red"), (91, 3, "red"), (100, 0, "red"),
    (None, 0, "black"),                                                # no reading (off wrist)
    (70, 0, "red"), (45, 0, "blue"), (30, 0, "blue"),
    (64, 1, "red"), (95, 3, "red"),                                    # jump straight to band 3
]
COLOUR_NAMES = {C["COLOR_CALM"]: "blue", C["COLOR_STRESSED"]: "red", C["COLOR_UNKNOWN"]: "black"}


def hex_rgb(v):
    return ((v >> 16) & 255, (v >> 8) & 255, v & 255)


def font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    try:
        return ImageFont.truetype(f"/usr/share/fonts/truetype/dejavu/{name}", size)
    except OSError:
        return ImageFont.load_default()


def render(stress, beeps, clock, size=260):
    """Rough picture of the Forerunner 945 face (260x260 round screen)."""
    bg = background_color(stress)
    fg = (255, 255, 255) if is_valid(stress) else (170, 170, 170)
    im = Image.new("RGB", (size, size), (40, 40, 40))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    face = Image.new("RGB", (size, size), hex_rgb(bg))
    im.paste(face, (0, 0), mask)
    d = ImageDraw.Draw(im)
    cx = size / 2
    d.text((cx, size * 0.14), "FRI 30 OCT", fill=fg, font=font(16), anchor="mt")
    d.text((cx, size * 0.40), clock, fill=fg, font=font(68, True), anchor="mm")
    value = str(stress) if is_valid(stress) else "--"
    d.text((cx, size * 0.62), f"STRESS {value}", fill=fg, font=font(24, True), anchor="mt")
    d.text((cx, size * 0.76), status_text(stress), fill=fg, font=font(16), anchor="mt")
    if beeps:
        d.text((cx, size * 0.86), "BEEP + BUZZ x" + str(beeps), fill=(255, 255, 0), font=font(14, True), anchor="mt")
    return im


def main():
    OUT.mkdir(exist_ok=True)
    tracker = AlertTracker()
    failures = []
    frames = []
    print(f"Thresholds from {LOGIC_SRC.name}: stressed >= {C['STRESS_THRESHOLD']}, "
          f"2 beeps >= {C['LEVEL2_THRESHOLD']}, 3 beeps >= {C['LEVEL3_THRESHOLD']}, "
          f"hysteresis {C['HYSTERESIS']}\n")
    print(f"{'step':>4}  {'stress':>6}  {'face':<6} {'status':<9} beeps")
    for i, (stress, want_beeps, want_colour) in enumerate(SCENARIO):
        beeps = tracker.update(stress)
        colour = COLOUR_NAMES[background_color(stress)]
        ok = beeps == want_beeps and colour == want_colour
        if not ok:
            failures.append((i, stress, beeps, want_beeps, colour, want_colour))
        print(f"{i:>4}  {str(stress):>6}  {colour:<6} {status_text(stress):<9} "
              f"{'*' * beeps or '-':<3} {'OK' if ok else 'FAIL'}")
        frames.append(render(stress, beeps, f"10:{i:02d}"))

    cols = 6
    tile = frames[0].width
    rows = (len(frames) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (tile + 10) + 10, rows * (tile + 10) + 10), (20, 20, 20))
    for i, f in enumerate(frames):
        sheet.paste(f, (10 + (i % cols) * (tile + 10), 10 + (i // cols) * (tile + 10)))
    sheet.save(OUT / "stress_simulation.png")
    print(f"\nRendered {len(frames)} frames to {OUT / 'stress_simulation.png'}")

    if failures:
        for f in failures:
            print("FAIL step %d stress=%s beeps=%d (want %d) colour=%s (want %s)" % f)
        sys.exit(1)
    print("All simulation checks passed.")


if __name__ == "__main__":
    main()
