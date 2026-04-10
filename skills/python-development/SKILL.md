---
trigger: "Working in a Python project"
---

# Python Development

This skill documents Python project best practices and automates the developer workflow via Make. It extends `makefile-automation-basic` with a project virtual environment managed by `uv sync`.

---

## Project Structure

Use a **flat layout**: the package lives at the repo root, not under `src/`.

```
my-project/
├── pyproject.toml
├── Makefile
├── .pre-commit-config.yaml
├── mypackage/
│   ├── __init__.py
│   └── core.py
├── test_core.py          ← co-located with source
└── README.md             ← documents Makefile targets for common tasks
```

Every project includes a `README.md` that documents how to run common developer tasks using Make. Use the `README.md` in this skill directory as a template. It should cover at minimum: running tests, linting, formatting, and resetting the environment.

Tests are **co-located** with source files: `test_foo.py` lives next to `foo.py`. This keeps tests close to the code they cover and avoids a separate `tests/` directory.

---

## uv

All Python tooling is managed via [uv](https://docs.astral.sh/uv/).

```bash
uv python install 3.12       # install a specific Python version
uv venv                      # create .venv in current directory
uv add requests              # add a runtime dependency
uv add --dev pytest ruff     # add dev dependencies
uv sync --all-groups         # install all dependency groups into .venv
uv run pytest                # run a command in the project venv
```

Never activate the venv manually. Use `uv run` or rely on Make targets.

---

## Makefile Targets

| Target | Command | Description |
|--------|---------|-------------|
| `make test` | `pytest` | Run all tests |
| `make lint` | `ruff check .` | Check for linting errors |
| `make format` | `ruff format .` | Auto-format code |
| `make hooks` | `pre-commit install` | Install git hooks (inherited) |
| `make pre-commit` | `pre-commit run` | Run all hooks manually (inherited) |
| `make clean` | remove `.tools/` and `.venv/` | Full reset |

All targets automatically install their dependencies when needed. The venv is rebuilt automatically when `pyproject.toml` changes — the `$(PROJECT_DEPS)` marker file lists `pyproject.toml` as a prerequisite.

---

## Ruff

[Ruff](https://docs.astral.sh/ruff/) is the linter and formatter.

```bash
make lint      # ruff check .
make format    # ruff format .
```

Configure in `pyproject.toml` under `[tool.ruff]`. See the template for recommended rule sets (`E`, `W`, `F`, `I`, `UP`, `B`, `SIM`).

---

## ty (Type Checker)

[ty](https://github.com/astral-sh/ty) is Astral's experimental type checker. It is **pre-release (alpha)** and not included in a Make target by default.

```bash
uv run ty check    # run manually
```

Because `ty` is in alpha, `pyproject.toml` must include:

```toml
[tool.uv]
prerelease = "if-necessary-or-explicit"
```

---

## pytest

Tests use **co-location**: `test_foo.py` sits next to `foo.py`. Both naming conventions are supported:
- `test_*.py`
- `*_test.py`

Configure in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["."]
python_files = ["test_*.py", "*_test.py"]
norecursedirs = [".venv", ".tools", "dist", "build"]
```

---

## Pre-commit Philosophy

Only hooks that **reduce merge conflicts** belong in `.pre-commit-config.yaml`:

- `ruff` — linting with auto-fix (import sort is part of ruff's `I` ruleset)
- `ruff-format` — canonical code formatting
- Basic file hygiene: trailing whitespace, end-of-file newline, YAML validity, merge conflict markers, large files

Heavy analysis (full type checking with ty, full pytest runs) belongs in **CI**, not pre-commit. Pre-commit should be fast and non-blocking for developers.

---

## pyproject.toml

Use the template at `pyproject.toml` in this skill directory. Key sections:

- `[project]` — package metadata, `requires-python = ">=3.12"`, runtime dependencies
- `[dependency-groups]` — dev tools: pytest, ruff, ty (use dependency groups, not optional dependencies)
- `[tool.uv]` — `prerelease = "if-necessary-or-explicit"` for ty alpha
- `[tool.ruff]` — line length 88, target Python 3.12
- `[tool.ruff.lint]` — rule selection and per-file ignores (S101 assert in tests)
- `[tool.pytest.ini_options]` — test discovery configuration
- `[tool.ty]` — placeholder; see https://github.com/astral-sh/ty for options
