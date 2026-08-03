---
name: backlog
description: Backlog.md task management workflow. Load when user mentions "tasks", "backlog.md", "backlog", "todo", or when the conversation involves tracking or planning work items.
---

# Backlog.md Workflow

This project uses Backlog.md for task and project management.

## Instructions

Run `backlog instructions overview` before answering or taking action. Use the overview to decide whether to search, read, create, or update Backlog tasks.

Use the detailed guides when needed:
- `backlog instructions task-creation` for creating or splitting tasks
- `backlog instructions task-execution` for planning and implementation workflow
- `backlog instructions task-finalization` for completion and handoff

Use `backlog <command> --help` before running unfamiliar commands. Help shows options, fields, and examples.

Do not edit Backlog task, draft, document, decision, or milestone markdown files directly. Use the `backlog` CLI so metadata, relationships, and history stay consistent.

## Scope of Backlog Tasks

Backlog tasks represent work for **coding agents**. Never include acceptance
criteria that involve editing the wiki (`.wiki/`). The wiki is maintained by a
separate wiki manager agent and is read-only for coding agents. If wiki
documentation is needed for a task, it should come from reading existing wiki
content — never from creating or editing it.