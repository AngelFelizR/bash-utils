# bash-utils

A personal collection of reusable Bash utilities for Linux.

The goal of this repository is to keep my `.bashrc` small while organizing shell functions into reusable modules. Most functions automate repetitive tasks that I frequently perform during software development, data science projects, and system administration.

## Structure

```text
bash-utils/
├── archive/
│   ├── delete_nixbld_users.sh
│   └── update-touchpad.sh
├── file-utils.sh
└── README.md
```

### `file-utils.sh`

Utility functions for working with files.

| Function      | Description                                                                                                                                                                                      |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `print_files` | Prints the contents of text files matching a shell pattern. Supports recursive search through a configurable directory depth. Particularly useful when sharing project files with LLMs.          |
| `copy_as_md`  | Copies one or more files to a destination directory while replacing their extension with `.md`. Useful when preparing Quarto (`.qmd`) or R Markdown (`.Rmd`) files for Markdown-based workflows. |

## Archived Scripts

The `archive/` directory contains one-time or infrequently used scripts that are kept as references instead of being loaded into the shell.

| Script                   | Purpose                                                                           |
| ------------------------ | --------------------------------------------------------------------------------- |
| `delete_nixbld_users.sh` | Removes `nixbld` users created by Nix after uninstalling it from the host system. |
| `update-touchpad.sh`     | Restores a preferred touchpad button mapping using `xinput`.                      |

## Loading the Utilities

Add the following line to your `~/.bashrc`:

```bash
source ~/bash-utils/file-utils.sh
```

Reload your shell:

```bash
source ~/.bashrc
```

## Design Principles

This project follows a few simple principles:

* Keep `.bashrc` focused on configuration.
* Group related functions into small modules.
* Document every public function with a Roxygen2-inspired header.
* Include built-in `--help` documentation whenever appropriate.
* Prefer readability over clever Bash tricks.
* Archive one-time migration scripts instead of deleting them immediately.

## Future Modules

As additional utilities are created, they may be organized into separate modules such as:

```text
bash-utils/
├── file-utils.sh
├── git-utils.sh
├── docker-utils.sh
├── quarto-utils.sh
├── system-utils.sh
└── archive/
```

The objective is to gradually build a small personal Bash standard library, reducing the need to repeatedly search for common shell commands or rely on external tools for simple automation tasks.

