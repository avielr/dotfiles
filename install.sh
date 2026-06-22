#!/usr/bin/env bash
# Dotfiles installer — symlinks shell, tmux, git, and Claude configs into $HOME.
# Idempotent. Safe to re-run. Does NOT touch secrets (see secrets/env.example).
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

link() { # link <src> <dest>
  mkdir -p "$(dirname "$2")"
  rm -rf "$2"
  ln -sf "$1" "$2"
  echo "  linked $2 -> $1"
}

echo "==> Shell (zsh)"
link "$DOTFILES/zsh/.zshrc"    "$HOME/.zshrc"
link "$DOTFILES/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

echo "==> tmux"
link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo "==> git"
link "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"

echo "==> Claude Code"
mkdir -p "$CLAUDE_DIR/plugins" "$CLAUDE_DIR/hooks"
link "$DOTFILES/claude/settings.json"          "$CLAUDE_DIR/settings.json"
link "$DOTFILES/claude/CLAUDE.md"              "$CLAUDE_DIR/CLAUDE.md"
link "$DOTFILES/claude/RTK.md"                 "$CLAUDE_DIR/RTK.md"
link "$DOTFILES/claude/statusline-command.sh"  "$CLAUDE_DIR/statusline-command.sh"
link "$DOTFILES/claude/hooks/rtk-rewrite.sh"   "$CLAUDE_DIR/hooks/rtk-rewrite.sh"
link "$DOTFILES/claude/hooks/.rtk-hook.sha256" "$CLAUDE_DIR/hooks/.rtk-hook.sha256"
chmod +x "$CLAUDE_DIR/statusline-command.sh" "$CLAUDE_DIR/hooks/rtk-rewrite.sh" 2>/dev/null || true
[ -d "$DOTFILES/claude/commands" ] && link "$DOTFILES/claude/commands" "$CLAUDE_DIR/commands"
for reg in known_marketplaces.json blocklist.json; do
  [ -f "$DOTFILES/claude/plugins/$reg" ] && link "$DOTFILES/claude/plugins/$reg" "$CLAUDE_DIR/plugins/$reg"
done
# Plugins themselves reinstall from the marketplaces listed in settings.json (enabledPlugins).

echo "==> Secrets"
if [ ! -f "$HOME/.secrets/env" ]; then
  echo "  No ~/.secrets/env yet. Create it from the template:"
  echo "    mkdir -p ~/.secrets && cp '$DOTFILES/secrets/env.example' ~/.secrets/env && chmod 600 ~/.secrets/env"
  echo "  then fill in your API keys (.zshrc sources it automatically)."
else
  echo "  ~/.secrets/env present (not managed by this repo) — good."
fi

cat <<'NOTE'
==> Optional prerequisites (install manually if missing):
  oh-my-zsh     : sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  powerlevel10k : git clone --depth=1 https://github.com/romkatv/powerlevel10k ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
  zsh plugins   : git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
                  git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  tmux tpm      : git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm   (then prefix+I inside tmux)
NOTE
echo "Done. Open a new zsh shell to load everything."
