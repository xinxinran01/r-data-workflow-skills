# 参数与可追溯结果

## 输入与默认值

| 参数 | 默认/判定 |
|---|---|
| 项目 | 用户指定；不依赖 getwd() 推断 |
| CSV 编码 | 先检测并抽查中文；检测不可靠时询问；输出 UTF-8 |
| 编号 | 字符，不丢前导零 |
| 地址清洗 | 去首尾空白，保留门牌/楼栋/原地址 |
| 查询去重 | 服务商 + 城市上下文 + 清洗后地址 + 影响结果的参数 |
| 服务商 | 用户选择；未选择时给高德建议，不能擅自调用 |
| 密钥 | AMAP_KEY / BAIDU_MAP_KEY / TENCENT_MAP_KEY，运行时读取 |
| 超时 | 10秒，可改 |
| 额外重试 | 最多3次，仅暂时性错误 |
| 重试等待 | 0.5秒起，指数退避；遵循 Retry-After |
| 请求间隔 | 0.2秒起；根据账户配额加大，含重试和备选调用 |
| 名称备选 | 默认关闭；启用后记录查询方式和复核状态 |
| 输出坐标 | 默认保留接口原坐标，并明确记录；地图需求另核验 |

超时、429、部分5xx可重试；密钥无效、权限不足、额度耗尽等业务错误应停止批量请求并保存进度。除 HTTP 状态还必须检查 JSON 业务状态。不要打印可能含密钥的底层错误或请求对象。预算按唯一查询、备选、重试共同估计；缓存只存脱敏结果，不存密钥，跨运行复用前核对服务商、参数、时间和坐标系。

## 结果字段

每个原始行保留 source_row_id、address_original、address_clean、query_id。每个响应包含 query_id、longitude、latitude、status、coord_system；生产结果另加 provider、query_method、formatted_address、adcode、match_level、candidate_count、query_time、error_code（可脱敏）、review_reason。原始列与新增列重名时停止并明确重命名方案。

状态建议 missing_address、no_result、ambiguous、low_precision、api_error、ok。县市中心点不能冒充机构门牌级坐标。请求成功不等于地址准确。多候选默认不选第一条；用省市区约束筛选后仍不唯一则待审核。

helpers.R 的 prepare_addresses 适用于单一服务商/上下文批次；多个城市必须分批或生成包含城市的复合查询键。attach_geocodes 接受归一化响应表，不解析供应商原始 JSON；成功且数值有效的坐标才允许回填。空地址不请求。未返回响应记 no_result。GCJ-02 数值只是标签正确的服务坐标，不等于已适配任意底图。

## 在线代码必须完成的步骤

读取环境 Key → 严格验证输入与预算 → 分批唯一查询 → 限速、有限重试、业务状态处理 → 原子保存检查点 → 回填原始行 → 导出带状态的全量表及失败/复核表。进度文件写入当前运行的 derived 子目录；中断后从已成功查询继续。名称备选仍不能找到时保留失败。

用户仅要求生成代码时，交付能运行的完整代码与环境变量说明；没有 Key 时可以完成清洗、配置和离线试验，实际联网步骤报告未运行。

## 文档来源

运行时核对最新官方接口和账户限额：
- [高德地理编码](https://developer.amap.com/api/webservice/guide/api/georegeo)
- [百度地理编码](https://lbsyun.baidu.com/docs/webapi?title=geocoding/guide/webservice-geocoding-base)
- [腾讯位置服务](https://lbs.qq.com/service/webService/webServiceGuide/webServiceGeocoder)

这个发布版提供工作流、预处理/回填辅助函数和离线示例；不内置跨服务商在线客户端或坐标转换引擎。
