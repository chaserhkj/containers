---
id: TASK-3
title: Use grun to provide x11-ssh-askpass in arch-gui bootc images
status: To Do
assignee: []
created_date: '2026-07-09 02:22'
updated_date: '2026-07-09 02:25'
labels:
  - bootc
  - arch-gui
  - ssh
dependencies:
  - TASK-1
  - TASK-2
modified_files:
  - bootc/arch-gui/rootfs/usr/bin/grun-askpass
  - bootc/arch-gui/Containerfile
priority: medium
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The arch-gui bootc images need a working SSH_ASKPASS so that SSH key operations (e.g. ssh-add with encrypted keys, or SSH agent forwarding) can prompt the user for passphrases graphically. Since the grun script (TASK-1) knows how to find and set up the display environment, the askpass should be invoked through grun.

This task creates a thin wrapper script (e.g. /usr/bin/grun-askpass) that:
- Runs grun with lxqt-openssh-askpass as the target command
- Errors out if grun cannot find a GUI environment (no display, no fallback succeeds)

That's it — the wrapper is a one-liner adapter. SSH_ASKPASS env var is set to point at this wrapper.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An x11-ssh-askpass program is installed in the arch-gui bootc image
- [ ] #2 The askpass dialog renders correctly when triggered by ssh-add or other SSH operations inside a GUI session
- [ ] #3 A thin wrapper script (e.g. /usr/bin/grun-askpass) invokes grun to run lxqt-openssh-askpass
- [ ] #4 The wrapper exits with an error when grun cannot find a GUI environment (no display and no fallback succeeds)
<!-- AC:END -->
