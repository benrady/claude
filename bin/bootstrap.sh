#!/usr/bin/env bash
# Bootstrap an agentic development workstation.
#
# Deploys the workstation CLAUDE.md and skills as symlinks into ~/.claude, so they
# are available to every agent on this workstation. Idempotent: existing correct
# symlinks are left in place, and a pre-existing non-symlink is backed up before
# being replaced.
#
# Per-org git identity and credentials are NOT configured here. They live in
# ~/.gitconfig via `includeIf "gitdir:~/src/<org>/"` includes that pull in
# ~/.gitconfig-<org>; see the "Commit attribution" section of CLAUDE.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_DIR="$HOME/.claude"
SKILLS_SRC="$REPO_ROOT/skills"

log()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }

# Link $2 -> $1, backing up an existing non-symlink and replacing a wrong symlink.
link_into_place() {
  local target="$1" link="$2"
  if [[ -L "$link" ]]; then
    if [[ "$(readlink "$link")" == "$target" ]]; then
      info "ok: $link"
      return
    fi
    rm "$link"
  elif [[ -e "$link" ]]; then
    mv "$link" "$link.bak"
    info "backed up existing $link -> $link.bak"
  fi
  ln -s "$target" "$link"
  info "linked: $link -> $target"
}

deploy_workstation_files() {
  log "Deploying workstation files"
  mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/skills"
  link_into_place "$REPO_ROOT/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  local skill name
  for skill in "$SKILLS_SRC"/*/; do
    [[ -d "$skill" ]] || continue
    name="$(basename "$skill")"
    link_into_place "${skill%/}" "$CLAUDE_DIR/skills/$name"
  done
}

deploy_workstation_files
log "Bootstrap complete."
