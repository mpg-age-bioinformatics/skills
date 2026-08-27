#!/usr/bin/env bash
set -euo pipefail

agent="${1:-}"
case "$agent" in
  codex) agent_template="codex" ;;
  claude) agent_template="claude-code" ;;
  *) echo "Usage: $0 <codex|claude>" >&2; exit 2 ;;
esac

project_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
project_name="$(basename -- "$project_root" | tr '[:upper:]_' '[:lower:]-' | tr -cd 'a-z0-9.-')"
[[ -n "$project_name" ]] || { echo "Error: invalid project directory name." >&2; exit 2; }
command -v docker >/dev/null 2>&1 || { echo "Error: Docker CLI is required to build the sandbox template." >&2; exit 1; }
command -v sbx >/dev/null 2>&1 || { echo "Error: Docker Sandboxes CLI (sbx) is not installed." >&2; exit 1; }

sandbox_name="py-${project_name}-${agent}"
template_tag="python-sandbox-${project_name}-${agent}:local"
template_tar="$(mktemp "${TMPDIR:-/tmp}/python-sandbox-template.XXXXXX.tar")"
trap 'rm -f "$template_tar"' EXIT

docker build --build-arg "AGENT_TEMPLATE=$agent_template" -t "$template_tag" -f "$project_root/code/Dockerfile" "$project_root/code"
docker image save "$template_tag" -o "$template_tar"
sbx template load "$template_tar"

echo "Sandbox: $sandbox_name"
echo "VS Code Remote-SSH host: ${sandbox_name}.sbx"
echo "Workspace: $project_root"

if sbx ls --quiet | grep -Fqx "$sandbox_name"; then
  sbx run --detached --name "$sandbox_name"
else
  sbx run --detached --name "$sandbox_name" --template "$template_tag" "$agent" "$project_root"
fi

python_series="$(sed -n 's/^ARG PYTHON_IMAGE=python:\([0-9][0-9]*\.[0-9][0-9]*\)-bookworm$/\1/p' "$project_root/code/Dockerfile")"
[[ -n "$python_series" ]] || { echo "Error: could not determine the Python series from code/Dockerfile." >&2; exit 1; }
sbx exec --env "EXPECTED_PYTHON_SERIES=$python_series" --workdir "$project_root" "$sandbox_name" sh -c \
  'set -e; test -x .venv/bin/python || python -m venv .venv; test -x .venv/bin/python; .venv/bin/python -c "import os, sys; expected = tuple(map(int, os.environ[\"EXPECTED_PYTHON_SERIES\"].split(\".\"))); assert sys.version_info[:2] == expected, (sys.version, expected); print(sys.executable); print(sys.version)"'

if [[ "${PYTHON_SANDBOX_SKIP_VSCODE:-0}" == "1" ]]; then
  echo "Skipped VS Code setup because PYTHON_SANDBOX_SKIP_VSCODE=1."
  exit 0
fi

if command -v code >/dev/null 2>&1; then
  code_cli="$(command -v code)"
else
  code_cli=""
  for candidate in \
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
    "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
    "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"; do
    if [[ -x "$candidate" ]]; then
      code_cli="$candidate"
      break
    fi
  done
  [[ -n "$code_cli" ]] || {
    echo "Error: neither the code CLI nor a Visual Studio Code application bundle was found." >&2
    exit 1
  }

  if [[ ! -e /usr/local/bin/code && -w /usr/local/bin ]]; then
    ln -s "$code_cli" /usr/local/bin/code
    code_cli="/usr/local/bin/code"
    echo "Enabled the code CLI at /usr/local/bin/code."
  else
    echo "Using Visual Studio Code's bundled CLI at $code_cli."
  fi
fi

sbx setup ssh
"$code_cli" --install-extension ms-vscode-remote.remote-ssh
remote_authority="ssh-remote+${sandbox_name}.sbx"
for extension in ms-python.python ms-python.vscode-pylance ms-toolsai.jupyter charliermarsh.ruff REditorSupport.r openai.chatgpt anthropic.claude-code; do
  "$code_cli" --remote "$remote_authority" --install-extension "$extension"
done
"$code_cli" --remote "$remote_authority" "$project_root"
