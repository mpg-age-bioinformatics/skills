#!/usr/bin/env bash
set -euo pipefail

target_dir="${1:-}"
r_version="${2:-}"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
skill_dir="$(dirname -- "$script_dir")"
skills_repository="https://github.com/mpg-age-bioinformatics/skills.git"

if [[ -z "$target_dir" || -z "$r_version" ]]; then
  echo "Usage: setup-project.sh <absolute-project-directory> <R-version>" >&2
  exit 2
fi
if [[ "$target_dir" != /* ]]; then
  echo "Error: project directory must be an absolute path." >&2
  exit 2
fi
if [[ ! "$r_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Error: R version must be major.minor or major.minor.patch (for example, 4.4 or 4.4.2)." >&2
  exit 2
fi
if [[ ! -d "$target_dir" ]]; then
  echo "Error: project directory does not exist: $target_dir" >&2
  exit 2
fi

cd "$target_dir"
IFS=. read -r r_major r_minor _ <<< "$r_version"
image_version="$r_major.$r_minor"
echo "Requested R $r_version; using Rocker tag $image_version (latest patch release in that series)."

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

if [[ -e .codex-home && ! -d .codex-home ]]; then
  echo "Error: .codex-home exists but is not a directory." >&2
  exit 1
fi
if [[ ! -d .codex-home ]]; then
  mkdir .codex-home
  chmod 700 .codex-home
fi
if [[ -e .claude-home && ! -d .claude-home ]]; then
  echo "Error: .claude-home exists but is not a directory." >&2
  exit 1
fi
if [[ ! -d .claude-home ]]; then
  mkdir .claude-home
  chmod 700 .claude-home
fi
if [[ -e .r-library && ! -d .r-library ]]; then
  echo "Error: .r-library exists but is not a directory." >&2
  exit 1
fi
mkdir -p .r-library

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
sed "s/__R_VERSION__/${image_version}/g" "$skill_dir/assets/devcontainer.json.template" > "$generated_devcontainer"
install_if_absent_or_identical "$generated_devcontainer" .devcontainer/devcontainer.json
install_if_absent_or_identical "$skill_dir/assets/settings.json" .vscode/settings.json
install_if_absent_or_identical "$skill_dir/assets/extensions.json" .vscode/extensions.json

if [[ ! -e .gitignore ]]; then
  cp "$skill_dir/assets/gitignore" .gitignore
else
  for rule in '/.codex-home/' '/.claude-home/' '/skills/' '/.r-library/' '/.Rhistory' '/.RData' '/.Ruserdata' '/.Rproj.user/' '/renv/library/' '/renv/staging/'; do
    grep -Fqx "$rule" .gitignore || printf '%s\n' "$rule" >> .gitignore
  done
fi
[[ -e AGENTS.md ]] || cp "$skill_dir/assets/AGENTS.md" AGENTS.md
[[ -e .instructions.md ]] || cp "$skill_dir/assets/.instructions.md" .instructions.md

git init
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  git add -A -- .devcontainer .vscode .gitignore AGENTS.md .instructions.md
  if git diff --cached --quiet; then
    echo "R project setup is already committed."
  else
    git commit -m "Add R development container"
  fi
else
  git add -A
  if git diff --cached --quiet -- .devcontainer; then
    echo "Error: .devcontainer was not staged; check repository ignore rules." >&2
    exit 1
  fi
  git commit -m "Initial R project setup"
fi

git status --short
git show --stat --oneline HEAD
