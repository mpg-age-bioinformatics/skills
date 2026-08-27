#!/usr/bin/env bash
set -euo pipefail

python_version="${1:-}"
agent="${2:-}"
project_dir="${3:-$(pwd -P)}"

if [[ -z "$python_version" || -z "$agent" ]]; then
  if [[ ! -t 0 ]]; then
    echo "Usage: $0 <Python-version> <codex|claude> [project-directory]" >&2
    exit 2
  fi
  echo "Python version and sandbox agent are required."
  if [[ -z "$python_version" ]]; then
    read -r -p "Python version (major.minor or major.minor.patch): " python_version
  fi
  if [[ -z "$agent" ]]; then
    read -r -p "Agent (codex or claude): " agent
  fi
fi

[[ "$python_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || {
  echo "Error: Python version must be major.minor or major.minor.patch." >&2
  exit 2
}
case "$agent" in
  codex|claude) ;;
  *) echo "Error: agent must be codex or claude." >&2; exit 2 ;;
esac
[[ "$project_dir" == /* && -d "$project_dir" ]] || {
  echo "Error: project directory must be an absolute existing path: $project_dir" >&2
  exit 2
}

asset_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
skill_dir="$(dirname -- "$asset_dir")"
setup_script="$skill_dir/scripts/setup-project.sh"
[[ -x "$setup_script" ]] || {
  echo "Error: python-sandbox setup script is unavailable: $setup_script" >&2
  exit 1
}

"$setup_script" "$project_dir" "$python_version" "$agent"
exec "$project_dir/code/run-python-sandbox.sh" "$agent"
