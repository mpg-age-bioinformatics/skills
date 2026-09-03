#!/usr/bin/env bash
set -euo pipefail

r_version="${1:-}"
agent="${2:-}"
project_dir="${3:-$(pwd -P)}"

if [[ -z "$r_version" || -z "$agent" ]]; then
  if [[ ! -t 0 ]]; then
    echo "Usage: $0 <R-version> <codex|claude> [project-directory]" >&2
    exit 2
  fi
  [[ -n "$r_version" ]] || read -r -p "R version (major.minor or major.minor.patch): " r_version
  [[ -n "$agent" ]] || read -r -p "Agent (codex or claude): " agent
fi

[[ "$r_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || { echo "Error: invalid R version." >&2; exit 2; }
case "$agent" in codex|claude) ;; *) echo "Error: agent must be codex or claude." >&2; exit 2 ;; esac
case "$project_dir" in
  //*) echo "Error: network and WSL project directories are not supported: $project_dir" >&2; exit 2 ;;
esac
if [[ "$project_dir" == /* && ! -e "$project_dir" ]]; then
  echo "Creating project directory: $project_dir"
  mkdir -p "$project_dir"
fi
[[ "$project_dir" == /* && -d "$project_dir" ]] || { echo "Error: project directory must be an absolute path." >&2; exit 2; }

asset_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
skill_dir="$(dirname -- "$asset_dir")"
"$skill_dir/scripts/setup-project.sh" "$project_dir" "$r_version" "$agent"
exec "$project_dir/code/run-r-sandbox.sh" "$agent"
