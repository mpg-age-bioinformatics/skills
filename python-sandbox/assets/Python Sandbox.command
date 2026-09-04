#!/usr/bin/env bash
set -uo pipefail

python_version="${1:-}"
agent="${2:-}"
project_dir="${3:-}"
skills_repository="${PYTHON_SANDBOX_SKILLS_REPOSITORY:-https://github.com/mpg-age-bioinformatics/skills.git}"
skills_ref="${PYTHON_SANDBOX_SKILLS_REF:-}"
temporary_root="${TMPDIR:-/tmp}"
download_root=""

finish() {
  status=$?
  trap - EXIT
  if [[ -n "$download_root" && -d "$download_root" ]]; then
    rm -rf -- "$download_root"
  fi
  if [[ -t 0 ]]; then
    echo
    if [[ $status -eq 0 ]]; then
      echo "Python Sandbox setup finished."
    else
      echo "Python Sandbox setup stopped with an error (status $status)."
    fi
    read -r -p "Press Return to close this window..." _
  fi
  exit "$status"
}
trap finish EXIT

command -v git >/dev/null 2>&1 || {
  echo "Error: Git is required to download the Python Sandbox setup files." >&2
  exit 1
}
download_root="$(mktemp -d "${temporary_root%/}/python-sandbox-command.XXXXXX")"
downloaded_skills="$download_root/skills"
echo "Downloading Python Sandbox setup files..."
git clone --quiet --depth 1 "$skills_repository" "$downloaded_skills"
if [[ -n "$skills_ref" ]]; then
  git -C "$downloaded_skills" fetch --quiet --depth 1 origin "$skills_ref"
  git -C "$downloaded_skills" checkout --quiet --detach FETCH_HEAD
fi
launcher="$downloaded_skills/python-sandbox/assets/python-sandox.sh"

[[ -x "$launcher" ]] || {
  echo "Error: downloaded Python Sandbox launcher is unavailable: $launcher" >&2
  exit 1
}

if [[ -z "$python_version" ]]; then
  read -r -p "Python version (major.minor or major.minor.patch): " python_version
fi
if [[ -z "$agent" ]]; then
  read -r -p "Agent (codex or claude): " agent
fi
if [[ -z "$project_dir" ]]; then
  default_project="$HOME/Desktop/python-sandbox-project"
  read -r -p "Project directory [$default_project]: " project_dir
  project_dir="${project_dir:-$default_project}"
  case "$project_dir" in
    "~") project_dir="$HOME" ;;
    "~/"*) project_dir="$HOME/${project_dir#\~/}" ;;
  esac
  if [[ "$project_dir" != /* ]]; then
    project_dir="$(pwd -P)/$project_dir"
  fi
  if [[ ! -e "$project_dir" ]]; then
    echo "Creating project directory: $project_dir"
    mkdir -p "$project_dir"
  fi
fi

PYTHON_SANDBOX_USE_LOCAL_SKILL=1 "$launcher" "$python_version" "$agent" "$project_dir"
