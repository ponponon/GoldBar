import Foundation
import Combine

struct GoldResponse: Codable {
    let price: Double
}

struct ExchangeResponse: Codable {
    let result: String
    let rates: [String: Double]
}

enum Currency: String, CaseIterable, Codable {
    case CNY = "CNY"
    case USD = "USD"
    case JPY = "JPY"
    case EUR = "EUR"
    
    var symbol: String {
        switch self {
        case .CNY: return "¥"
        case .USD: return "$"
        case .JPY: return "¥"
        case .EUR: return "€"
        }
    }
    
    var name: String {
        switch self {
        case .CNY: return "人民币 (CNY)"
        case .USD: return "美元 (USD)"
        case .JPY: return "日元 (JPY)"
        case .EUR: return "欧元 (EUR)"
        }
    }
}

@MainActor
class GoldPriceManager: ObservableObject {
    @Published var currentPriceUSD: Double = 0.0
    @Published var previousPriceUSD: Double = 0.0
    @Published var selectedCurrency: Currency = .CNY {
        didSet {
            UserDefaults.standard.set(selectedCurrency.rawValue, forKey: "SelectedCurrency")
        }
    }
    @Published var exchangeRates: [String: Double] = [:]
    @Published var lastUpdated: Date = Date()
    
    private var timer: AnyCancellable?
    private let ounceToGram: Double = 31.1034768
    
    var currentDisplayPrice: Double {
        convertUSDToSelectedCurrency(currentPriceUSD)
    }
    
    var previousDisplayPrice: Double {
        convertUSDToSelectedCurrency(previousPriceUSD)
    }
    
    var isPositiveChange: Bool {
        currentPriceUSD >= previousPriceUSD
    }
    
    var changeString: String {
        guard previousPriceUSD != 0 else { return "+0.00%" }
        let diffPercent = ((currentPriceUSD - previousPriceUSD) / previousPriceUSD) * 100
        let sign = diffPercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", diffPercent))%"
    }
    
    init() {
        if let savedCurrency = UserDefaults.standard.string(forKey: "SelectedCurrency"),
           let currency = Currency(rawValue: savedCurrency) {
            self.selectedCurrency = currency
        }
        
        Task {
            await fetchExchangeRates()
            await fetchPrice()
            startTimer()
        }
    }
    
    func startTimer() {
        timer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.fetchExchangeRates()
                    await self?.fetchPrice()
                }
            }
    }
    
    func fetchExchangeRates() async {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(ExchangeResponse.self, from: data)
            if result.result == "success" {
                self.exchangeRates = result.rates
            }
        } catch {
            print("Error fetching exchange rates: \(error)")
        }
    }
    
    func fetchPrice() async {
        guard let url = URL(string: "https://api.gold-api.com/price/XAU") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(GoldResponse.self, from: data)
            
            if currentPriceUSD != 0 && abs(result.price - currentPriceUSD) > 0.0001 {
                previousPriceUSD = currentPriceUSD
            } else if currentPriceUSD == 0 {
                previousPriceUSD = result.price
            }
            
            self.currentPriceUSD = result.price
            lastUpdated = Date()
        } catch {
            print("Error fetching gold price: \(error)")
            if currentPriceUSD == 0 {
                let mockPrice = 2150.45
                previousPriceUSD = mockPrice
                currentPriceUSD = mockPrice
            }
        }
    }
    
    private func convertUSDToSelectedCurrency(_ priceUSD: Double) -> Double {
        let rate = exchangeRates[selectedCurrency.rawValue] ?? defaultRate(for: selectedCurrency)
        return (priceUSD * rate) / ounceToGram
    }
    
    private func defaultRate(for currency: Currency) -> Double {
        switch currency {
        case .USD:
            return 1.0
        case .CNY:
            return 7.2
        case .JPY:
            return 150.0
        case .EUR:
            return 0.92
        }
    }
}
