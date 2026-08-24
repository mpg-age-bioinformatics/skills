#!/usr/bin/env bash
set -euo pipefail

target_dir="${1:-}"
python_version="${2:-}"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
skill_dir="$(dirname -- "$script_dir")"
skills_repository="https://github.com/mpg-age-bioinformatics/skills.git"

if [[ -z "$target_dir" || -z "$python_version" ]]; then
  echo "Usage: setup-project.sh <absolute-project-directory> <Python-version>" >&2
  exit 2
fi
if [[ "$target_dir" != /* ]]; then
  echo "Error: project directory must be an absolute path." >&2
  exit 2
fi
if [[ ! "$python_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Error: Python version must be major.minor or major.minor.patch (for example, 3.12 or 3.12.4)." >&2
  exit 2
fi
if [[ ! -d "$target_dir" ]]; then
  echo "Error: project directory does not exist: $target_dir" >&2
  exit 2
fi

cd "$target_dir"
IFS=. read -r python_major python_minor _ <<< "$python_version"
image_version="$python_major.$python_minor"
echo "Requested Python $python_version; using Dev Container tag $image_version-bookworm."

mkdir -p .devcontainer .vscode code data
if [[ -e skills ]]; then
  if [[ ! -d skills/.git ]]; then
    echo "Error: skills/ already exists and is not a Git clone." >&2
    exit 1
  fi
  existing_skills_repository="$(git -C skills remote get-url origin 2>/dev/null || true)"
  if [[ "$existing_skills_repository" != "$skills_repository" ]]; then
    echo "Error: skills/ already exists with a different origin: ${existing_skills_repository:-<none>}" >&2
    exit 1
  fi
else
  git clone "$skills_repository" skills
fi

for agent_home in .codex-home .claude-home; do
  if [[ -e "$agent_home" && ! -d "$agent_home" ]]; then
    echo "Error: $agent_home exists but is not a directory." >&2
    exit 1
  fi
  if [[ ! -d "$agent_home" ]]; then
    mkdir "$agent_home"
    chmod 700 "$agent_home"
  fi
done

install_if_absent_or_identical() {
  local source_path="$1"
  local destination_path="$2"
  if [[ -e "$destination_path" ]]; then
    if ! cmp -s "$source_path" "$destination_path"; then
      echo "Error: refusing to overwrite existing $destination_path" >&2
      exit 1
    fi
  else
    cp "$source_path" "$destination_path"
  fi
}

generated_devcontainer="$(mktemp)"
trap 'rm -f "$generated_devcontainer"' EXIT
sed "s/__PYTHON_VERSION__/${image_version}/g" "$skill_dir/assets/devcontainer.json.template" > "$generated_devcontainer"
install_if_absent_or_identical "$generated_devcontainer" .devcontainer/devcontainer.json
install_if_absent_or_identical "$skill_dir/assets/settings.json" .vscode/settings.json
install_if_absent_or_identical "$skill_dir/assets/extensions.json" .vscode/extensions.json

if [[ ! -e .gitignore ]]; then
  cp "$skill_dir/assets/gitignore" .gitignore
else
  for rule in '/.codex-home/' '/.claude-home/' '/skills/' '/.venv/' '/.pytest_cache/' '/.ruff_cache/' '/.mypy_cache/' '/.ipynb_checkpoints/' '__pycache__/' '*.py[cod]' '/.coverage' '/htmlcov/'; do
    grep -Fqx "$rule" .gitignore || printf '%s\n' "$rule" >> .gitignore
  done
fi
[[ -e AGENTS.md ]] || cp "$skill_dir/assets/AGENTS.md" AGENTS.md
[[ -e .instructions.md ]] || cp "$skill_dir/assets/.instructions.md" .instructions.md

git init
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  git add -A -- .devcontainer .vscode .gitignore AGENTS.md .instructions.md
  if git diff --cached --quiet; then
    echo "Python project setup is already committed."
  else
    git commit -m "Add Python development container"
  fi
else
  git add -A
  if git diff --cached --quiet -- .devcontainer; then
    echo "Error: .devcontainer was not staged; check repository ignore rules." >&2
    exit 1
  fi
  git commit -m "Initial Python project setup"
fi

git status --short
git show --stat --oneline HEAD
