---
name: herdr-type-dont-execute
description: "System-changing commands go into a named herdr pane the user can see (split one if needed); user later allowed me to press Enter too"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 15ce87e5-5a60-4ade-84bc-c613e24d6e47
  modified: 2026-10-17T05:40:28.731Z
---

When working in the user's herdr session, run system-changing commands (apt, sudo, config/dotfile edits) in a herdr pane the user can see, not silently in my own shell. Type with `herdr pane send-text <pane> "<cmd>"`. Read-only checks from my own shell are fine.

**Why:** The user said "you have to type the commands in my terminal" after I ran an upgrade without them; they want to see every change. Later (2026-10-16) they added: "you can make new panes too, split the pane into a new one when you need a place to run commands", "always give it a name", and "you can run the command too".

**How to apply:**
- If the existing pane is busy (e.g. powertop), split a new one: `herdr pane split <pane> --direction down`, and ALWAYS name it right away: `herdr pane rename <new-pane> <descriptive-name>` (e.g. `claude-commands`).
- After typing, I may press Enter myself (`herdr pane send-keys <pane> Enter`); sudo will prompt, so tell the user to enter their password in that pane. Then follow output with `herdr pane read`.
