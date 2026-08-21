#!/usr/bin/env bash
set -euo pipefail

commit_message="${1:-Snapshot project for data archive}"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: run this command inside a Git repository." >&2
  exit 1
}

code_dir="$repo_root/code"
data_dir="$repo_root/data"

if [[ ! -d "$code_dir" ]]; then
  echo "Error: $code_dir is not a directory." >&2
  exit 1
fi

if [[ ! -d "$data_dir" ]]; then
  echo "Error: $data_dir is not a directory." >&2
  exit 1
fi

git_dir="$(git -C "$repo_root" rev-parse --git-dir)"
if [[ "$git_dir" != /* ]]; then
  git_dir="$repo_root/$git_dir"
fi
if [[ -f "$git_dir/MERGE_HEAD" ]]; then
  echo "Error: finish or abort the current merge before matching code and data." >&2
  exit 1
fi

git -C "$repo_root" add -A -- .

git -C "$repo_root" commit --allow-empty --message "$commit_message"

snapshot_hash="$(git -C "$repo_root" rev-parse --short=8 HEAD)"
archive_dir="$repo_root/data_$snapshot_hash"

if [[ -e "$archive_dir" ]]; then
  echo "Error: archive already exists: $archive_dir" >&2
  echo "The code commit was created, but data was not renamed." >&2
  exit 1
fi

mv -- "$data_dir" "$archive_dir"
mkdir -- "$data_dir"

echo "Project commit: $snapshot_hash"
echo "Archived data: data_$snapshot_hash"
echo "Created empty data/"
