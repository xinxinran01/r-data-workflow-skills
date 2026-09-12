---
name: r-clinical-data-summary
description: Use when a user needs R-based clinical or public-health data import, merging, codebook-driven variable definitions, derived variables, descriptive tables, or explicitly requested univariable analysis. 适用于医学数据整理、变量编码和描述性统计。
---

# R 数据整理与描述性统计

将用户模板中的导入、变量定义、描述性表格和可选单变量分析组织成可单独执行的模块。用户要求哪一步就完成哪一步；不默认扩展到回归、预测模型或自动筛选危险因素。

## 项目与运行

默认补齐 Project.Rproj、00_admin、01_data/raw、01_data/derived、02_code、03_output，已有项目约定优先。根目录作为显式参数，raw只读，代码/配置放02_code，clean数据放derived，表格报告放03_output。保护既有文件，用版本名或独立运行目录。

检查 Rscript PATH、Windows R-core InstallPath 或用户路径，并运行 --version；检查实际需要的包。生成 R 代码不等于已执行；找不到 R 时说明检查结果，保留代码且询问路径，不能静默换语言或远程环境。

## 模块路由

- 导入、合并、类型与衍生变量：先阅读 [data-preparation.md](references/data-preparation.md)。
- 描述性表格或 Word 三线表：阅读 [descriptive.md](references/descriptive.md)。
- 用户明确要求单变量/单因素回归：再阅读 [univariable.md](references/univariable.md)。它是可选模块，不是所有分析的固定最后一步。
- [helpers.R](scripts/helpers.R) 提供严格数值转换、显式编码映射和基本描述统计；复制到项目后使用。完整导入/合并、分组Word表和回归脚本由助手按配置生成。

## 信息与参数

先检查实际文件、工作表、列名、编码和样本取值；不要求用户重复提供可读取的信息。必须明确分析单位、合并方式/键、变量编码含义、单位、衍生规则；信息不足时先完成可确定的导入诊断，集中询问会改变结论的事项。

模块0集中保存 file/sheet/encoding、变量字典、merge、derived、missing、group、order、outputs、可选outcome/event/reference。项目脚本不得保留“请替换”占位符；未知关键规则在配置中明确标为未确定，并在受影响步骤报错，不猜测含义。

## 固定质量规则

ID和地区编码保留字符及前导零。转换失败报告原值和行号，不能静默变NA。变量字典显式维护 code、label、reference，不用 factor 的内部整数代替业务编码。重复随访不能直接当成独立受试者；先确认分析时点和单位。

默认保留原始行，描述统计逐变量报告有效N与缺失N；用户指定完整病例时记录筛选变量和排除前后人数。连续变量无有效值时输出NA，单一有效值不计算SD；分类水平保留字典顺序。

回归的事件水平、参照水平、连续变量尺度必须明确。只描述关联；不能自动把单变量P值当成因果证据或后续变量筛选规则。

## 交付与测试

输出清洗CSV及保留类型/标签的RDS、变量字典、缺失/转换/合并报告，以及所需的描述表和可选回归表。报告运行环境、实际执行范围、纳入人数、待澄清项和结果路径。Word表生成后检查内容，能够渲染时检查分页/列宽/中文字体；未检查不能声称版式已验证。

试用：“使用 $r-clinical-data-summary，按raw中的变量编码表整理Excel并输出描述性三线表，先不做回归。”

离线辅助函数示例：`Rscript scripts/demo.R 新的演示项目目录`（在Skill目录运行）。仅验证合成数据的转换与描述统计，不代表实际项目、回归或Word排版已通过验收。
