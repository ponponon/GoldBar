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
    @Published var previousPriceCNY: Double = 0.0
    @Published var exchangeRate: Double = 7.2 // Default fallback
    @Published var lastUpdated: Date = Date()
    
    private var timer: AnyCancellable?
    private let ounceToGram: Double = 31.1034768
    
    var isPositiveChange: Bool {
        currentPriceCNY >= previousPriceCNY
    }
    
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
        // Set refresh interval to 30 seconds as per user's request
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
        // Using a public exchange rate API (USD to CNY)
        // This endpoint does not require an API key
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(ExchangeResponse.self, from: data)
            if result.result == "success", let cnyRate = result.rates["CNY"] {
                self.exchangeRate = cnyRate
                print("Fetched exchange rate: \(exchangeRate)")
            }
        } catch {
            print("Error fetching exchange rate: \(error)")
        }
    }
    
    func fetchPrice() async {
        // Use a publicly available gold price API
        guard let url = URL(string: "https://api.gold-api.com/price/XAU") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(GoldResponse.self, from: data)
            
            let pricePerGramCNY = (result.price * exchangeRate) / ounceToGram
            
            if currentPriceCNY != 0 {
                previousPriceCNY = currentPriceCNY
            } else {
                previousPriceCNY = pricePerGramCNY
            }
            
            currentPriceUSD = result.price
            currentPriceCNY = pricePerGramCNY
            lastUpdated = Date()
            print("Fetched gold price (USD/oz): \(currentPriceUSD), (CNY/g): \(currentPriceCNY)")
        } catch {
            print("Error fetching gold price: \(error)")
            // Fallback for demo if API fails
            if currentPriceCNY == 0 {
                let mockUSD = 2150.45
                currentPriceUSD = mockUSD
                currentPriceCNY = (mockUSD * exchangeRate) / ounceToGram
                previousPriceCNY = currentPriceCNY - 0.5
            }
        }
    }
}
