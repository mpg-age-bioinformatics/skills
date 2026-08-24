#!/usr/bin/env python3
"""Create a Jupyter notebook with the Nexus Python environment setup cell."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


FIRST_CELL = '''import os
import site
import sys
from pathlib import Path

username = os.environ.get("USER") or Path.home().name
python_major_minor = f"{sys.version_info.major}.{sys.version_info.minor}"
desired_user_base = Path(
    f"/nexus/posix0/MAGE-flaski/service/posit/home/{username}/.jupyter/python/{python_major_minor}"
)
desired_user_site = desired_user_base / "lib" / f"python{python_major_minor}" / "site-packages"

old_user_site = site.getusersitepackages()
os.environ["PYTHONUSERBASE"] = str(desired_user_base)
site.USER_BASE = str(desired_user_base)
site.USER_SITE = str(desired_user_site)
site.ENABLE_USER_SITE = True

if old_user_site in sys.path:
    sys.path.remove(old_user_site)
if desired_user_site.exists():
    site.addsitedir(str(desired_user_site))
    if str(desired_user_site) in sys.path:
        sys.path.remove(str(desired_user_site))
    sys.path.insert(0, str(desired_user_site))
else:
    raise FileNotFoundError(f"Expected user site-packages does not exist: {desired_user_site}")

print(sys.executable)
print(sys.version)
print(site.USER_BASE)
print(site.USER_SITE)
print(os.environ.get("PYTHONUSERBASE"))
print(sys.path[0])
'''


def notebook_path(value: str) -> Path:
    path = Path(value).expanduser()
    if path.suffix == "":
        path = path.with_suffix(".ipynb")
    elif path.suffix.lower() != ".ipynb":
        raise argparse.ArgumentTypeError("notebook name must use the .ipynb extension")
    return path


def build_notebook() -> dict[str, object]:
    return {
        "cells": [
            {
                "cell_type": "code",
                "execution_count": None,
                "id": "nexus-python-environment",
                "metadata": {},
                "outputs": [],
                "source": FIRST_CELL.splitlines(keepends=True),
            }
        ],
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3",
            },
            "language_info": {"name": "python"},
        },
        "nbformat": 4,
        "nbformat_minor": 5,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("name", type=notebook_path, help="output notebook name or path")
    parser.add_argument(
        "--force",
        action="store_true",
        help="replace an existing notebook (only with explicit user authorization)",
    )
    args = parser.parse_args()

    output: Path = args.name
    if output.exists() and not args.force:
        parser.error(f"refusing to overwrite existing file: {output}")

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(build_notebook(), indent=1) + "\n", encoding="utf-8")
    print(output.resolve())


if __name__ == "__main__":
    main()
