#!/usr/bin/env bash
set -euo pipefail

target_dir="${1:-}"
agent="${2:-}"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
skill_dir="$(dirname -- "$script_dir")"
skills_repository="https://github.com/mpg-age-bioinformatics/skills.git"

if [[ -z "$target_dir" || "$target_dir" != /* || ! -d "$target_dir" ]]; then
  echo "Usage: setup-project.sh <absolute-existing-project-directory> <codex|claude>" >&2
  exit 2
fi
case "$agent" in
  codex|claude) ;;
  *) echo "Error: agent must be codex or claude." >&2; exit 2 ;;
esac

cd "$target_dir"
mkdir -p code data .vscode

if [[ -e skills ]]; then
  if [[ ! -d skills/.git ]]; then
    echo "Error: skills/ already exists and is not a Git clone." >&2
    exit 1
  fi
  existing_origin="$(git -C skills remote get-url origin 2>/dev/null || true)"
  if [[ "$existing_origin" != "$skills_repository" ]]; then
    echo "Error: skills/ has a different origin: ${existing_origin:-<none>}" >&2
    exit 1
  fi
else
  git clone "$skills_repository" skills
fi

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

if [[ ! -e AGENTS.md ]]; then
  cp "$skill_dir/assets/AGENTS.md" AGENTS.md
elif ! grep -Fq '<!-- bioinformatics-sandbox:scientific-libraries:start -->' AGENTS.md; then
  printf '\n' >> AGENTS.md
  sed -n '/<!-- bioinformatics-sandbox:scientific-libraries:start -->/,/<!-- bioinformatics-sandbox:scientific-libraries:end -->/p' \
    "$skill_dir/assets/AGENTS.md" >> AGENTS.md
fi
install_if_absent_or_identical "$skill_dir/assets/.instructions.md" .instructions.md
install_if_absent_or_identical "$skill_dir/assets/extensions.json" .vscode/extensions.json
install_if_absent_or_identical "$skill_dir/assets/settings.json" .vscode/settings.json
install_if_absent_or_identical "$skill_dir/assets/run-bioinformatics-sandbox.sh" code/run-bioinformatics-sandbox.sh
install_if_absent_or_identical "$skill_dir/assets/windows-project-runner/runner-$agent.exe" "code/Run Bioinformatics Sandbox.exe"
chmod +x code/run-bioinformatics-sandbox.sh

if [[ ! -e .gitignore ]]; then
  cp "$skill_dir/assets/gitignore" .gitignore
else
  while IFS= read -r rule; do
    [[ -z "$rule" ]] && continue
    grep -Fqx "$rule" .gitignore || printf '%s\n' "$rule" >> .gitignore
  done < "$skill_dir/assets/gitignore"
fi

git init
setup_paths=(.vscode .gitignore AGENTS.md .instructions.md code/run-bioinformatics-sandbox.sh "code/Run Bioinformatics Sandbox.exe")
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  git add -f -A -- "${setup_paths[@]}"
  if git diff --cached --quiet; then
    echo "Bioinformatics Sandbox setup is already committed."
  else
    git commit -m "Add bioinformatics sandbox setup"
  fi
else
  git add -f -A -- "${setup_paths[@]}"
  git commit -m "Initial bioinformatics sandbox setup"
fi

git status --short
git show --stat --oneline HEAD
