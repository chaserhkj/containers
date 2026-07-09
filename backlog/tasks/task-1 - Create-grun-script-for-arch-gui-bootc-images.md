---
id: TASK-1
title: Create grun script for arch-gui bootc images
status: To Do
assignee: []
created_date: '2026-07-09 02:12'
updated_date: '2026-07-09 02:12'
labels:
  - bootc
  - arch-gui
  - script
dependencies: []
modified_files:
  - bootc/arch-gui/rootfs/usr/bin/grun
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The grun script is a helper for arch-gui bootc images that automatically sets the correct environment variables for GUI applications. It works through a chain of fallback strategies:

1. Loads environment from $XDG_RUNTIME_DIR/gui.env if it exists
2. Uses the current environment if WAYLAND_DISPLAY or DISPLAY is already set
3. Checks systemd user session for display variables
4. Falls back to scanning /proc for user-owned processes with display environment variables

This is useful because GUI applications launched outside of a proper desktop session context (e.g. via SSH, systemd services, or container entrypoints) may not inherit the necessary display, dbus, or other environment variables needed to render correctly.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Script installs to /usr/bin/grun in the arch-gui bootc image
- [ ] #2 grun successfully launches a GUI application with display env vars inherited from gui.env file
- [ ] #3 grun falls back to scanning /proc for display env vars when no env file or systemd user session is available
- [ ] #4 grun respects GRUN_DISABLE_PROC env var to disable slow /proc scanning
- [ ] #5 Script exits with error when no display environment can be found
- [ ] #6 Documentation or usage examples exist for the script
<!-- AC:END -->
