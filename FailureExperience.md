# 失败经验记录 (Failure Experience)

本文件记录了在开发过程中遇到的错误、调试经验及解决方案，以避免 AI 在未来重犯类似的逻辑错误。

## 🔴 错误 1: 汇率 API 解析失败 (keyNotFound)

### 1. 现象 (Issue)
在运行应用时，控制台报错：
`keyNotFound(CodingKeys(stringValue: "conversion_rate", ...), ...)`
应用无法正确换算人民币金价，仅能显示美元价格。

### 2. 原因 (Root Cause)
- **API 限制**: 之前使用的 `v6.exchangerate-api.com` 在没有 API Key 的情况下，返回的 JSON 结构中不包含 `conversion_rate` 字段。
- **解析假设错误**: 代码中定义了 `struct ExchangeResponse` 预期包含 `conversion_rate` 字段，导致 JSONDecoder 无法找到对应的 Key。

### 3. 解决方案 (Fix)
- **更换稳定 API**: 切换至 `https://open.er-api.com/v6/latest/USD`，这是一个无需 API Key 即可获取 `rates` 字典的免费公开接口。
- **调整数据结构**: 
  - 将 `conversion_rate` 改为 `rates: [String: Double]`。
  - 从 `rates["CNY"]` 中精准提取汇率。

### 4. 得到的经验 (Lessons Learned)
- **外部 API 验证**: 在集成任何第三方 API 前，务必先在浏览器或 Postman 中测试其在**未授权状态下**（无 Key）的真实返回结构。
- **防御性编程**: 对于不确定的 API 响应，应优先考虑使用字典 (`[String: Any]`) 或可选类型，而非硬编码严格的 Codable 结构。
- **环境隔离**: 区分“演示/测试”与“生产”级别的 API。对于简单的工具类应用，优先选择完全公开、零门槛的 API 接口。

---

## 🟢 总结 (Summary)
每次在修改网络请求逻辑前，必须检查对应的 API 端点返回格式是否与代码中定义的模型完全一致。
