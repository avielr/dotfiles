# Aliases
alias cursor='/mnt/c/Program\ Files/cursor/Cursor.exe ~/.zshrc'
alias debugpod='kubectl run -it --rm --restart=Never debug --image=nicolaka/netshoot -- bash'
# Enable Powerlevel10k instant prompt (keep at the top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting kubectl)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Syntax highlighting and autosuggestions
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Envman
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# History settings
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=$HOME/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY

# FZF Ctrl+R reverse search
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
export FZF_CTRL_R_OPTS="--reverse --tiebreak=index"

# Maximum PATH
export PATH="$HOME/.local/bin:$HOME/.kubectx:$PATH"

# Kubectx / Kubens aliases
alias kctx=kubectx
alias kns=kubens

# Powerlevel10k prompt customization
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs context_segment time)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs battery)
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%F{cyan}╭─%f"
POWERLEVEL9K_MULTILINE_SECOND_PROMPT_PREFIX="%F{cyan}╰─%f"

# --- Compact context segment combining k8s, k3d, cloud, dev ---
function context_segment() {
  local segments=()
  
  # Kubernetes context + namespace
  if command -v kubectl &>/dev/null; then
    local ctx ns cluster
    ctx=$(kubectl config current-context 2>/dev/null)
    ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
    cluster=$(kubectl config view --minify --output 'jsonpath={..clusters[0].name}' 2>/dev/null)
    [[ -n $ctx ]] && segments+=("%F{yellow}⎈ ${ctx}${ns:+:${ns}}${cluster:+[${cluster}]}%f")
  fi

  # k3d cluster
  if command -v k3d &>/dev/null; then
    local k3d_cluster
    k3d_cluster=$(k3d cluster list --no-headers | awk '{print $1}' | head -n1)
    [[ -n $k3d_cluster ]] && segments+=("%F{blue}🟦 ${k3d_cluster}%f")
  fi

  # Cloud context
  if [[ -n "$AWS_PROFILE" ]]; then
    segments+=("%F{magenta}☁ AWS:${AWS_PROFILE}%f")
  elif [[ -n "$GCP_PROJECT" ]]; then
    segments+=("%F{blue}☁ GCP:${GCP_PROJECT}%f")
  fi

  # Dev environment
  if [[ -n "$VIRTUAL_ENV" ]]; then
    segments+=("%F{green}🐍 $(basename $VIRTUAL_ENV)%f")
  elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    segments+=("%F{green}🅒 ${CONDA_DEFAULT_ENV}%f")
  fi

  # Join with spaces
  echo "${(j: :)segments}"
}

# Assign to Powerlevel10k custom segment
POWERLEVEL9K_CUSTOM_CONTEXT="context_segment"

# Source Powerlevel10k config if exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export PATH="$HOME/.local/bin:$PATH"

# opencode
export PATH=/home/aviel/.opencode/bin:$PATH


# API keys & other secrets — kept OUT of version control.
# Copy secrets/env.example -> ~/.secrets/env and fill in real values.
[ -f "$HOME/.secrets/env" ] && source "$HOME/.secrets/env"
