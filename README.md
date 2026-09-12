# R 数据工作流 Skills

版本：0.1.0。将地址解析、两表对账和医学数据整理封装为三个可分别安装的 Skill。用户说明项目和目标，助手检查真实文件、选择参数，再生成并执行适配项目的 R 代码。

| Skill | 用途 |
|---|---|
| [r-geocode-addresses](r-geocode-addresses/SKILL.md) | 地址清洗、地理编码工作流、带坐标系与状态的结果表 |
| [r-table-reconciliation-join](r-table-reconciliation-join/SKILL.md) | 两侧差异、相似候选、人工审核与左连接、空间属性融合 |
| [r-clinical-data-summary](r-clinical-data-summary/SKILL.md) | 导入/合并、变量字典、衍生变量、描述表及可选单变量分析 |

三个目录都自带所需说明和辅助函数，可以独立安装。它们与[交互式地图 Skill](https://github.com/xinxinran01/interactive_map_with_R)组合使用，但没有强制依赖关系。

## 安装

在具有 Skill Installer 的 Codex 中复制下面这句话：

```text
使用 $skill-installer，从 xinxinran01/r-data-workflow-skills 的 main 分支安装以下三个目录：
r-geocode-addresses
r-table-reconciliation-join
r-clinical-data-summary
```

也可以只指定其中一个目录。安装后在后续对话中使用；若未出现，重新打开 Codex。仓库结构遵循 [OpenAI Skill 文档](https://learn.chatgpt.com/docs/build-skills)。这是一组直接安装的 Skill 文件夹，不是应用商店插件。

手动安装：下载仓库ZIP并解压，把需要的完整 Skill 目录复制到该 Codex 环境支持的个人技能目录。使用内置安装器的环境通常由安装器放入 `$CODEX_HOME/skills`（未设置时为 `~/.codex/skills`）；路径应以你的运行环境为准。不要只复制 SKILL.md，references 和 scripts 也需要保留。不要覆盖你已自行修改的同名版本。

## 最简单的使用方法

```text
使用 $r-geocode-addresses。我的项目是……，机构地址表在01_data/raw。
请先检查地址和字段，通过高德获取坐标，Key从AMAP_KEY环境变量读取。
```

```text
使用 $r-table-reconciliation-join。我的地图和人口表在项目raw目录。
以地图为主，先输出差异和相似候选，我审核后再做左连接。
```

```text
使用 $r-clinical-data-summary。读取项目raw中的数据和变量编码表，
保留编号，按编码表整理变量，输出清洗数据和描述性Word三线表，暂不回归。
```

以后你主要提供：项目路径、文件、变量含义、想要的结果。列名和文件结构能读取的部分由助手判断；事件编码、坐标要求、聚合含义等会改变结果的选择，需要有明确依据。

## 项目结构

```text
项目根目录/
├── Project.Rproj
├── 00_admin/
├── 01_data/
│   ├── raw/
│   └── derived/
├── 02_code/
└── 03_output/
```

缺少目录时补齐；已有不同约定时适配。数据留在项目中，不放进 Skill 安装目录。用户项目的真实数据、精确地址、API Key 不属于发布包。

## 运行环境与功能范围

R 在助手能够访问的执行环境中运行。当前离线示例在本机 R 4.5.2 验证；Skill 本身不是云端计算服务。地址在线解析会把必要地址字段发送给所选地图服务商，数据清洗和回填仍由 R 完成。

自带 helpers.R 是可复用的基础步骤，demo.R 是离线合成示例。完整业务脚本由助手根据实际文件生成，包括按需的在线请求、sf图层读取/融合、Word表格和回归。这个版本没有预置全服务商在线客户端、坐标转换引擎或完整统计应用。

离线示例仅依赖基础R。真实工作流按需使用 readr、readxl、dplyr、sf、stringdist、httr2、jsonlite、officer、flextable 等；助手先检查缺失包。空间数据的系统依赖及地图API的权限/限额需要按运行环境核对。

## 离线测试

在仓库根目录运行，目标目录必须尚不存在：

```text
Rscript r-geocode-addresses/scripts/demo.R demo-geocode
Rscript r-table-reconciliation-join/scripts/demo.R demo-join
Rscript r-clinical-data-summary/scripts/demo.R demo-summary
```

每个示例生成标准项目结构、合成结果与03_output/validation.txt，并执行正确性断言。地址示例使用合成响应，不发送网络请求。测试范围见 [VALIDATION.md](VALIDATION.md)。

## 以后怎么升级

共同行为修改相应 SKILL.md；条件性流程修改 references；稳定易错计算修改 helpers.R 并补充示例断言。发布新版本前用新的演示目录运行测试。修改任一 Skill 不要求其他两个同时升级。交互式地图和图表联动继续在地图 Skill 中发展。
