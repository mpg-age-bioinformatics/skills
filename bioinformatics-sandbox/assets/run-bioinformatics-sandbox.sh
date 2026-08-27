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

if sbx ls --quiet | grep -Fqx "$sandbox_name"; then
  sbx run --detached --name "$sandbox_name"
else
  sbx run --detached --name "$sandbox_name" "$agent" "$project_root"
fi

if [[ "${BIOINFORMATICS_SANDBOX_SKIP_VSCODE:-0}" == "1" ]]; then
  echo "Skipped VS Code setup because BIOINFORMATICS_SANDBOX_SKIP_VSCODE=1."
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
for extension in ms-python.python ms-python.vscode-pylance ms-toolsai.jupyter REditorSupport.r openai.chatgpt anthropic.claude-code; do
  "$code_cli" --remote "$remote_authority" --install-extension "$extension"
done
"$code_cli" --remote "$remote_authority" "$project_root"
