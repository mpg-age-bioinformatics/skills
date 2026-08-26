#!/usr/bin/env bash
set -euo pipefail

agent="${1:-}"
if [[ "$agent" != "codex" && "$agent" != "claude" ]]; then
  echo "Usage: $0 <codex|claude>" >&2
  exit 2
fi

project_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
project_name="$(basename -- "$project_root" | tr '[:upper:]_' '[:lower:]-' | tr -cd 'a-z0-9.-')"
if [[ -z "$project_name" ]]; then
  echo "Error: project directory name does not contain a valid sandbox-name character." >&2
  exit 2
fi

sandbox_name="bio-${project_name}-${agent}"
if ! command -v sbx >/dev/null 2>&1; then
  echo "Error: Docker Sandboxes CLI (sbx) is not installed on the host." >&2
  exit 1
fi

echo "Sandbox: $sandbox_name"
echo "VS Code Remote-SSH host: ${sandbox_name}.sbx"
echo "Workspace: $project_root"
exec sbx run --name "$sandbox_name" "$agent" "$project_root"
