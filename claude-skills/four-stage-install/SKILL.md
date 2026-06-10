---
name: four-stage-install
description: Install the Four Stage AI Workflow into the current business repository. Invoke manually with `/four-stage-install` after `cd` into the target repo and starting Claude Code. This command runs the remote bootstrap installer, injects project workflow files, and updates the global workflow skills.
disable-model-invocation: true
argument-hint: "Run from the target repo root"
allowed-tools: Bash(curl:*)
---

# Four Stage Installer

Run the remote bootstrap installer for the current Claude Code working directory.

Install result:

!`curl -fsSL https://raw.githubusercontent.com/Coder42Y/four-gate-ai-workflow/master/bootstrap.sh | bash`

After the command finishes:

1. Report whether installation succeeded.
2. Tell the user to edit `ai-workflow/环境真相档案.md` and fill every `[待填]`.
3. Tell the user to restart Claude Code if the newly installed workflow skills do not appear immediately.
4. Tell the user that daily coding now happens in this business repo, using prompts such as:

```text
开始前准备：帮我把这个需求问完整
先归因，不要急着写代码。现象是：...
验证闭环：这次改动是否真的生效？
```
