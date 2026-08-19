#!/usr/bin/env bash
set -euo pipefail

target_dir="${1:-$PWD}"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
skill_dir="$(dirname -- "$script_dir")"

cd "$target_dir"

mkdir -p .devcontainer code data

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

if [[ ! -e .devcontainer/devcontainer.json ]]; then
	cp "$skill_dir/assets/devcontainer.json" .devcontainer/devcontainer.json
fi

if [[ ! -e .gitignore ]]; then
	cp "$skill_dir/assets/gitignore" .gitignore
fi

if [[ ! -e AGENTS.md ]]; then
	cp "$skill_dir/assets/AGENTS.md" AGENTS.md
fi

git init

if git rev-parse --verify HEAD >/dev/null 2>&1; then
	git add -A -- .devcontainer .gitignore AGENTS.md
	if git diff --cached --quiet; then
		echo "Repository setup is already committed."
	else
		git commit -m "Add DinD project setup"
	fi
else
	git add -A

	if git diff --cached --quiet -- .devcontainer; then
		echo "Error: .devcontainer was not staged; check the repository ignore rules." >&2
		exit 1
	fi
	git commit -m "Initial project setup"
fi

git status --short
git show --stat --oneline HEAD
