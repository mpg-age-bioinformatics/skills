#!/usr/bin/env bash
set -euo pipefail

repository_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/sandbox-runtime-tests.XXXXXX")"
test_root="$(CDPATH= cd -- "$test_root" && pwd -P)"
trap 'rm -rf -- "$test_root"' EXIT
mock_bin="$test_root/bin"
mkdir -p "$mock_bin"

cat > "$mock_bin/mock-tool" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
tool="$(basename -- "$0")"
case "$tool:$1" in
  docker:info) echo linux; exit 0 ;;
  sbx:version) echo 'sbx version: v0.39.0 test'; exit 0 ;;
  sbx:diagnose) exit 0 ;;
  sbx:ls) exit 0 ;;
  sbx:exec)
    if [[ " $* " == *" pwd -P "* ]]; then
      printf '%s\n' "$SANDBOX_TEST_CONTAINER_PROJECT"
      exit 0
    fi
    ;;
  code:--remote)
    for argument in "$@"; do
      if [[ "$argument" == "--list-extensions" ]]; then
        printf '%s\n' \
          ms-python.python ms-python.vscode-pylance ms-toolsai.jupyter \
          charliermarsh.ruff REditorSupport.r RDebugger.r-debugger \
          quarto.quarto openai.chatgpt anthropic.claude-code
        exit 0
      fi
    done
    ;;
  cygpath:-w) printf 'C:\\mock%s\n' "$2"; exit 0 ;;
  cygpath:-m) printf 'C:/mock%s\n' "$2"; exit 0 ;;
esac
{
  printf '%s|%s|' "$tool" "${MSYS2_ARG_CONV_EXCL:-}"
  printf ' %q' "$@"
  printf '\n'
} >> "$SANDBOX_TEST_LOG"
MOCK
chmod +x "$mock_bin/mock-tool"
for tool in docker sbx code cygpath; do ln -s mock-tool "$mock_bin/$tool"; done

run_case() {
  local sandbox="$1" mode="$2" runtime skip_variable
  local project="$test_root/$sandbox-$mode"
  mkdir -p "$project/code"
  case "$sandbox" in
    python)
      runtime="$repository_root/python-sandbox/assets/run-python-sandbox.sh"
      skip_variable=PYTHON_SANDBOX_SKIP_VSCODE
      printf '%s\n' 'ARG PYTHON_IMAGE=python:3.13-bookworm' > "$project/code/Dockerfile"
      ;;
    r)
      runtime="$repository_root/r-sandbox/assets/run-r-sandbox.sh"
      skip_variable=R_SANDBOX_SKIP_VSCODE
      mkdir -p "$project/.r-library"
      printf '%s\n' 'ARG R_IMAGE=ghcr.io/rocker-org/devcontainer/r-ver:4.5' > "$project/code/Dockerfile"
      ;;
    bioinformatics)
      runtime="$repository_root/bioinformatics-sandbox/assets/run-bioinformatics-sandbox.sh"
      skip_variable=BIOINFORMATICS_SANDBOX_SKIP_VSCODE
      ;;
  esac
  cp "$runtime" "$project/code/$(basename -- "$runtime")"
  chmod +x "$project/code/$(basename -- "$runtime")"
  local log="$test_root/$sandbox-$mode.log"
  local container_project='/sandbox/project\_5'
  local container_project_log
  printf -v container_project_log '%q' "$container_project"
  : > "$log"
  if [[ "$mode" == windows ]]; then
    env PATH="$mock_bin:$PATH" OSTYPE=msys MSYSTEM=MINGW64 SANDBOX_TEST_LOG="$log" SANDBOX_TEST_CONTAINER_PROJECT="$container_project" "$skip_variable=0" \
      bash "$project/code/$(basename -- "$runtime")" codex >/dev/null
    grep -F 'sbx|*| run' "$log" | grep -F 'C:\\mock/' >/dev/null
    if [[ "$sandbox" != bioinformatics ]]; then
      grep -F 'sbx|*| exec' "$log" | grep -F -- "--workdir $container_project_log" >/dev/null
    fi
    grep -F 'code|*| --remote' "$log" | grep -F "$container_project_log" >/dev/null
  else
    env PATH="$mock_bin:$PATH" OSTYPE=darwin SANDBOX_TEST_LOG="$log" SANDBOX_TEST_CONTAINER_PROJECT="$container_project" "$skip_variable=0" \
      bash "$project/code/$(basename -- "$runtime")" codex >/dev/null
    grep -F 'sbx|| run' "$log" | grep -F "$project" >/dev/null
    grep -F 'code|| --remote' "$log" | grep -F "$container_project_log" >/dev/null
  fi
}

for sandbox in python r bioinformatics; do
  run_case "$sandbox" macos
  run_case "$sandbox" windows
done

grep -F 'python -m venv --clear --copies .venv' "$repository_root/python-sandbox/assets/run-python-sandbox.sh" >/dev/null

echo "Runtime launcher path tests passed."
