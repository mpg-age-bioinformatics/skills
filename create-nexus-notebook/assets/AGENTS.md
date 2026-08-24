# Jupyter notebook development

- Group all package imports for a notebook in a single code cell near the top of the notebook. Do not scatter imports across later cells.
- Place that import cell immediately after any required environment-initialization cell, unless the initialization code itself must import packages before the environment is configured.
- Keep imports explicit and organized with standard-library, third-party, and local project imports in separate groups within the same cell.
- In notebook requests, interpret informal wording such as “write me a function for a heatmap” as a request for executable analysis code that calls the appropriate established library function, not as a request to define a new Python function. For example, write the relevant data preparation, plotting setup, `sns.heatmap(...)` call, labels, display, and saving code directly in notebook cells. Define a new function with `def` only when the user explicitly asks for a custom, named, or reusable function, or when reuse is clearly required by the task.
- Treat every same-stem `.ipynb` and `.py` file as one Jupytext pair. Preserve the notebook's `ipynb,py:percent` pairing metadata and synchronize changes with Jupytext; do not edit both representations independently.
