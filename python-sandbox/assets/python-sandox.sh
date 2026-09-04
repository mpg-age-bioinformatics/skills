#!/usr/bin/env bash
set -euo pipefail

python_version="${1:-}"
agent="${2:-}"
project_dir="${3:-}"
skills_repository="${PYTHON_SANDBOX_SKILLS_REPOSITORY:-https://github.com/mpg-age-bioinformatics/skills.git}"
skills_ref="${PYTHON_SANDBOX_SKILLS_REF:-}"
use_local_skill="${PYTHON_SANDBOX_USE_LOCAL_SKILL:-0}"
download_root=""

cleanup() {
  if [[ -n "$download_root" && -d "$download_root" ]]; then
    rm -rf -- "$download_root"
  fi
}
trap cleanup EXIT

if [[ -z "$python_version" || -z "$agent" ]]; then
  if [[ ! -t 0 ]]; then
    echo "Usage: $0 <Python-version> <codex|claude> [project-directory]" >&2
    exit 2
  fi
  echo "Python version and sandbox agent are required."
  if [[ -z "$python_version" ]]; then
    read -r -p "Python version (major.minor or major.minor.patch): " python_version
  fi
  if [[ -z "$agent" ]]; then
    read -r -p "Agent (codex or claude): " agent
  fi
fi

[[ "$python_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || {
  echo "Error: Python version must be major.minor or major.minor.patch." >&2
  exit 2
}
case "$agent" in
  codex|claude) ;;
  *) echo "Error: agent must be codex or claude." >&2; exit 2 ;;
esac

if [[ -z "$project_dir" ]]; then
  if [[ $# -ge 2 ]]; then
    project_dir="$(pwd -P)"
  elif [[ -t 0 ]]; then
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
  else
    echo "Usage: $0 <Python-version> <codex|claude> [project-directory]" >&2
    exit 2
  fi
fi

case "$project_dir" in
  //*) echo "Error: network and WSL project directories are not supported: $project_dir" >&2; exit 2 ;;
esac
if [[ "$project_dir" == /* && ! -e "$project_dir" ]]; then
  echo "Creating project directory: $project_dir"
  mkdir -p "$project_dir"
fi
[[ "$project_dir" == /* && -d "$project_dir" ]] || {
  echo "Error: project directory must be an absolute existing path: $project_dir" >&2
  exit 2
}

asset_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
skill_dir="$(dirname -- "$asset_dir")"
setup_script="$skill_dir/scripts/setup-project.sh"

if [[ "$use_local_skill" != "1" || ! -x "$setup_script" ]]; then
  command -v git >/dev/null 2>&1 || {
    echo "Error: Git is required to download the Python Sandbox setup files." >&2
    exit 1
  }
  temporary_root="${TMPDIR:-/tmp}"
  download_root="$(mktemp -d "${temporary_root%/}/python-sandbox.XXXXXX")"
  downloaded_skills="$download_root/skills"
  echo "Downloading Python Sandbox setup files..."
  git clone --quiet --depth 1 "$skills_repository" "$downloaded_skills"
  if [[ -n "$skills_ref" ]]; then
    git -C "$downloaded_skills" fetch --quiet --depth 1 origin "$skills_ref"
    git -C "$downloaded_skills" checkout --quiet --detach FETCH_HEAD
  fi
  skill_dir="$downloaded_skills/python-sandbox"
  setup_script="$skill_dir/scripts/setup-project.sh"
fi

[[ -x "$setup_script" ]] || {
  echo "Error: downloaded Python Sandbox setup is incomplete: $setup_script" >&2
  exit 1
}

"$setup_script" "$project_dir" "$python_version" "$agent"
"$project_dir/code/run-python-sandbox.sh" "$agent"
