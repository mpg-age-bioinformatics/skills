---
name: create-nexus-notebook
description: Create a user-named Jupyter notebook whose first cell configures the Nexus MAGE-flaski per-user Python package location, plus project instructions for organized notebook imports. Use when the user asks to create or initialize an IPython/Jupyter notebook for that environment.
---

# Create a Nexus notebook

Obtain the notebook name from the user. If the request already includes a name, do not ask again.

Run `scripts/create_notebook.py NAME` from the user's intended project directory. The generator appends `.ipynb` when the name has no extension, creates parent directories when needed, and creates `AGENTS.md` in the current working directory. That project guidance requires package imports to be grouped in one code cell near the top of each notebook. The generator accepts an identical existing `AGENTS.md` but refuses to overwrite different project instructions. Do not reproduce or modify the initialization cell or `AGENTS.md` manually.

If the intended output directory is not stated, create the notebook in the current working directory. Preserve any relative or absolute parent directory included in `NAME`. Do not use `--force` unless the user explicitly asks to replace the existing notebook.

After generation, parse the notebook as JSON and verify that it has notebook format 4 and that the first cell is a code cell. Also verify that `AGENTS.md` exists in the invocation directory. Report both created paths.
