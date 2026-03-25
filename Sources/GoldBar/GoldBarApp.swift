import SwiftUI

@main
struct GoldBarApp: App {
    @StateObject private var priceManager = GoldPriceManager()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("实时金价")
                        .font(.headline)
                    Spacer()
                    Text(priceManager.lastUpdated, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .bottom, spacing: 4) {
                    Text(priceManager.selectedCurrency.symbol)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", priceManager.currentDisplayPrice))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("/克")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    let rate = priceManager.exchangeRates[priceManager.selectedCurrency.rawValue] ?? 1.0
                    Text("汇率: 1 USD ≈ \(String(format: "%.2f", rate)) \(priceManager.selectedCurrency.rawValue)")
                    Text("国际金价: $\(String(format: "%.2f", priceManager.currentPriceUSD))/盎司")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("切换币种：\(priceManager.selectedCurrency.name)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $priceManager.selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text(currency.rawValue).tag(currency)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                HStack {
                    Text("涨跌幅:")
                        .font(.subheadline)
                    Text(priceManager.changeString)
                        .font(.subheadline.bold())
                        .foregroundColor(priceManager.isPositiveChange ? .green : .red)
                    Text(priceManager.isPositiveChange ? "▲" : "▼")
                        .font(.caption)
                        .foregroundColor(priceManager.isPositiveChange ? .green : .red)
                }
                
                Divider()
                
                HStack {
                    Button(action: {
                        Task {
                            await priceManager.fetchPrice()
                        }
                    }) {
                        Label("立即刷新", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(role: .destructive, action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Label("退出程序", systemImage: "power")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .frame(minWidth: 300)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "goldbar.fill")
                Text(String(format: "%.1f", priceManager.currentDisplayPrice))
                Text(priceManager.selectedCurrency.rawValue)
                    .font(.system(size: 10, weight: .bold))
                Text(priceManager.isPositiveChange ? "▲" : "▼")
                    .foregroundColor(priceManager.isPositiveChange ? .green : .red)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
