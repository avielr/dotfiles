---
description: Show current superpowers workflow phase and exact next commands to run
argument-hint: "[-a] [-c]"
allowed-tools: [Bash, Read, Glob]
---

# Workflow Status

Detect the current superpowers workflow phase from project state and print exact next commands.

## Step 0 — Detect mode

Parse `$ARGUMENTS`:
- `-c` → **cleanup mode**: show worktree cleanup report (see Step C below), then stop
- `-a` → **all mode**: show all projects regardless of phase
- _(no flags)_ → **active mode**: show only projects with an active worktree (Phase 3)

Also detect context:
1. Run `git rev-parse --show-toplevel` to get repo root
2. Run `git worktree list` — if current working directory is inside a worktree (not the main repo), extract branch name → derive topic slug → single-project mode (regardless of flags, except `-c`)
3. If on main/master, apply the mode filter above

## Step 1 — Gather state

Run in parallel:
- `ls docs/plans/ 2>/dev/null` — find files in plans dir (always use main repo root path)
- `git branch --show-current` — current branch
- `git worktree list` — active worktrees

## Step 2 — Parse

For each `*-design.md` file found (sort descending — most recent first):

- **topic slug**: strip date prefix + `-design.md` suffix
  e.g. `2026-02-25-my-topic-design.md` → `my-topic`
- **branch**: `feature/<slug>`
- **plan file**: any `docs/plans/*-<slug>.md` that does NOT end in `-design.md`
- **worktree path**: `.worktrees/feature/<slug>`
- **phase**:
  - No design doc → 0
  - Design doc, no plan file → 1
  - Plan file, worktree NOT in `git worktree list` → 2
  - Plan file, worktree IS in `git worktree list` → 3

In **active mode** (default): only show projects where Phase = 3. If no active projects exist, show a brief note and list the Phase 1/2 projects as a summary line each (no details).

In **all mode** (`-a`): show all projects with full detail.

In **single-project mode** (inside a worktree): show only that project.

If a plan file exists, also read it to extract:
- The `**Goal:**` line (trim the `**Goal:**` prefix)
- All `### Task N:` or `## Task N:` lines → collect task names → count them

For each Phase 3 project, also run:
`git log --oneline master..feature/<slug> | wc -l` → commit count ahead of master

## Step 3 — Output as markdown

Print output as plain markdown text (no ANSI codes). Use bold, inline code, and the symbols below for visual structure.

### Symbols
- Worktree active: `🟢 active`
- Worktree missing: `🟡 not created yet`
- Plan found: `✅`
- Plan missing: `❌`
- Phase 3 badge: `🟢`
- Phase 2 badge: `🟡`
- Phase 1 badge: `🟡`
- Phase 0 badge: `🔴`

### Output format (active mode — default)

```
## Workflow Status  _(showing active only — use `-a` for all)_

---

### ❯ [1/1] `investigation-perf-optimization`

| | |
|---|---|
| **design** | `docs/plans/2026-02-25-investigation-perf-optimization-design.md` |
| **plan** | `docs/plans/2026-02-25-investigation-perf-optimization-plan.md` ✅ |
| **branch** | `feature/investigation-perf-optimization` |
| **worktree** | `/Users/.../investigation-perf-optimization` 🟢 active |

> **Goal:** Eliminate sequential tool-call bottleneck in SRE investigation agents
> **19 tasks:** Run existing tests · Add tool loading preamble · Add Performance Rules · …

### 🟢 Phase 3 — execution complete (17 commits)

...phase commands...

---

_Waiting (no active worktree):_
- 🟡 `knowledge-curator` — Phase 2, plan written
- 🟡 `devops-ai-group` — Phase 2, plan written
- 🟡 `multi-agent-sre-investigation` — Phase 2, plan written

_Run `/workflow -a` to see full details for all projects._
```

Key rules:
- In active mode: full detail for Phase 3 only; Phase 0/1/2 shown as a compact summary list at the bottom
- If no Phase 3 projects: skip the "showing active only" note, show all with full detail (same as `-a`)
- Task list: join first 3 task names with ` · ` then `· …` if more
- If plan file missing: omit Goal/tasks blockquote, show `_(no plan file yet)_`
- Omit trailing `---` after the last entry
- In single-project mode: omit the `[1/N]` numbering — just show `❯ \`slug\``
- Worktree paths in the table: use absolute path from `git worktree list` output

### Phase command blocks

**Phase 0:**
```
### 🔴 Phase 0 — not started

_Start here:_
\`\`\`
/superpowers:brainstorming
\`\`\`
```

**Phase 1:**
```
### 🟡 Phase 1 — design done, plan needed

_Run in a new terminal:_
\`\`\`
/superpowers:using-git-worktrees feature/<slug>
/superpowers:writing-plans docs/plans/<design-doc>
\`\`\`
```

**Phase 2:**
```
### 🟡 Phase 2 — plan written, worktree needed

_Run in a new terminal:_
\`\`\`
/superpowers:using-git-worktrees feature/<slug>
/superpowers:executing-plans docs/plans/<plan-file>
\`\`\`
```

**Phase 3 — not yet executing** (0 commits ahead of master):
```
### 🟢 Phase 3 — ready to execute

_In this session (worktree already active):_
\`\`\`
/superpowers:subagent-driven-development docs/plans/<plan-file>
\`\`\`

_In a new session:_
\`\`\`
cd <absolute-worktree-path>
/superpowers:subagent-driven-development docs/plans/<plan-file>
\`\`\`
```

**Phase 3 — execution complete** (>0 commits ahead of master):
```
### 🟢 Phase 3 — execution complete (N commits)

_In this session:_
\`\`\`
/superpowers:verification-before-completion
/superpowers:finishing-a-development-branch
\`\`\`

_In a new session:_
\`\`\`
cd <absolute-worktree-path>
/superpowers:verification-before-completion
/superpowers:finishing-a-development-branch
\`\`\`
```

## Step C — Cleanup mode (`-c`)

Run in parallel:
- `git worktree list --porcelain` — full worktree details
- `git branch --merged master` — branches already merged into master
- `git branch -vv` — to detect branches with gone remotes

For each worktree (excluding the main repo checkout):

1. **Merged** — branch appears in `git branch --merged master`: safe to remove
2. **Gone remote** — branch shows `[origin/...: gone]` in `git branch -vv`: remote deleted, likely safe
3. **Active** — has commits ahead of master and remote not gone: still in use, skip

Output:

```
## Worktree Cleanup

---

**Safe to remove** (branch merged or remote gone):

| worktree | branch | reason |
|---|---|---|
| `.worktrees/perf-optimization` | `perf-optimization` | merged into master |

_Remove with:_
\`\`\`
git worktree remove .worktrees/perf-optimization
git branch -d perf-optimization
\`\`\`

---

**Still active** (skip):

| worktree | branch | commits ahead |
|---|---|---|
| `.worktrees/feature/investigation-perf-optimization` | `feature/investigation-perf-optimization` | 17 |
```

If nothing to clean up: print `_All worktrees are active — nothing to remove._`

## Notes
- `docs/plans/` must be read from main repo root — resolve via `git worktree list` first line
- Multiple design docs → most recent first
- Absolute worktree paths come from `git worktree list` output, never constructed manually
