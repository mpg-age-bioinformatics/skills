# R project environment

- Put implementation files in `code/` and data or generated analysis artifacts in `data/`.
- Use R as the default language for analysis unless the task requires another tool.
- Run R work in the Dev Container. Do not install project packages on the host to bypass the container.
- Use `renv` for project dependency isolation when additional R packages are needed, and keep its lockfile under version control.
- Prefer established CRAN or Bioconductor packages for analysis and visualization.
- Keep secrets out of source code, output, and Git. The ignored `.codex-home/` directory contains sensitive Codex state.
