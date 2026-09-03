#!/usr/bin/env bash
set -euo pipefail

agent="${1:-}"
project_dir="${2:-$(pwd -P)}"

if [[ -z "$agent" ]]; then
  if [[ ! -t 0 ]]; then
    echo "Usage: $0 <codex|claude> [project-directory]" >&2
    exit 2
  fi
  read -r -p "Sandbox agent (codex or claude): " agent
fi

case "$agent" in
  codex|claude) ;;
  *) echo "Error: agent must be codex or claude." >&2; exit 2 ;;
esac
case "$project_dir" in
  //*) echo "Error: network and WSL project directories are not supported: $project_dir" >&2; exit 2 ;;
esac
if [[ "$project_dir" == /* && ! -e "$project_dir" ]]; then
  echo "Creating project directory: $project_dir"
  mkdir -p "$project_dir"
fi
[[ "$project_dir" == /* && -d "$project_dir" ]] || {
  echo "Error: project directory must be an absolute path: $project_dir" >&2
  exit 2
}

asset_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
skill_dir="$(dirname -- "$asset_dir")"
setup_script="$skill_dir/scripts/setup-project.sh"
[[ -x "$setup_script" ]] || {
  echo "Error: bioinformatics-sandbox setup script is unavailable: $setup_script" >&2
  exit 1
}

"$setup_script" "$project_dir" "$agent"
exec "$project_dir/code/run-bioinformatics-sandbox.sh" "$agent"
