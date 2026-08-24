---
name: create-nexus-notebook
description: Create a user-named Jupyter notebook whose first cell configures the Nexus MAGE-flaski per-user Python package location, pair it with a synchronized Jupytext Python file, and add project instructions for organized notebook imports. Use when the user asks to create or initialize an IPython/Jupyter notebook for that environment.
---

# Create a Nexus notebook

Obtain the notebook name from the user. If the request already includes a name, do not ask again.

Use the intended project's Python environment and ensure Jupytext is installed there. When dependency management is defined by the project, add and install Jupytext through that workflow instead of performing an undocumented installation.

Run `scripts/create_notebook.py NAME` from the user's intended project directory. The generator appends `.ipynb` when the name has no extension, creates parent directories when needed, and uses Jupytext to pair the notebook with a same-stem `py:percent` file. It also creates `AGENTS.md` in the current working directory. That project guidance requires package imports to be grouped in one code cell near the top of each notebook, interprets informal requests for “a function” as direct executable library usage unless a custom function is explicitly requested, and requires the `.ipynb`/`.py` pair to remain synchronized through Jupytext. The generator accepts an identical existing `AGENTS.md` but refuses to overwrite different project instructions. Do not reproduce or modify the initialization cell or `AGENTS.md` manually.

If the intended output directory is not stated, create the pair in the current working directory. Preserve any relative or absolute parent directory included in `NAME`. The generator refuses to overwrite either member of an existing pair. Do not use `--force` unless the user explicitly asks to replace both files.

After generation, parse the notebook as JSON and verify that it has notebook format 4, the first cell is a code cell, and its Jupytext formats are `ipynb,py:percent`. Run Jupytext synchronization once more and verify the paired `.py` file and `AGENTS.md` exist. Report all three paths.
