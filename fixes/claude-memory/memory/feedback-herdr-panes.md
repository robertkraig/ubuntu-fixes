---
name: feedback-herdr-panes
description: "How to run commands and scripts in herdr — visible panes, naming, sudo pattern"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9d0fe937-b21e-4353-b280-89282212c3c8
  modified: 2026-10-17T20:21:37.646Z
---

Run system-changing commands (apt, sudo, config edits) in a herdr pane the user can see, not silently in my own shell. Read-only checks from my own shell are fine.

**Why:** User said "you have to type the commands in my terminal" — they want to see every change. They also said "I really enjoy watching how you do your work."

**How to apply:**
- Type commands with `herdr pane send-text <pane> "<cmd>"`, then press Enter with `herdr pane send-keys <pane> Enter`. Tell the user to enter their sudo password in that pane. Follow output with `herdr pane read`.
- If the current pane is busy (e.g. powertop running), split a new one: `herdr pane split <pane> --direction down`, then ALWAYS name it immediately: `herdr pane rename <new-pane> <descriptive-name>` (e.g. `claude-commands`).
- When asked to run a script: confirm herdr is running, ask which pane to use or offer to create a named one, ask the user to focus that pane first so they can watch it execute live.
- Never create an unlabeled pane. User explicitly asked that new panes/tabs always be labeled.
- The labeled command-line pane is `w2:p6`. Check `herdr pane list` to find free panes.
