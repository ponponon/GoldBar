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
                    Text("¥")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", priceManager.currentPriceCNY))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("/克")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("汇率: 1 USD ≈ \(String(format: "%.2f", priceManager.exchangeRate)) CNY")
                    Text("国际金价: $\(String(format: "%.2f", priceManager.currentPriceUSD))/盎司")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                
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
            .frame(width: 220)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "goldbar.fill")
                Text(String(format: "%.1f", priceManager.currentPriceCNY))
                Text(priceManager.isPositiveChange ? "▲" : "▼")
                    .foregroundColor(priceManager.isPositiveChange ? .green : .red)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
