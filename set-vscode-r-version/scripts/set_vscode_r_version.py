#!/usr/bin/env python3
"""Set a folder-local VS Code R_VERSION override and user R settings."""

from __future__ import annotations

import json
import sys
from pathlib import Path


USER_R_SETTINGS = {
    "r.rterm.linux": "/nexus/posix0/MAGE-flaski/service/posit/rcs/R-vscode",
    "r.sessionWatcher": True,
    "r.alwaysUseActiveTerminal": True,
    "r.plot.useHttpgd": False,
    "workbench.panel.defaultLocation": "bottom",
}


def read_json_object(path: Path) -> dict:
    if not path.exists():
        return {}

    with path.open("r", encoding="utf-8") as handle:
        text = handle.read().strip()
    settings = json.loads(text) if text else {}
    if not isinstance(settings, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return settings


def write_json(path: Path, settings: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(settings, handle, indent=2)
        handle.write("\n")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: set_vscode_r_version.py PROJECT_DIR R_VERSION", file=sys.stderr)
        return 2

    project_dir = Path(sys.argv[1]).expanduser().resolve()
    r_version = sys.argv[2].strip()
    if not r_version:
        print("R_VERSION must not be empty", file=sys.stderr)
        return 2

    settings_path = project_dir / ".vscode" / "settings.json"
    settings = read_json_object(settings_path)

    env = settings.get("terminal.integrated.env.linux")
    if env is None:
        env = {}
    if not isinstance(env, dict):
        raise ValueError("terminal.integrated.env.linux must be a JSON object")

    env["R_VERSION"] = r_version
    settings["terminal.integrated.env.linux"] = env
    write_json(settings_path, settings)

    user_settings_path = Path.home() / ".vscode-server" / "User" / "settings.json"
    user_settings = read_json_object(user_settings_path)
    user_settings.update(USER_R_SETTINGS)
    write_json(user_settings_path, user_settings)

    print(settings_path)
    print(user_settings_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
