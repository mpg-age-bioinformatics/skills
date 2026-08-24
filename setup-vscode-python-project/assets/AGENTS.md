# Python project environment

- Put implementation files, notebooks, tests, dependency manifests, and installation scripts under `code/`. Put input data and generated artifacts under `data/`.
- Use Python as the default implementation language unless the task requires another tool.
- Treat the Dev Container setup as completed scaffolding. Develop incrementally and do not rerun the setup skill after ordinary code or dependency changes.
- Run Python in the Dev Container using the project-root `.venv/`. Do not install project dependencies globally, with `sudo`, on the host, or into the Dev Container's system interpreter.
- Record every dependency and installation instruction in tracked files under `code/`; never leave installation as an undocumented terminal action.
- Pin every direct and transitive dependency to one exact version. Do not use version ranges, unversioned requirements, floating Git references, or floating tool versions.
- Keep a human-maintained direct-dependency input such as `code/requirements.in` and a fully resolved `code/requirements.lock`. Install runtime and test environments from the lock file. Update both files together whenever dependencies change.
- Each executable script must locate inputs and outputs relative to the project root or an explicit top-level configuration section. It must work in a fresh process from the project root and must not depend on interactive shell state.
- After dependency changes, run affected entry points and tests in a fresh `.venv/bin/python` process and verify imports resolve from `.venv/`.
- For scientific, data-analysis, visualization, or bioinformatics requests, use the established scientific Python ecosystem by default. Choose libraries that express the analysis idiomatically—for example, Pandas for tabular CSV data, NumPy/SciPy for numerical work, Matplotlib or Seaborn for plots, Biopython for sequence data, and scikit-learn for machine learning.
- Do not replace a conventional scientific-library workflow with a hand-written standard-library implementation merely to avoid adding dependencies. Add the appropriate packages to `code/requirements.in`, resolve exact versions into `code/requirements.lock`, install from that lock into `.venv/`, and verify the resulting program. Use a standard-library-only implementation only when the user requests it or when a real project constraint requires it.
- Produce conventional, editable scientific code and normal analysis artifacts. For example, a heatmap from CSV should ordinarily read the table with Pandas and plot it with Seaborn/Matplotlib, with labeled axes, a color bar, a suitable palette, and an image saved under `data/`; do not manually construct SVG/XML unless requested.
- Use pytest for automated tests unless the project already uses another test framework.
- Keep notebooks reproducible: move reusable logic into importable modules under `code/`, keep execution order clear, and save generated artifacts under `data/`.
- Keep secrets out of source code, notebooks, output, and Git. The ignored `.codex-home/` and `.claude-home/` directories contain sensitive agent state.
