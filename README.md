# 四阶段 AI 开发工作流（项目实战提炼 · 同栈可推广）

把某政企合同项目（已脱敏）一个多月的真实 AI coding 经验，提炼成一套**能在同栈项目群推广的强制纪律**。专治"配置即行为 + 远端 CI 编译 + 手工运维 + 无 Flyway"这类项目的三个最贵错误：**不知真相就动手、为非代码问题写代码、没实证就说修好了**。

## 一图

```
任务 ─▶ 阶段0 归因 ─▶ 阶段1 外部真相 ─▶ 阶段2 取值地图 ─▶ 阶段3 验证闭环 ─▶ 宣称完成
       是哪层?       代码外真相先核     钉到唯一正路      无实证不许说       │
       非代码不写码                    (走真API也会取错)   "修好了"          │
                              回灌：踩坑即写回档案，AI 抄写、人审 ◀──────────┘
```

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
| `安装.sh` | 一键软链两个 Skill（幂等/可卸载） | `bash 安装.sh`（旧版，推荐用 `deploy.sh`） |
| `deploy.sh` | **一键部署**：全局 Skills + 项目级模板 + CLAUDE.md 注入 | `bash deploy.sh /path/to/project` |
| `四阶段工作流.html` | 静态说明页，用于讲解方法论 | 浏览器直接打开 |

> 配套读 `../AI全栈开发工作流指南.md`（**描述性**：AI 实际做了什么、数千次调用分布）。本套是**规范性**：该强制什么。

## 一键部署

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

`四阶段工作流.html` 只是静态说明页，适合打开给团队讲这套方法。真正的落地入口仍是 `deploy.sh` 和生成到项目里的 `ai-workflow/` 文档。

> 旧版 `安装.sh` 仍可用（仅做全局 skill 软链），建议迁移到 `deploy.sh`。

## 开工前准备

很多同事不是不会让 AI 写代码，而是开工前没准备好：目标、边界、复现、上下文、验收标准都不清楚。遇到这种任务，先触发 `ai-task-preflight`：

```text
开始前准备：帮我把这个需求问完整
```

它会一次问一个关键问题，并给推荐答案；如果答案能从代码或文档里查到，agent 应该自己查。最终产出一份「AI 任务简报」，再进入阶段 0 归因。

## 最小起步（三天）

0. **装** `bash deploy.sh /path/to/project`（一键搞定全局 + 项目）。
1. **Day1** 启用 `ai-task-preflight` + `verify-closure`：先把需求问清楚，再立铁律"没实证不说修好了"。
2. **Day2** 完善 `ai-workflow/环境真相档案.md`，AI 每会话先读。
3. **Day3** 建立取值地图 + 执行 `bash deploy.sh --install-review-addon` 并进 `code-self-review` §6.9。

详见 `推广手册.md` §4。

## 真正新建的只有 3 个 Skill

开工准备、验证、归因。取值地图复用 `code-self-review`；真相档案是文档；回灌是习惯。**刻意不臃肿。**
