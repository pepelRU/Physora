import SwiftUI

struct ToolsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PhysoraBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        toolsHeader
                        VStack(spacing: 12) {
                            NavigationLink(value: ToolRoute.converter) {
                                ToolCard(
                                    title: "Конвертер единиц",
                                    subtitle: "Длина, масса, давление, энергия и ещё 8 величин",
                                    systemImage: "arrow.left.arrow.right",
                                    tint: .physoraAccent,
                                    chips: ["м → км", "кг → г", "°C → K"]
                                )
                            }
                            NavigationLink(value: ToolRoute.calculator) {
                                ToolCard(
                                    title: "Научный калькулятор",
                                    subtitle: "Степени, корни, тригонометрия и логарифмы",
                                    systemImage: "function",
                                    tint: .physoraMint,
                                    chips: ["sin", "√", "log", "×10ⁿ"]
                                )
                            }
                        }
                        .buttonStyle(PressableScaleButtonStyle())
                        localNote
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Инструменты")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Закрыть инструменты")
                }
            }
            .navigationDestination(for: ToolRoute.self) { route in
                switch route {
                case .converter:
                    UnitConverterView()
                case .calculator:
                    CalculatorView()
                }
            }
        }
    }

    private var toolsHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Считать быстро.\nБез запросов к AI.")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Конвертер и калькулятор работают на устройстве и доступны без интернета.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            IconBadge(systemImage: "wrench.and.screwdriver.fill", tint: .physoraAccent, size: 48)
        }
    }

    private var localNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.physoraMint)
                .padding(.top, 1)
            Text("Данные не отправляются в сеть. Результаты вычисляются детерминированным локальным кодом Physora.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }
}

private enum ToolRoute: Hashable {
    case converter
    case calculator
}

private struct ToolCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let chips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 46, height: 46)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 2)
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }
            HStack(spacing: 6) {
                ForEach(chips, id: \.self) { chip in
                    Text(chip)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(tint.opacity(0.08), in: Capsule())
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }
}
