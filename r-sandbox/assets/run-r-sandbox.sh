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

sandbox_name="r-${project_name}-${agent}"
template_tag="r-sandbox-${project_name}-${agent}:local"
temporary_root="${TMPDIR:-/tmp}"
template_tar="$(mktemp "${temporary_root%/}/r-sandbox-template.XXXXXX")"
trap 'rm -f "$template_tar"' EXIT

docker build --build-arg "AGENT_TEMPLATE=$agent_template" -t "$template_tag" -f "$project_root/code/Dockerfile" "$project_root/code"
docker image save "$template_tag" -o "$template_tar"
sbx template load "$template_tar"

echo "Sandbox: $sandbox_name"
echo "VS Code Remote-SSH host: ${sandbox_name}.sbx"
echo "Workspace: $project_root"
r_library="$project_root/.r-library"

if sbx ls --quiet | grep -Fqx "$sandbox_name"; then
  sbx run --detached --env "R_LIBS_USER=$r_library" --name "$sandbox_name"
else
  sbx run --detached --env "R_LIBS_USER=$r_library" --name "$sandbox_name" --template "$template_tag" "$agent" "$project_root"
fi

r_series="$(sed -n 's/^ARG R_IMAGE=ghcr.io\/rocker-org\/devcontainer\/r-ver:\([0-9][0-9]*\.[0-9][0-9]*\)$/\1/p' "$project_root/code/Dockerfile")"
[[ -n "$r_series" ]] || { echo "Error: could not determine the R series from code/Dockerfile." >&2; exit 1; }
sbx exec --env "EXPECTED_R_SERIES=$r_series" --env "R_LIBS_USER=$r_library" --workdir "$project_root" "$sandbox_name" Rscript -e \
  'actual <- paste(R.version$major, strsplit(R.version$minor, ".", fixed=TRUE)[[1]][1], sep="."); stopifnot(identical(actual, Sys.getenv("EXPECTED_R_SERIES")), normalizePath(Sys.getenv("R_LIBS_USER"), mustWork=TRUE) %in% normalizePath(.libPaths(), mustWork=FALSE), requireNamespace("BiocManager", quietly=TRUE), requireNamespace("languageserver", quietly=TRUE), as.character(utils::packageVersion("languageserver")) == "0.3.18"); cat(R.version.string, "\n"); cat("BiocManager", as.character(utils::packageVersion("BiocManager")), "\n"); cat("languageserver", as.character(utils::packageVersion("languageserver")), "\n"); cat(.libPaths(), sep="\n")'

if [[ "${R_SANDBOX_SKIP_VSCODE:-0}" == "1" ]]; then
  echo "Skipped VS Code setup because R_SANDBOX_SKIP_VSCODE=1."
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
    if [[ -x "$candidate" ]]; then code_cli="$candidate"; break; fi
  done
  [[ -n "$code_cli" ]] || { echo "Error: neither the code CLI nor Visual Studio Code was found." >&2; exit 1; }
  if [[ ! -e /usr/local/bin/code && -w /usr/local/bin ]]; then
    ln -s "$code_cli" /usr/local/bin/code
    code_cli="/usr/local/bin/code"
  fi
fi

sbx setup ssh
"$code_cli" --install-extension ms-vscode-remote.remote-ssh --force
remote_authority="ssh-remote+${sandbox_name}.sbx"
required_extensions=(REditorSupport.r RDebugger.r-debugger quarto.quarto openai.chatgpt anthropic.claude-code)
for extension in "${required_extensions[@]}"; do
  "$code_cli" --remote "$remote_authority" --install-extension "$extension" --force
done

remote_extensions="$("$code_cli" --remote "$remote_authority" --list-extensions | tr '[:upper:]' '[:lower:]')"
for extension in "${required_extensions[@]}"; do
  extension_lower="$(printf '%s' "$extension" | tr '[:upper:]' '[:lower:]')"
  if ! printf '%s\n' "$remote_extensions" | grep -Fxiq "$extension_lower"; then
    echo "Error: VS Code extension was not installed in $remote_authority: $extension" >&2
    exit 1
  fi
done

"$code_cli" --remote "$remote_authority" "$project_root"
