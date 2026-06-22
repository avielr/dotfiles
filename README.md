# dotfiles

Personal dev environment configs — shell, tmux, git, and Claude Code. Designed to seed a fresh machine (e.g. the always-on Ubuntu Server box) with one command.

## Install

```bash
git clone https://github.com/avielr/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` symlinks everything into `$HOME` and is safe to re-run.

## What's here

| Path | Links to | What |
|---|---|---|
| `zsh/.zshrc`, `zsh/.p10k.zsh` | `~/.zshrc`, `~/.p10k.zsh` | oh-my-zsh + powerlevel10k prompt, kube/dev context segment, fzf Ctrl-R |
| `tmux/.tmux.conf` | `~/.tmux.conf` | tpm + resurrect/continuum/fzf, mouse, pane CWD titles |
| `git/.gitconfig` | `~/.gitconfig` | gh credential helper, identity |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code model, hooks, statusline, enabled plugins + marketplaces |
| `claude/CLAUDE.md`, `claude/RTK.md` | `~/.claude/` | global instructions (CLAUDE.md `@RTK.md`-includes the RTK reference) |
| `claude/hooks/`, `claude/statusline-command.sh` | `~/.claude/` | RTK rewrite PreToolUse hook + statusline |
| `claude/commands/` | `~/.claude/commands` | custom slash commands |
| `claude/plugins/{known_marketplaces,blocklist}.json` | `~/.claude/plugins/` | plugin registry (plugins themselves reinstall from their marketplaces) |

## Secrets

API keys are **never** committed. `.zshrc` sources `~/.secrets/env` if it exists:

```bash
mkdir -p ~/.secrets
cp secrets/env.example ~/.secrets/env
chmod 600 ~/.secrets/env
# then edit ~/.secrets/env and fill in real keys
```

## Prerequisites

The shell config assumes a few tools. `install.sh` prints the exact install commands for: oh-my-zsh, powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting, and tmux's tpm. Plus: `zsh`, `tmux`, `fzf`, `git`, `gh`, `kubectl` (+ optional `kubectx`/`kubens`).

## Notes

- The `claude/settings.json` `hooks` path is absolute (`/home/aviel/.claude/hooks/rtk-rewrite.sh`); if the username differs on a new machine, update that one path.
- `rtk` (Rust Token Killer) is a separate binary — install it independently for the RTK hook/statusline to do anything.
