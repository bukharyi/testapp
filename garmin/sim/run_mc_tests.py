#!/usr/bin/env python3
"""Runs the assertions in shared/StressLogicTests.mc against the Python copy of the logic.

A cross-check for machines without the Connect IQ SDK. The real tests run on Garmin's
simulator (see README).
"""
import re
import sys
from pathlib import Path

import simulate as logic

TESTS_SRC = Path(__file__).resolve().parent.parent / "shared" / "StressLogicTests.mc"


def to_python(expr):
    expr = expr.replace("null", "None")
    expr = re.sub(r"StressLogic\.(COLOR_\w+)", r"logic.C['\1']", expr)
    expr = expr.replace("StressLogic.backgroundColor", "logic.background_color")
    expr = expr.replace("StressLogic.alertLevel", "logic.alert_level")
    expr = expr.replace("t.currentLevel()", "t.armed")
    return expr


def main():
    text = TESTS_SRC.read_text()
    tests = re.findall(r"function (\w+)\(logger as Test\.Logger\) as Boolean \{(.*?)\n\}", text, re.S)
    failed = 0
    for name, body in tests:
        env = {"logic": logic, "t": logic.AlertTracker()}
        count = 0
        for actual, expected in re.findall(r"Test\.assertEqual\((.+?), ([\w.]+)\);", body):
            count += 1
            got = eval(to_python(actual), env)
            want = eval(to_python(expected), env)
            if got != want:
                failed += 1
                print(f"FAIL {name}: {actual} = {got}, expected {want}")
        print(f"{name}: {count} assertions")
    if failed or not tests:
        sys.exit(1)
    print(f"All {len(tests)} test functions passed.")


if __name__ == "__main__":
    main()
