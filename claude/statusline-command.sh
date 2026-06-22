#!/usr/bin/env bash
# Claude Code statusline — one line, split:
#   LEFT:  dir · branch[●][@worktree] · Model[1M] · ▮▮▯▯▯▯▯▯▯▯ 28% · venv/node
#   RIGHT: cost: $0.42 · lines: +156/-23 · 5h: 23% · 7d: 41% · eff:high

input=$(cat)
j() { jq -r "$1 // empty" <<<"$input"; }

cwd=$(j '.workspace.current_dir // .cwd')
model_id=$(j '.model.id')
model_dn=$(j '.model.display_name')
ctx_pct=$(j '.context_window.used_percentage')
ctx_size=$(j '.context_window.context_window_size')
cost_usd=$(j '.cost.total_cost_usd')
lines_added=$(j '.cost.total_lines_added')
lines_removed=$(j '.cost.total_lines_removed')
rl_5h=$(j '.rate_limits.five_hour.used_percentage')
rl_7d=$(j '.rate_limits.seven_day.used_percentage')
effort=$(j '.effort.level')
worktree=$(j '.worktree.name // .workspace.git_worktree')

DIM=$'\033[38;5;240m'
DIR=$'\033[38;5;111m'
BR=$'\033[38;5;176m'
MD=$'\033[38;5;215m'
ACC=$'\033[38;5;220m'
G=$'\033[38;5;108m'
Y=$'\033[38;5;179m'
R=$'\033[38;5;167m'
RST=$'\033[0m'
SEP="${DIM} · ${RST}"

# strip ANSI, count visible chars
vlen() {
  local s
  s=$(printf '%s' "$1" | sed -E $'s/\x1b\\[[0-9;]*m//g')
  echo "${#s}"
}

# terminal width: try tty, then env, then default
cols=$( (stty size </dev/tty) 2>/dev/null | awk '{print $2}')
[ -z "$cols" ] && cols=$( (tput cols </dev/tty) 2>/dev/null)
[ -z "$cols" ] && cols=${COLUMNS:-120}
# small safety buffer for harness padding
cols=$((cols - 4))
[ "$cols" -lt 40 ] && cols=40

short_cwd="${cwd/#$HOME/~}"
IFS='/' read -ra parts <<< "$short_cwd"
if [ "${#parts[@]}" -gt 4 ]; then
  short_cwd="${parts[0]}/${parts[1]}/…/${parts[-2]}/${parts[-1]}"
fi

git_seg=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  br=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
       || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
  dirty=""
  git -C "$cwd" diff --quiet HEAD 2>/dev/null || dirty="●"
  git_seg="${BR}${br}${RST}${R}${dirty}${RST}"
fi
[ -n "$worktree" ] && git_seg="${git_seg}${DIM}@${RST}${BR}${worktree}${RST}"

# model.display_name is generic ("Opus") — parse model.id for the version
short_model="$model_dn"
case "$model_id" in
  claude-opus-4-7*)   short_model="Opus 4.7" ;;
  claude-opus-4-6*)   short_model="Opus 4.6" ;;
  claude-opus-4-5*)   short_model="Opus 4.5" ;;
  claude-sonnet-4-6*) short_model="Sonnet 4.6" ;;
  claude-sonnet-4-5*) short_model="Sonnet 4.5" ;;
  claude-haiku-4-5*)  short_model="Haiku 4.5" ;;
  claude-*)
    short_model=$(awk -F- '{
      if (NF>=4) { f=toupper(substr($2,1,1)) substr($2,2); printf "%s %s.%s", f, $3, $4 }
      else print $0
    }' <<<"$model_id")
    ;;
esac
ctx_badge=""
if [ -n "$ctx_size" ] && [ "$ctx_size" -ge 1000000 ] 2>/dev/null; then
  ctx_badge="${DIM} 1M${RST}"
fi

extras=""
if [ -n "$VIRTUAL_ENV" ]; then
  extras="${SEP}${Y}($(basename "$VIRTUAL_ENV"))${RST}"
elif [ -f "$cwd/.python-version" ]; then
  extras="${SEP}${Y}py:$(cat "$cwd/.python-version" 2>/dev/null)${RST}"
fi
if [ -f "$cwd/package.json" ]; then
  nv=$(node -v 2>/dev/null)
  [ -n "$nv" ] && extras="${extras}${SEP}${G}node:${nv#v}${RST}"
fi

# right-side segments
ctx_seg=""
if [ -n "$ctx_pct" ]; then
  pct_int=${ctx_pct%.*}; [ -z "$pct_int" ] && pct_int=0
  if   [ "$pct_int" -ge 80 ]; then clr=$R
  elif [ "$pct_int" -ge 50 ]; then clr=$Y
  else                              clr=$G
  fi
  filled=$((pct_int/10)); [ "$filled" -gt 10 ] && filled=10
  empty=$((10-filled))
  bar=""
  for ((i=0; i<filled; i++)); do bar+="▮"; done
  for ((i=0; i<empty;  i++)); do bar+="▯"; done
  ctx_seg="${clr}${bar} ${pct_int}%${RST}"
fi

cost_seg=""
if [ -n "$cost_usd" ] && awk -v c="$cost_usd" 'BEGIN{exit !(c>0)}'; then
  cost_fmt=$(awk -v c="$cost_usd" 'BEGIN{printf "%.2f", c}')
  cost_seg="${DIM}cost:${RST} ${ACC}\$${cost_fmt}${RST}"
fi

lines_seg=""
la=${lines_added:-0}; lr=${lines_removed:-0}
if [ "$la" != "0" ] || [ "$lr" != "0" ]; then
  lines_seg="${DIM}lines:${RST} ${G}+${la}${RST}${DIM}/${RST}${R}-${lr}${RST}"
fi

rl_seg=""
if [ -n "$rl_5h" ]; then
  rl_seg="${DIM}5h:${RST} ${rl_5h%.*}%"
  [ -n "$rl_7d" ] && rl_seg="${rl_seg}${SEP}${DIM}7d:${RST} ${rl_7d%.*}%"
fi

eff_seg=""
[ -n "$effort" ] && [ "$effort" != "medium" ] && eff_seg="${DIM}eff:${RST}${effort}"

# compose
left="${DIR}${short_cwd}${RST}"
[ -n "$git_seg" ] && left="${left}${SEP}${git_seg}"
left="${left}${SEP}${MD}${short_model}${RST}${ctx_badge}"
[ -n "$ctx_seg" ] && left="${left}${SEP}${ctx_seg}"
left="${left}${extras}"

right_parts=()
[ -n "$cost_seg"  ] && right_parts+=("$cost_seg")
[ -n "$lines_seg" ] && right_parts+=("$lines_seg")
[ -n "$rl_seg"    ] && right_parts+=("$rl_seg")
[ -n "$eff_seg"   ] && right_parts+=("$eff_seg")

right=""
for ((i=0; i<${#right_parts[@]}; i++)); do
  [ "$i" -gt 0 ] && right+="${SEP}"
  right+="${right_parts[$i]}"
done

# pad left/right to terminal width
ll=$(vlen "$left")
rl=$(vlen "$right")
gap=$((cols - ll - rl))
[ "$gap" -lt 1 ] && gap=1
pad=$(printf '%*s' "$gap" '')

if [ -n "$right" ]; then
  printf "%s%s%s" "$left" "$pad" "$right"
else
  printf "%s" "$left"
fi
