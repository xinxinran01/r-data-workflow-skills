---
name: r-table-reconciliation-join
description: Use when a user needs R-based two-table reconciliation, auditable left joins, unmatched-name reports, fuzzy candidate review, or spatial attribute matching. 适用于两表对账、名称差异匹配、人工审核后左连接和地图属性融合。
---

# R 两表匹配与对账

以表A为主，先明确数据粒度和匹配依据，输出可追溯的差异与候选，再应用审核后的映射。可独立处理普通表，也可为地图生成带属性的 GPKG。

## 项目与环境

默认补齐 Project.Rproj、00_admin、01_data/raw、01_data/derived、02_code、03_output；尊重已有布局，不移动原始数据。显式项目根目录；代码/配置放 02_code，派生表与 GPKG 放 derived，报告放 output。新运行使用独立目录或版本名，保护原有结果和人工审核文件。

检查 Rscript 的 PATH、Windows R-core InstallPath 或用户路径，并实际验证版本。按需检查 readr/readxl、sf、dplyr、stringdist；说明缺失项。保留 R 技术路线，说明实际运行环境和已运行步骤。

## 执行流程

先读 [workflow.md](references/workflow.md)。从实际文件检查格式、编码、sheet/layer、匹配列、唯一键、缺失键、重复键和 sf 活动几何列。代码编号按字符处理。字段能检查就不反复询问；关联粒度、数值合并规则、歧义对应关系不能猜。

1. 阶段一：保留原始键，温和清洗，输出两侧独有项、重复/空键报告及相似候选。使用 [helpers.R](scripts/helpers.R) 的基础检查，针对实际输入生成可独立运行的项目脚本。
2. 阶段二：读取用户已有审核或明确的匹配决定；验证后为尚未覆盖的B生成可选归属模板。需要人工判断的候选保持 pending。不要把重命名文件或“继续”当成自动同意所有候选。
3. 阶段三：应用精确匹配和审核映射；仅按已明确规则聚合，再左连接并输出。只需精确匹配且不存在歧义时可直接完成，不强制等待空审核。
4. 检查 A 行序、粒度、匹配标记、B 来源、汇总守恒、几何/CRS 和输出回读。匹配率根据匹配键标记计算，不能根据人口或其他指标是否 NA 判断。

## 关键边界

候选允许一个B对应多个A，表示多个待选项。最终一对多分配必须有用户明确的复制/分摊规则；人口、病例不能按候选直接复制累加。多个B归属一个A时逐列定义 sum/加权/保留/不适用，率和百分比不能直接相加，全缺失合计保持 NA。

默认缺失键永不相互匹配；不擅自删除“卫生院”“街道”等可能改变实体的字词。辅助 safe_left_join 对非空B重复键停止，需要先解决歧义或按明确规则汇总。

sf 数据用 st_geometry 和活动几何列，不把列名字符串传入 st_union。仅按用户要求合并碎片；合并前验证标识和属性一致性，面积需核对 CRS 和单位。行政区版本/层级冲突先列出，不擅自替换地区代码。

## 快速试用

“使用 $r-table-reconciliation-join，把 raw 的地图和人口表对账，先输出差异和候选，我审核后再融合。”

`Rscript scripts/demo.R 新的演示项目目录` 在本 Skill 目录运行。示例测试普通表、审核映射和防重复连接；sf 几何处理需在真实项目另行运行验证。完整三阶段项目代码由助手根据数据生成。
