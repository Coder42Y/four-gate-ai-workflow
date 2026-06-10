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
| `取值地图增补.md` | 阶段2：给 `code-self-review` 加 §6.9（查绕路非裸数字） | 并进现有 skill |
| `CLAUDE.md片段-回灌与阶段纪律.md` | 四阶段常驻提醒 | 粘进项目 CLAUDE.md |
| `skills/verify-closure/SKILL.md` | 阶段3 · 验证闭环（**第一枪**） | 软链进 ~/.claude/skills |
| `skills/attribute-rootcause/SKILL.md` | 阶段0 · 归因 | 软链进 ~/.claude/skills |
| `安装.sh` | 一键软链两个 Skill（幂等/可卸载） | `bash 安装.sh`（旧版，推荐用 `deploy.sh`） |
| `deploy.sh` | **一键部署**：全局 Skills + 项目级模板 + CLAUDE.md 注入 | `bash deploy.sh /path/to/project` |

> 配套读 `../AI全栈开发工作流指南.md`（**描述性**：AI 实际做了什么、数千次调用分布）。本套是**规范性**：该强制什么。

## 一键部署

```bash
# 仅全局安装（软链 Skills 到 ~/.claude/skills/）
bash deploy.sh

# 全局 + 部署到指定项目（自动探测技术栈、生成模板、注入 CLAUDE.md）
bash deploy.sh /path/to/your/project

# 查状态
bash deploy.sh --check /path/to/your/project

# 卸载
bash deploy.sh --uninstall /path/to/your/project
```

部署后需手动完成：编辑 `ai-workflow/环境真相档案.md` 中的 `[待填]` 项。

> 旧版 `安装.sh` 仍可用（仅全局安装），建议迁移到 `deploy.sh`。

## 最小起步（三天）

0. **装** `bash deploy.sh /path/to/project`（一键搞定全局 + 项目）。
1. **Day1** 启用 `verify-closure` + 立铁律"没实证不说修好了" → 立刻拦假成功。
2. **Day2** 完善 `ai-workflow/环境真相档案.md`，AI 每会话先读。
3. **Day3** 建立取值地图 + 按需并进 `code-self-review` §6.9。

详见 `推广手册.md` §4。

## 真正新建的只有 2 个 Skill

验证、归因。取值地图复用 `code-self-review`；真相档案是文档；回灌是习惯。**刻意不臃肿。**
