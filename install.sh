#!/usr/bin/env bash
# Symlink dotfiles into place
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Linking Claude configs..."
mkdir -p "$CLAUDE_DIR/plugins"

ln -sf "$DOTFILES/claude/settings.json" "$CLAUDE_DIR/settings.json"
ln -sf "$DOTFILES/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
# Remove dir if exists so symlink replaces it cleanly
rm -rf "$CLAUDE_DIR/commands"
ln -sf "$DOTFILES/claude/commands" "$CLAUDE_DIR/commands"

# Plugin manifests
ln -sf "$DOTFILES/claude/plugins/blocklist.json" "$CLAUDE_DIR/plugins/blocklist.json"
ln -sf "$DOTFILES/claude/plugins/known_marketplaces.json" "$CLAUDE_DIR/plugins/known_marketplaces.json"

# Plugin directories
for plugin_dir in "$DOTFILES/claude/plugins/*/"; do
  plugin_name="$(basename "$plugin_dir")"
  rm -rf "$CLAUDE_DIR/plugins/$plugin_name"
  ln -sf "$plugin_dir" "$CLAUDE_DIR/plugins/$plugin_name"
done

echo "Done. Claude configs linked from $DOTFILES/claude/"
