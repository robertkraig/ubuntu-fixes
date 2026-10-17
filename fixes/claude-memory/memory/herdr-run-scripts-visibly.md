---
name: herdr-run-scripts-visibly
description: "When the user says to run a script: check herdr is running, ask which pane (or make a named one), and ask them to connect so they can watch"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 686e4225-a187-48ae-a591-9ddfbe9f76ef
  modified: 2026-10-17T20:04:06.611Z
---

When the user asks me to run a script, run it in a herdr pane they can watch, not in my own shell.

1. Confirm herdr is running (`herdr status` / `herdr pane list`). If it isn't, tell the user and ask them to start it.
2. Ask which existing pane to use, or offer to create a new one (`herdr pane split <pane> --direction down`), and always name it right away (`herdr pane rename <pane> <name>`).
3. Ask the user to connect to / focus that pane before I start, then run the script there and follow along with `herdr pane read`.

**Why:** The user said (2026-10-17): "I really enjoy watching how you do your work." They want to see scripts execute live.

**How to apply:** Applies to any "run a script" request, not just sudo or system changes. Builds on [[herdr-type-dont-execute]] (named panes, I may press Enter, user types the sudo password).
