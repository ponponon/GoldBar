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
    @Published var currentDisplayPrice: Double = 0.0
    @Published var previousDisplayPrice: Double = 0.0
    @Published var selectedCurrency: Currency = .CNY {
        didSet {
            UserDefaults.standard.set(selectedCurrency.rawValue, forKey: "SelectedCurrency")
            updateDisplayPrice()
        }
    }
    @Published var exchangeRates: [String: Double] = [:]
    @Published var lastUpdated: Date = Date()
    
    private var timer: AnyCancellable?
    private let ounceToGram: Double = 31.1034768
    
    var isPositiveChange: Bool {
        currentDisplayPrice >= previousDisplayPrice
    }
    
    var changeString: String {
        let diff = currentDisplayPrice - previousDisplayPrice
        let sign = diff >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", diff))"
    }
    
    init() {
        // Load saved currency preference
        if let savedCurrency = UserDefaults.standard.string(forKey: "SelectedCurrency"),
           let currency = Currency(rawValue: savedCurrency) {
            self.selectedCurrency = currency
        }
        
        // Initial fetch
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
                updateDisplayPrice()
                print("Fetched exchange rates successfully.")
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
            
            self.currentPriceUSD = result.price
            updateDisplayPrice()
            lastUpdated = Date()
            print("Fetched gold price (USD/oz): \(currentPriceUSD), Display: \(currentDisplayPrice) \(selectedCurrency.rawValue)")
        } catch {
            print("Error fetching gold price: \(error)")
            if currentPriceUSD == 0 {
                currentPriceUSD = 2150.45
                updateDisplayPrice()
            }
        }
    }
    
    private func updateDisplayPrice() {
        let rate = exchangeRates[selectedCurrency.rawValue] ?? (selectedCurrency == .USD ? 1.0 : 7.2)
        let priceInSelectedCurrency = (currentPriceUSD * rate) / ounceToGram
        
        if currentDisplayPrice != 0 && abs(priceInSelectedCurrency - currentDisplayPrice) > 0.001 {
            previousDisplayPrice = currentDisplayPrice
        } else if currentDisplayPrice == 0 {
            previousDisplayPrice = priceInSelectedCurrency
        }
        
        currentDisplayPrice = priceInSelectedCurrency
    }
}
