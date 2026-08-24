# Jupyter notebook development

- Group all package imports for a notebook in a single code cell near the top of the notebook. Do not scatter imports across later cells.
- Place that import cell immediately after any required environment-initialization cell, unless the initialization code itself must import packages before the environment is configured.
- Keep imports explicit and organized with standard-library, third-party, and local project imports in separate groups within the same cell.
