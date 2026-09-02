#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
skill_dir="$(dirname -- "$script_dir")"
runner_dir="$skill_dir/assets/windows-project-runner"
command -v go >/dev/null 2>&1 || { echo "Error: Go is required." >&2; exit 1; }
go_winres="${GO_WINRES:-$(go env GOPATH)/bin/go-winres}"
[[ -x "$go_winres" ]] || { echo "Error: install go-winres with: go install github.com/tc-hib/go-winres@v0.3.3" >&2; exit 1; }

cd "$runner_dir"
"$go_winres" simply --arch amd64 --out rsrc --product-version 1.0.0 \
  --file-version 1.0.0 --manifest cli \
  --file-description "Bioinformatics Sandbox project runner" \
  --product-name "Bioinformatics Sandbox" --original-filename "Run Bioinformatics Sandbox.exe" \
  --icon icon.png
for agent in codex claude; do
  GO111MODULE=off GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -trimpath \
    -ldflags="-s -w -X main.agent=$agent" -o "runner-$agent.exe" .
done

