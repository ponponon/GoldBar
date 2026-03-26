import SwiftUI
import Charts

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
                    GoldBadgeIcon(size: 20)
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
                    Text("汇率源: \(priceManager.exchangeRateSource)")
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("刷新频率：\(priceManager.refreshIntervalOption.title)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $priceManager.refreshIntervalOption) {
                        ForEach(RefreshIntervalOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("历史走势（\(priceManager.selectedCurrency.rawValue)/克）")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    if priceManager.priceHistory.count >= 2 {
                        Chart(priceManager.priceHistory) { point in
                            LineMark(
                                x: .value("时间", point.timestamp),
                                y: .value("价格", priceManager.displayPrice(for: point.priceUSD))
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 110)
                    } else {
                        Text("数据采集中，稍后将显示折线图")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(height: 40, alignment: .leading)
                    }
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
                            await priceManager.fetchExchangeRates()
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
                GoldBadgeIcon(size: 12)
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

struct GoldBadgeIcon: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.2),
                            Color(red: 0.94, green: 0.62, blue: 0.13)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: size * 0.08)
                .padding(size * 0.12)
            Text("G")
                .font(.system(size: size * 0.52, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.95))
        }
        .frame(width: size, height: size)
        .shadow(color: .orange.opacity(0.3), radius: size * 0.12, y: size * 0.06)
    }
}
