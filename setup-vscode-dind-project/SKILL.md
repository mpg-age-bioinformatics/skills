---
name: setup-vscode-dind-project
description: Set up a VS Code Docker-in-Docker Dev Container with project-local persistent Codex and Claude Code state, add a root execution policy, initialize the code/data layout, and create the setup commit.
---

# Set up the DinD project and repository skill

Work from the current repository root. Perform each operation independently and idempotently.

1. Run `scripts/setup-project.sh` with the absolute path of the current repository root as its only argument. Do not recreate its file-copying or Git operations manually.
2. The script preserves existing setup files, creates the ignored `.codex-home/` and `.claude-home/` directories with owner-only permissions when missing, and does not install repository-local skills. The Dev Container bind-mounts them at `/home/vscode/.codex` and `/home/vscode/.claude`, preserving this project's Codex and Claude Code sessions, settings, and authentication across container rebuilds. In a repository without `HEAD`, the script stages all non-ignored files and creates `Initial project setup`, after explicitly verifying that `.devcontainer` is staged. In a repository with `HEAD`, it stages only `.devcontainer`, `.gitignore`, `.instructions.md`, and the root `AGENTS.md`, then creates `Add DinD project setup` when those paths have uncommitted changes.
3. If a commit fails because Git author identity is missing, do not configure or invent an identity. Leave the files staged and tell the user to configure `user.name` and `user.email`, then rerun the skill.
4. Explain that the Dev Container uses a dedicated nested Docker daemon and does not mount the host Docker socket. Also explain that the official Docker-in-Docker feature requires privileged mode, so it is not an absolute security boundary; on macOS, Docker Desktop's Linux VM remains an additional outer boundary.
5. Reopen the current folder using `Dev Containers: Reopen in Container` when the environment exposes a supported way to invoke VS Code commands. Otherwise, use this exact wording: `The VS Code CLI isn't available here. In VS Code's Command Palette, run:` followed on the next line by `>Dev Containers: Reopen in Container`. Never omit the leading `>` and never claim the folder was reopened unless it actually was.
6. Tell the user that `AGENTS.md` defines the container-execution policy and `.instructions.md` directs agents to apply it throughout the repository automatically. Both `.codex-home/` and `.claude-home/` contain sensitive plaintext state and credentials and must remain uncommitted and private.

The generated execution policy is intended for scientific and bioinformatic work. Scientific analysis and visualization requests, including CSV-backed heatmap demos, must use an appropriate scientific library stack (for example, Pandas/NumPy with Matplotlib or Seaborn) and must be built and run in Docker through the nested Docker daemon. Do not choose Python-standard-library-only code as a workaround for dependency installation. The policy also requires every installation instruction to be tracked under `code/` and every required dependency, runtime, service, tool, and base image to use one exact pinned version, with supported lockfiles committed and updated alongside installation code.

Do not add the host Docker socket, other host filesystem or credential mounts, extra capabilities, or unrelated configuration. Do not overwrite existing files or skill directories.
