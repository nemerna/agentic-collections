#!/usr/bin/env bash
#
# Setup/teardown rh-automation skills for Cursor IDE.
#
# Creates lightweight wrapper SKILL.md files in ~/.cursor/skills/ that point
# back to the full skill implementations inside this repository. Cursor
# discovers these wrappers and the AI reads the real files on demand.
#
# Usage:
#   ./setup-cursor.sh              # install
#   ./setup-cursor.sh install      # install
#   ./setup-cursor.sh uninstall    # remove
#   ./setup-cursor.sh status       # check what's installed
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CURSOR_SKILLS_DIR="${CURSOR_SKILLS_DIR:-$HOME/.cursor/skills}"
PREFIX="rh-automation"

SKILLS=(
  aap-mcp-validator
  governance-readiness-assessor
  deployment-risk-analyzer
  governed-job-launcher
  job-failure-analyzer
  host-fact-inspector
  resolution-advisor
  execution-summary
)

AGENTS=(
  governance-assessor
  governance-deployer
  forensic-troubleshooter
)

# Also remove legacy skill names during uninstall
LEGACY_SKILLS=(
  mcp-aap-validator
  deployment-safety-checker
  governance-launcher
  troubleshooting-advisor
)

extract_frontmatter() {
  awk 'BEGIN{p=0} /^---$/{p++;next} p==1{print} p>=2{exit}' "$1"
}

install_skill() {
  local name="$1"
  local source_file="$2"
  local target_dir="$CURSOR_SKILLS_DIR/${PREFIX}-${name}"

  if [[ ! -f "$source_file" ]]; then
    echo "⚠  Skipping $name: $source_file not found"
    return
  fi

  local frontmatter
  frontmatter="$(extract_frontmatter "$source_file")"

  mkdir -p "$target_dir"
  cat > "$target_dir/SKILL.md" <<EOF
---
${frontmatter}
---

# How to execute

Read and follow the full skill implementation using the Read tool:

**Read** \`${source_file}\`

All relative paths inside that file (docs, templates, etc.) are relative to the
rh-automation pack root at \`${PACK_DIR}\`.
EOF
  echo "  ✓ ${PREFIX}-${name}"
}

install_agent() {
  local name="$1"
  local source_file="$2"
  local target_dir="$CURSOR_SKILLS_DIR/${PREFIX}-${name}"

  if [[ ! -f "$source_file" ]]; then
    echo "⚠  Skipping $name: $source_file not found"
    return
  fi

  local frontmatter
  frontmatter="$(extract_frontmatter "$source_file")"

  mkdir -p "$target_dir"
  cat > "$target_dir/SKILL.md" <<EOF
---
${frontmatter}
---

# How to execute

Read and follow the full agent workflow using the Read tool:

**Read** \`${source_file}\`

The agent orchestrates sub-skills that are also installed as Cursor skills
(prefixed with \`${PREFIX}-\`). When the agent says to invoke a skill, read the
corresponding Cursor skill.

All relative paths inside the file (docs, templates, etc.) are relative to the
rh-automation pack root at \`${PACK_DIR}\`.
EOF
  echo "  ✓ ${PREFIX}-${name} (agent)"
}

do_install() {
  echo "Installing rh-automation skills for Cursor…"
  echo "  Pack: $PACK_DIR"
  echo "  Target: $CURSOR_SKILLS_DIR"
  echo ""

  mkdir -p "$CURSOR_SKILLS_DIR"

  for skill in "${SKILLS[@]}"; do
    install_skill "$skill" "$PACK_DIR/skills/$skill/SKILL.md"
  done

  for agent in "${AGENTS[@]}"; do
    install_agent "$agent" "$PACK_DIR/agents/$agent.md"
  done

  echo ""
  echo "Done. Open a new Cursor chat to pick up the skills."
}

do_uninstall() {
  echo "Removing rh-automation skills from Cursor…"

  for skill in "${SKILLS[@]}"; do
    local dir="$CURSOR_SKILLS_DIR/${PREFIX}-${skill}"
    if [[ -d "$dir" ]]; then
      rm -rf "$dir"
      echo "  ✓ Removed ${PREFIX}-${skill}"
    fi
  done

  for agent in "${AGENTS[@]}"; do
    local dir="$CURSOR_SKILLS_DIR/${PREFIX}-${agent}"
    if [[ -d "$dir" ]]; then
      rm -rf "$dir"
      echo "  ✓ Removed ${PREFIX}-${agent}"
    fi
  done

  for legacy in "${LEGACY_SKILLS[@]}"; do
    local dir="$CURSOR_SKILLS_DIR/${PREFIX}-${legacy}"
    if [[ -d "$dir" ]]; then
      rm -rf "$dir"
      echo "  ✓ Removed legacy ${PREFIX}-${legacy}"
    fi
  done

  echo ""
  echo "Done. Open a new Cursor chat to apply."
}

do_status() {
  echo "rh-automation Cursor skill status:"
  echo ""

  local installed=0
  local total=$(( ${#SKILLS[@]} + ${#AGENTS[@]} ))

  for skill in "${SKILLS[@]}"; do
    local dir="$CURSOR_SKILLS_DIR/${PREFIX}-${skill}"
    if [[ -d "$dir" ]]; then
      echo "  ✓ ${PREFIX}-${skill}"
      ((installed++))
    else
      echo "  ✗ ${PREFIX}-${skill} (not installed)"
    fi
  done

  for agent in "${AGENTS[@]}"; do
    local dir="$CURSOR_SKILLS_DIR/${PREFIX}-${agent}"
    if [[ -d "$dir" ]]; then
      echo "  ✓ ${PREFIX}-${agent} (agent)"
      ((installed++))
    else
      echo "  ✗ ${PREFIX}-${agent} (not installed)"
    fi
  done

  echo ""
  echo "$installed / $total installed"
}

case "${1:-install}" in
  install)   do_install ;;
  uninstall) do_uninstall ;;
  status)    do_status ;;
  *)
    echo "Usage: $0 {install|uninstall|status}"
    exit 1
    ;;
esac
