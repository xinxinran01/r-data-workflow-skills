# 三阶段配置和审核契约

## 参数

表A/表B分别记录 path、format、sheet/layer、encoding、key、稳定 row_id、保留列。空间输入通过 sf::st_layers 检查层，通过 attr(x, "sf_column") 检查活动几何列。不得硬编码 Shape。

默认 exact 优先、左连接、缺失键不匹配、trimws 清洗、fuzzy=true 时 Levenshtein 距离阈值4、候选方向 only_B → only_A、special_belong=false、dissolve=false。阈值可调整，它是字符编辑距离，不是概率。短名称或多层行政区需额外上下文。大表先按已知地区分块，避免无上限笛卡尔积。

每个阶段重读原始文件、配置和已审核文件；不依赖之前 R 会话中的对象。记录输入文件校验和、字段映射和运行标识，审核文件对应旧输入时报告失效。

## 阶段一

派生输出：only_in_A.csv、only_in_B.csv、similar_mapping_candidates.csv；必要时 duplicate_keys_A.csv、duplicate_keys_B.csv、missing_keys.csv。候选列包括 b_id、b_name、a_id、a_name、distance、decision、note，decision 初始 pending。审核中 accept/reject/pending 含义明确，不自动接受最近项。

对只有名称且重复的输入，先分配稳定行ID并报告；无法唯一定位映射时禁止最终应用。helpers.R 的名称映射要求B键唯一，不支持模糊合并重复实体。

## 阶段二

读取 similar_mapping_reviewed.csv：新增引用必须能在原表定位；不允许同一B有冲突决定、重复接受对、已精确匹配B被重复分配。用户已有明确映射或对话中逐项给定决定时可记录来源后生成审核文件，不必要求重复手工填写。

只对剩余B输出 remaining_B_for_belong.csv、belong_mapping_template.csv。归属表用 special_b_name、belongs_to，可加稳定ID、decision、note。未启用归属时跳过；没有剩余项时不制造人工任务。

## 阶段三

审核决定仅对已验证输入应用。多个B映射同一A后，需要确定每个数值字段的汇总含义。sum_preserve_na 仅用于用户确认可加的数量；部分缺失时同时报告 missing_count，不能把部分合计当成完整总量。默认辅助连接要求B键唯一。

空键不匹配（dplyr 可用 na_matches="never"）；用明确的匹配标记区分“已匹配但指标缺失”和“未匹配”。输出 joined.csv 或带属性 GPKG、unmatched_after_similar.csv，以及映射来源/聚合前后总数审计。默认最多一个B属性记录匹配到每个A记录；A允许已解释的碎片重复，基准行数是用户确认的 dissolve 之后的A。

保持A字段和顺序，冲突的B字段加后缀并记录；sf 的空间列不进入普通属性聚合。GPKG写入新路径或新图层，不删除既有文件。回读验证几何数量、CRS、唯一标识及关键属性。

## 辅助函数范围

reconcile_keys 输出 key 列的两侧差异、b_name/a_name/distance 候选及缺失键行号。safe_left_join 只处理 data.frame 属性，不接受 sf；空间项目将B准备为唯一属性表后用 sf/dplyr 左连接并单独核验几何。apply_review 只应用显式 accept，不负责归属聚合。示例中的审核表为合成测试决定，不可用来跳过真实审核。
