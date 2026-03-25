import Foundation
import Combine

struct GoldResponse: Codable {
    let price: Double
}

struct ExchangeResponse: Codable {
    let result: String
    let rates: [String: Double]
}

@MainActor
class GoldPriceManager: ObservableObject {
    @Published var currentPriceUSD: Double = 0.0
    @Published var currentPriceCNY: Double = 0.0
    @Published var previousPriceCNY: Double = 0.0 // 记录上一次“发生变动”的价格，而非上一个周期
    @Published var exchangeRate: Double = 7.2 // Default fallback
    @Published var lastUpdated: Date = Date()
    
    private var timer: AnyCancellable?
    private let ounceToGram: Double = 31.1034768
    
    // 涨跌判断：当前价格 vs 上一个不同的价格
    var isPositiveChange: Bool {
        currentPriceCNY >= previousPriceCNY
    }
    
    // 涨跌金额：相对于上一个不同价格的变动
    var changeString: String {
        let diff = currentPriceCNY - previousPriceCNY
        let sign = diff >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", diff))"
    }
    
    init() {
        // Initial fetch
        Task {
            await fetchExchangeRate()
            await fetchPrice()
            startTimer()
        }
    }
    
    func startTimer() {
        // 每 30 秒检查一次
        timer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.fetchExchangeRate()
                    await self?.fetchPrice()
                }
            }
    }
    
    func fetchExchangeRate() async {
        // ... (保持不变)
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(ExchangeResponse.self, from: data)
            if result.result == "success", let cnyRate = result.rates["CNY"] {
                self.exchangeRate = cnyRate
            }
        } catch {
            print("Error fetching exchange rate: \(error)")
        }
    }
    
    func fetchPrice() async {
        guard let url = URL(string: "https://api.gold-api.com/price/XAU") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(GoldResponse.self, from: data)
            
            let pricePerGramCNY = (result.price * exchangeRate) / ounceToGram
            
            // 核心修复逻辑：
            // 只有当新获取的价格与当前显示的价格“不同”时，才更新 previousPriceCNY
            // 这样 涨跌幅 就会显示“上一次变动”以来的幅度，而不是每 30 秒强行清零
            if currentPriceCNY != 0 && abs(pricePerGramCNY - currentPriceCNY) > 0.001 {
                previousPriceCNY = currentPriceCNY
            } else if currentPriceCNY == 0 {
                // 第一次获取数据时，基准价设为当前价
                previousPriceCNY = pricePerGramCNY
            }
            
            currentPriceUSD = result.price
            currentPriceCNY = pricePerGramCNY
            lastUpdated = Date()
            print("Fetched gold price (USD/oz): \(currentPriceUSD), (CNY/g): \(currentPriceCNY), Previous: \(previousPriceCNY)")
        } catch {
            // ... (保持不变)
            if currentPriceCNY == 0 {
                let mockUSD = 2150.45
                currentPriceUSD = mockUSD
                currentPriceCNY = (mockUSD * exchangeRate) / ounceToGram
                previousPriceCNY = currentPriceCNY
            }
        }
    }
}
