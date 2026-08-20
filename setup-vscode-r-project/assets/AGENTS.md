# R project environment

- Put implementation files in `code/` and data or generated analysis artifacts in `data/`.
- Use R as the default language for analysis unless the task requires another tool.
- Treat the Dev Container setup as completed project scaffolding. Develop and run scripts interactively with the user, and do not rerun the setup skill after ordinary code, analysis, or package changes.
- Run R work in the Dev Container. Do not install project packages on the host to bypass the container.
- Never leave a package installation as an ad-hoc terminal action. Record every package installation instruction in tracked project code or a tracked dependency manifest so the environment can be recreated from the repository.
- Pin every installed package to one exact version. Do not use unversioned package names, version ranges, `latest`, or other floating references in installation code or manifests.
- Use `renv` for R dependency isolation. As a package becomes necessary during interactive development, record its explicit install with an exact version (for example, `renv::install("dplyr@1.1.4")`), install it in the current Dev Container, run `renv::snapshot()`, and keep `renv.lock` under version control. Update the installation code and lockfile as part of that development change; do not rerun the setup skill.
- Whenever a package is installed or its installation instructions are added, update every affected executable R script or shared bootstrap so it activates the same library before loading the package. For an `renv` installation, activate the project with its project-relative `renv/activate.R` (or an equivalent `renv::load()` call) before any `library()` or `requireNamespace()` call. Do not hard-code an internal `renv` cache path.
- If a package is deliberately installed outside `renv`, make its configured project library available through `R_LIBS_USER` or prepend the project-relative library to `.libPaths()` before loading it. Do not assume an interactive terminal's library state will carry into a script.
- After changing dependencies, run each affected entry-point script in a fresh R process from its documented invocation context. Verify with `find.package()` or `path.package()` that every newly added package resolves from the intended `renv` or project library, and fix the script rather than asking the user to adjust library paths manually.
- Prefer established CRAN or Bioconductor packages for analysis and visualization.
- Keep secrets out of source code, output, and Git. The ignored `.codex-home/` directory contains sensitive Codex state.

## Interactive R development style

This project is developed interactively in RStudio or an interactive R session.

When creating analysis scripts:

- Write scripts as section-by-section analytical workflows that can be run incrementally.
- Put user-editable values near the top in a clearly labeled configuration section. This includes file paths, column names, experimental groups, model formulas, contrasts, thresholds, and output paths.
- Use RStudio section headers such as `# ---- Load data ----`.
- Keep intermediate objects available for inspection in the R environment.
- Prefer clear, explicit analysis steps over application-style abstractions.
- Include validation checks and informative errors after loading data.
- Save generated data, tables, plots, and analysis artifacts under `data/`.
- Do not use `readline()`, menus, interactive questions, command-line arguments, or prompt-driven interfaces unless explicitly requested.
- In this project, “interactive script” means an editable R/RStudio workflow, not a script that asks questions while running.
- Scripts should still be reproducible when run from top to bottom from the project root.
