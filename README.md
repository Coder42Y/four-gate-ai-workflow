# 四阶段 AI 开发工作流（项目实战提炼 · 同栈可推广）

把某政企合同项目（已脱敏）一个多月的真实 AI coding 经验，提炼成一套**能在同栈项目群推广的强制纪律**。专治"配置即行为 + 远端 CI 编译 + 手工运维 + 无 Flyway"这类项目的三个最贵错误：**不知真相就动手、为非代码问题写代码、没实证就说修好了**。

## 一图

![四阶段 AI 开发工作流说明图](assets/four-stage-flow.png)

> 可编辑源文件：`assets/four-stage-flow.svg`

## 文件导航

| 文件 | 是什么 | 给谁 |
|---|---|---|
| `四阶段蓝图.md` | 规范性总览（脊柱） | 想懂全貌 |
| `推广手册.md` | 为什么/三天起步/量化胜仗/回应质疑 | 负责人、推广 |
| `环境真相档案.md` | 阶段1底座 + **取值地图本体** + 脱敏实例 + 空白模板 | 落进每个项目根 |
| `取值地图增补.md` | 阶段2：给 `code-self-review` 加 §6.9（查绕路非裸数字） | `deploy.sh --install-review-addon` |
| `CLAUDE.md片段-回灌与阶段纪律.md` | 四阶段常驻提醒 | 粘进项目 CLAUDE.md |
| `skills/ai-task-preflight/SKILL.md` | 开工前准备：把模糊需求问成任务简报 | 软链进 Claude/Codex skills |
| `skills/verify-closure/SKILL.md` | 阶段3 · 验证闭环（**第一枪**） | 软链进 Claude/Codex skills |
| `skills/attribute-rootcause/SKILL.md` | 阶段0 · 归因 | 软链进 Claude/Codex skills |
| `claude-skills/four-stage-install/SKILL.md` | Claude Code 命令入口：`/four-stage-install` | 全局装一次 |
| `install-claude-command.sh` | 安装 Claude Code 命令入口 | 给同事第一次配置用 |
| `安装.sh` | 一键软链两个 Skill（幂等/可卸载） | `bash 安装.sh`（旧版，推荐用 `deploy.sh`） |
| `deploy.sh` | **一键部署**：全局 Skills + 项目级模板 + CLAUDE.md 注入 | `bash deploy.sh /path/to/project` |
| `四阶段工作流.html` | 静态说明页，用于讲解方法论 | 浏览器直接打开 |
| `四阶段使用说明.html` | 静态使用说明页：安装、调用、排错 | 给同事照着操作 |

> 配套读 `../AI全栈开发工作流指南.md`（**描述性**：AI 实际做了什么、多轮工具调用怎么分布）。本套是**规范性**：该强制什么。

## 推荐入口：Claude Code `/four-stage-install`

给 Claude Code 用户的推荐路径：先全局安装一次命令入口，之后每个新业务 repo 里用 slash command 接入。

```bash
curl -fsSL https://raw.githubusercontent.com/Coder42Y/four-gate-ai-workflow/master/install-claude-command.sh | bash
```

之后每个新业务 repo：

```bash
cd /path/to/business-repo
claude
```

在 Claude Code 里输入：

```text
/four-stage-install
```

它会在**当前业务 repo** 自动执行远程 bootstrap，生成 `ai-workflow/`、注入 `CLAUDE.md`，并全局安装/更新四阶段 workflow skills。日常 coding 不需要进入本仓库。

## 命令行部署

不用 Claude Code slash command 时，也可以在目标业务项目根目录直接运行：

```bash
curl -fsSL https://raw.githubusercontent.com/Coder42Y/four-gate-ai-workflow/master/bootstrap.sh | bash -s -- --with-review-addon /path/to/your/project
```

如果已经在目标项目根目录，可直接运行：

```bash
curl -fsSL https://raw.githubusercontent.com/Coder42Y/four-gate-ai-workflow/master/bootstrap.sh | bash
```

这会把工作流仓库缓存到 `~/.four-stage-ai-workflow`，之后自动调用 `deploy.sh`。重复执行会先更新缓存仓库，再重新部署。

```bash
# 仅全局安装（软链 Skills 到 ~/.claude/skills/ 和 ~/.codex/skills/）
bash deploy.sh

# 全局 + 部署到指定项目（自动探测技术栈、生成模板、注入 CLAUDE.md）
bash deploy.sh /path/to/your/project

# 安装 code-self-review 的取值地图增补（自动写入受管块，可重复运行升级）
bash deploy.sh --install-review-addon

# 部署项目时同时安装取值地图增补
bash deploy.sh --with-review-addon /path/to/your/project

# 查状态
bash deploy.sh --check /path/to/your/project

# 卸载
bash deploy.sh --uninstall /path/to/your/project
```

部署后需手动完成：编辑 `ai-workflow/环境真相档案.md` 中的 `[待填]` 项。

`四阶段工作流.html` 是方法论介绍页，适合打开给团队讲这套方法；`四阶段使用说明.html` 是操作说明页，适合同事第一次照着安装和调用。真正的落地入口是 Claude Code `/four-stage-install`，或命令行 `bootstrap.sh` / `deploy.sh`；项目内落地资产是生成到业务 repo 的 `ai-workflow/` 文档。

> 旧版 `安装.sh` 仍可用（仅做全局 skill 软链），建议迁移到 `deploy.sh`。

## 开工前准备

很多同事不是不会让 AI 写代码，而是开工前没准备好：目标、边界、复现、上下文、验收标准都不清楚。遇到这种任务，先触发 `ai-task-preflight`：

```text
开始前准备：帮我把这个需求问完整
```

它会一次问一个关键问题，并给推荐答案；如果答案能从代码或文档里查到，agent 应该自己查。最终产出一份「AI 任务简报」，再进入阶段 0 归因。

## 最小起步（三天）

0. **装**：Claude Code 用户先装 `/four-stage-install`，每个业务 repo 第一次输入 `/four-stage-install`；命令行用户可直接跑远程 `bootstrap.sh`。
1. **Day1** 启用 `ai-task-preflight` + `verify-closure`：先把需求问清楚，再立铁律"没实证不说修好了"。
2. **Day2** 完善 `ai-workflow/环境真相档案.md`，AI 每会话先读。
3. **Day3** 建立取值地图 + 执行 `bash deploy.sh --install-review-addon` 并进 `code-self-review` §6.9。

详见 `推广手册.md` §4。

## 真正新建的日常 Skill 只有 3 个

开工准备、验证、归因。另有一个 Claude Code 安装命令 `/four-stage-install`，只负责把本工作流接入当前业务 repo，不参与日常编码判断。取值地图复用 `code-self-review`；真相档案是文档；回灌是习惯。**刻意不臃肿。**
