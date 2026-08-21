---
name: match-code-data
description: Snapshot an entire Git repository while respecting its ignore rules, rename its data directory with the resulting eight-character commit hash, and create a new empty data directory. Use when the user wants to bind a completed data set to the exact project revision that produced it.
---

# Match Code Data

Change into the target Git repository (or one of its subdirectories), then run `scripts/match-code-data.sh` by its absolute path.

The script performs this guarded workflow:

1. Verify that `code/` and `data/` exist at the repository root.
2. Stage and commit all changes in the repository, including root files and additions, modifications, and deletions in subdirectories. Standard Git ignore rules remain in effect, so untracked ignored files are not added. Already-tracked files remain tracked even if a later ignore rule matches them. An empty commit is allowed so every rotation receives a unique project snapshot hash.
3. Resolve the new commit's eight-character hash.
4. Rename `data/` to `data_<hash>/`.
5. Create a new empty `data/` directory.

Use the default commit message unless the user supplies one:

```bash
/path/to/match-code-data/scripts/match-code-data.sh
/path/to/match-code-data/scripts/match-code-data.sh "Describe the code snapshot"
```

Report the project commit hash and archived data-directory name after success. Do not claim that only `code/` was committed.

The script stops if either required directory is missing or the repository is mid-merge. If the hash-named archive already exists, it preserves `data/` and reports that the code commit was created without rotating the data. Do not overwrite or merge an existing archive automatically.
