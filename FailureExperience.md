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

## 🟡 错误 2: 涨跌幅频繁归零 (Logic Flaw)

### 1. 现象 (Issue)
用户反馈涨跌幅“不更新”或经常显示 `+0.00`。

### 2. 原因 (Root Cause)
- **基准价更新过快**: 原逻辑在每 30 秒的刷新周期中，无论金价是否发生实际变动，都会将 `previousPrice` 更新为 `currentPrice`。
- **市场平稳期**: 在金价波动不剧烈时，连续两个周期的价格大概率完全一致，导致差值计算始终为 0。

### 3. 解决方案 (Fix)
- **条件更新基准**: 仅当新获取的价格与当前显示的价格存在**实质性差异**（如差值 > 0.001）时，才将当前价存档为 `previousPrice`。
- **逻辑定义**: 涨跌幅现在定义为：`当前价 - 上一次发生变动的价格`。

### 4. 得到的经验 (Lessons Learned)
- **业务逻辑 vs 物理周期**: 数据的“刷新周期”不应等同于业务上的“比较基准”。
- **用户感知**: 用户关注的是“金价最近一次动了多少”，而不是“过去 30 秒动了多少”。设计指标时需从用户心理预期出发。

---

## 🟢 总结 (Summary)
每次在修改网络请求逻辑前，必须检查对应的 API 端点返回格式是否与代码中定义的模型完全一致。对于 UI 显示指标，需确保其变动逻辑符合真实业务场景（如对比上一次变动而非上一个时间片）。
