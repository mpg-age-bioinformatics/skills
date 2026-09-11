---
name: set-vscode-r-version
description: Create or update a project-local VS Code `.vscode/settings.json` file to set `terminal.integrated.env.linux.R_VERSION`, ensure VS Code Server user-level R settings, and install needed R-related VS Code extensions for Posit Workbench R sessions. Use when a user wants a folder-specific R version for VS Code, Posit Workbench, the R extension, `R_VERSION`, `/r.rc`, R Debugger, or Quarto support.
---

# Set VS Code R Version

Use this skill to configure the current project folder to use a specific R version when VS Code creates an R terminal through the R extension in Posit Workbench.

The folder-local `.vscode/settings.json` should contain only the project-specific override:

```json
{
  "terminal.integrated.env.linux": {
    "R_VERSION": "4.5.2"
  }
}
```

Also add or keep common R extension settings in the VS Code Server user settings file, usually `/nexus/posix0/MAGE-flaski/service/posit/home/<username>/.vscode-server/User/settings.json`:

```json
{
  "r.rterm.linux": "/nexus/posix0/MAGE-flaski/service/posit/rcs/R-vscode",
  "r.sessionWatcher": true,
  "r.alwaysUseActiveTerminal": true,
  "r.plot.useHttpgd": false,
  "workbench.panel.defaultLocation": "bottom"
}
```

Ensure these VS Code extensions are installed when needed:

- R by REditorSupport: `REditorSupport.r`
- R Debugger: `RDebugger.r-debugger`
- Quarto: `quarto.quarto`

Tell the user to install missing extensions from the VS Code Extensions view inside Posit Workbench. Do not suggest installing extensions with the `code` CLI; it is not available in this environment.

## Workflow

1. Determine the requested R version. If the user does not provide one, ask for it.
2. Ensure the needed VS Code extensions above are installed, at minimum R by REditorSupport. Include R Debugger and Quarto when the user requests them or the project uses them.
3. Use `scripts/set_vscode_r_version.py PROJECT_DIR R_VERSION` to create or update `PROJECT_DIR/.vscode/settings.json` and ensure the VS Code Server user settings above.
4. Preserve unrelated existing VS Code workspace settings.
5. Preserve unrelated existing VS Code Server user settings.
6. If explaining the manual fallback, tell the user to open the gear/settings menu in VS Code inside Posit Workbench, open Settings, use the settings page action to open Settings JSON, and add or keep the common R settings above.
7. Tell the user to close the existing R terminal, open the Command Palette, and explicitly run `>R: Create R Terminal` so the R extension starts a fresh terminal with the folder-local `R_VERSION`.

## Notes

- Do not recommend `export R_VERSION=...` in one terminal followed by creating a new VS Code R terminal. The new terminal is spawned by VS Code and will not inherit that shell variable.
- A direct command such as `R_VERSION=4.5.2 /nexus/posix0/MAGE-flaski/service/posit/rcs/R-vscode` can start the requested R version, but plots may not display because it can bypass the VS Code R extension startup hook.
- To list available R versions, use `source /r.rc` or `source /r.rc help` in a shell terminal.
