---
id: TASK-2
title: Add shell hooks to auto-export envs to gui.env in arch-gui bootc images
status: To Do
assignee: []
created_date: '2026-07-09 02:15'
updated_date: '2026-07-09 02:18'
labels:
  - bootc
  - arch-gui
  - shell
dependencies:
  - TASK-1
modified_files:
  - bootc/arch-gui/rootfs/etc/profile.d/grun-env.sh
  - bootc/arch-gui/rootfs/etc/zsh/zprofile.d/grun-env.zsh
priority: medium
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The grun script (TASK-1) reads display environment variables from $XDG_RUNTIME_DIR/gui.env. This task adds shell hooks for both bash and zsh that automatically export environment variables to the appropriate env file on every interactive shell session.

The hooks should differentiate based on session context:

- **Within a GUI session** (WAYLAND_DISPLAY or DISPLAY is set): export display-related env vars to $XDG_RUNTIME_DIR/gui.env. This feeds the gui.env file that grun reads.
- **Outside a GUI session** (no display vars set, e.g. SSH, TTY, systemd service): export the current shell environment to $XDG_RUNTIME_DIR/shell.env. This captures the environment of an interactive shell session that may later be used to launch GUI applications.

This dual-file approach ensures that:
- gui.env always reflects the actual GUI session environment (updated on every interactive turn within the GUI)
- shell.env captures the environment of non-GUI interactive sessions, which can be useful for debugging or for tools that need to inherit the shell environment

The hooks should:
- Be installed as profile.d scripts or shell rc fragments for both bash and zsh
- Only trigger for interactive shells
- Only write to env files when the relevant environment has changed (avoid unnecessary writes)
- Handle the case where XDG_RUNTIME_DIR is not set
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Bash hook is installed and auto-exports display env vars to gui.env when inside a GUI session (WAYLAND_DISPLAY or DISPLAY is set)
- [ ] #2 Bash hook exports full shell env to shell.env when outside a GUI session (SSH, TTY, etc.)
- [ ] #3 Zsh hook is installed with the same GUI/non-GUI dual-file logic
- [ ] #4 Hooks only trigger for interactive shells (non-interactive shells are skipped)
- [ ] #5 Hooks avoid writing to env files when no relevant variables have changed
- [ ] #6 Hooks handle missing XDG_RUNTIME_DIR gracefully
- [ ] #7 Hooks are included in the arch-gui bootc image build
<!-- AC:END -->
