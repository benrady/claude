#!/usr/bin/env bash
# Bootstrap an agentic development workstation.
#
# Deploys the workstation CLAUDE.md and skills (as symlinks into ~/.claude), then
# configures git identity and credentials for each organization under ~/src. Every
# direct subdirectory of ~/src that is not itself a git repository is treated as a
# GitHub organization/user. The script is idempotent: it fills in only what is
# missing and prompts for any identity or token it does not yet have.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SRC="$HOME/src"
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

# Validate a PAT against the GitHub API without exposing it in the process list.
token_is_valid() {
  local token="$1" code
  code="$(curl -s -o /dev/null -w '%{http_code}' --config - https://api.github.com/user <<EOF
header = "Authorization: Bearer ${token}"
EOF
)"
  [[ "$code" == "200" ]]
}

configure_org() {
  local org="$1"
  local org_config="$HOME/.gitconfig-$org"
  local cred_file="$HOME/.git-credentials-$org"
  log "Organization: $org"

  # 1. Conditional include in ~/.gitconfig (single-valued, so this is idempotent).
  git config --global "includeIf.gitdir:$SRC/$org/.path" "$org_config"

  # 2. Commit identity, persisted in ~/.gitconfig-<org>.
  if [[ -z "$(git config --file "$org_config" --get user.email 2>/dev/null || true)" ]]; then
    local name email
    read -rp "    git user.name for '$org': " name
    read -rp "    git user.email for '$org': " email
    git config --file "$org_config" user.name "$name"
    git config --file "$org_config" user.email "$email"
    info "wrote identity to $org_config"
  else
    info "ok: identity ($(git config --file "$org_config" --get user.email))"
  fi

  # 3. Dir-scoped credential store with a Personal Access Token.
  if [[ -f "$cred_file" ]]; then
    info "ok: credential store $cred_file"
    return
  fi
  local token
  read -rsp "    GitHub PAT for '$org' (input hidden): " token
  printf '\n'
  ( umask 077; printf 'https://%s:%s@github.com\n' "$org" "$token" > "$cred_file" )
  chmod 600 "$cred_file"
  git config --file "$org_config" --unset-all credential."https://github.com".helper 2>/dev/null || true
  git config --file "$org_config" --add credential."https://github.com".helper ""
  git config --file "$org_config" --add credential."https://github.com".helper "store --file=$cred_file"
  info "wrote credential store $cred_file"
  if token_is_valid "$token"; then
    info "verified PAT against github.com"
  else
    info "WARNING: PAT did not validate against github.com - saved anyway, check it"
  fi
}

configure_orgs() {
  if [[ ! -d "$SRC" ]]; then
    log "No ~/src directory found; no organizations to configure."
    return
  fi
  local found=0 dir name
  for dir in "$SRC"/*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    if [[ -e "$dir/.git" ]]; then
      log "Skipping '$name': a git repository directly under ~/src is not an org."
      log "  Move it under an org directory, e.g. ~/src/<org>/$name."
      continue
    fi
    found=$((found + 1))
    configure_org "$name"
  done
  if [[ "$found" -eq 0 ]]; then
    log "No organization directories found under ~/src; nothing to configure."
    log "Create one with: mkdir ~/src/<org>   then re-run: make bootstrap"
  else
    log "Configured $found organization(s)."
  fi
}

deploy_workstation_files
configure_orgs
log "Bootstrap complete."
