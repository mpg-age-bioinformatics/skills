#!/usr/bin/env bash
set -euo pipefail

target_dir="${1:-$PWD}"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
skill_dir="$(dirname -- "$script_dir")"
skills_repository="https://github.com/mpg-age-bioinformatics/skills.git"

cd "$target_dir"

mkdir -p .devcontainer code data

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

if [[ ! -e .devcontainer/devcontainer.json ]]; then
	cp "$skill_dir/assets/devcontainer.json" .devcontainer/devcontainer.json
fi

if [[ ! -e .gitignore ]]; then
	cp "$skill_dir/assets/gitignore" .gitignore
fi
grep -Fqx '/skills/' .gitignore || printf '%s\n' '/skills/' >> .gitignore

if [[ ! -e AGENTS.md ]]; then
	cp "$skill_dir/assets/AGENTS.md" AGENTS.md
fi

if [[ ! -e .instructions.md ]]; then
	cp "$skill_dir/assets/.instructions.md" .instructions.md
fi

git init

if git rev-parse --verify HEAD >/dev/null 2>&1; then
	git add -A -- .devcontainer .gitignore AGENTS.md .instructions.md
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
