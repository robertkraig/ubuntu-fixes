# Claude Code Memories

## What this is

Claude Code keeps a per-directory memory in
`~/.claude/projects/-home-<user>/memory/`. These are the memories for my
home directory — mostly how I like Claude to work with me in herdr:

- `herdr-type-dont-execute.md` — system commands go in a named herdr pane I can see
- `herdr-run-scripts-visibly.md` — when I say "run a script", check herdr is up,
  ask which pane (or make a named one), and have me connect so I can watch

## Install

Run as your **regular user** (not root):

```bash
./install.sh
```

Existing memory files are never overwritten; new index lines are appended to
`MEMORY.md`.

## Save

After Claude learns something new on a machine, pull it back into the repo:

```bash
./save.sh
git status
```

## Files

- `memory/` — the memory files and `MEMORY.md` index
- `install.sh` — copy memories into `~/.claude` (no overwrite)
- `save.sh` — copy memories from `~/.claude` back into the repo
