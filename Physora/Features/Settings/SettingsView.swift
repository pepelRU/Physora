import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            ZStack {
                PhysoraBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        appearanceSection
                        aiSection
                        solutionsSection
                        applicationSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .ai:
                    AISettingsView()
                case .about:
                    AboutPhysoraView()
                case .technologies:
                    TechnologiesView()
                case .privacy:
                    PrivacyPolicyView()
                }
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhysoraSectionHeader("Внешний вид", systemImage: "circle.lefthalf.filled")
            HStack(spacing: 9) {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        Haptics.light()
                        withAnimation(.snappy(duration: 0.25)) {
                            appState.theme = theme
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: theme.icon)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(appState.theme == theme ? Color.physoraAccent : Color.secondary)
                            Text(theme.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(appState.theme == theme ? Color.primary : Color.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            appState.theme == theme
                                ? Color.physoraAccent.opacity(0.10)
                                : Color.physoraSurfaceMuted.opacity(0.55),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    appState.theme == theme ? Color.physoraAccent.opacity(0.4) : Color.physoraStroke,
                                    lineWidth: appState.theme == theme ? 1.4 : 0.8
                                )
                        )
                    }
                    .buttonStyle(PressableScaleButtonStyle())
                    .accessibilityLabel("Тема: \(theme.title)")
                    .accessibilityValue(appState.theme == theme ? "Выбрано" : "")
                }
            }
            Text("Автоматический режим следует оформлению iOS.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 2)
        }
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhysoraSectionHeader("Искусственный интеллект", systemImage: "sparkles")
            NavigationLink(value: SettingsRoute.ai) {
                HStack(spacing: 13) {
                    Image(systemName: "brain.head.profile")
                        .font(.headline)
                        .foregroundStyle(Color.physoraAccent)
                        .frame(width: 42, height: 42)
                        .background(Color.physoraAccent.opacity(0.11), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("DeepSeek")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Circle()
                                .fill(appState.hasStoredAPIKey ? Color.physoraMint : Color.physoraAmber)
                                .frame(width: 6, height: 6)
                        }
                        Text(appState.hasStoredAPIKey
                             ? "\(appState.modelTitle) · ключ сохранён"
                             : "Ключ не добавлен")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.quaternary)
                }
                .padding(16)
                .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                        .strokeBorder(
                            appState.hasStoredAPIKey ? Color.physoraStroke : Color.physoraAmber.opacity(0.2),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(PressableScaleButtonStyle())
        }
    }

    private var solutionsSection: some View {
        @Bindable var appState = appState
        return VStack(alignment: .leading, spacing: 12) {
            PhysoraSectionHeader("Решения", systemImage: "doc.text.magnifyingglass")
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("Подробность объяснений")
                        .font(.subheadline.weight(.medium))
                    Picker("Подробность", selection: $appState.explanationDetail) {
                        ForEach(ExplanationDetail.allCases) { detail in
                            Text(detail.title).tag(detail)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(appState.explanationDetail.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)

                SettingsDivider()

                SettingsToggleRow(
                    title: "Перевод в СИ",
                    subtitle: "Просить модель переводить величины в систему СИ",
                    systemImage: "ruler",
                    isOn: $appState.autoSI
                )
                SettingsDivider()
                SettingsToggleRow(
                    title: "Автоматические чертежи",
                    subtitle: "Строить схемы из графических примитивов, если они нужны",
                    systemImage: "scribble.variable",
                    isOn: $appState.buildDiagrams
                )
                SettingsDivider()
                SettingsToggleRow(
                    title: "Дополнительные пояснения",
                    subtitle: "Показывать физический смысл и проверку результата",
                    systemImage: "text.quote",
                    isOn: $appState.showExtraExplanations
                )
            }
            .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
            )
        }
    }

    private var applicationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhysoraSectionHeader("Приложение", systemImage: "info.circle")
            VStack(spacing: 0) {
                NavigationLink(value: SettingsRoute.about) {
                    SettingsNavigationRow(
                        title: "О Physora",
                        subtitle: "Философия и возможности",
                        systemImage: "atom",
                        tint: .physoraAccent
                    )
                }
                SettingsDivider()
                NavigationLink(value: SettingsRoute.technologies) {
                    SettingsNavigationRow(
                        title: "Используемые технологии",
                        subtitle: "Swift 6, SwiftUI, SwiftData, Canvas",
                        systemImage: "cpu",
                        tint: .physoraMint
                    )
                }
                SettingsDivider()
                NavigationLink(value: SettingsRoute.privacy) {
                    SettingsNavigationRow(
                        title: "Политика конфиденциальности",
                        subtitle: "Данные, Keychain и DeepSeek",
                        systemImage: "hand.raised.fill",
                        tint: .physoraAmber
                    )
                }
                SettingsDivider()
                HStack {
                    Text("Версия")
                        .font(.subheadline)
                    Spacer()
                    Text(versionText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
            )
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

enum SettingsRoute: Hashable {
    case ai
    case about
    case technologies
    case privacy
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.physoraSeparator)
            .padding(.leading, 16)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.quaternary)
        }
        .padding(15)
        .contentShape(Rectangle())
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.physoraAccent)
                    .frame(width: 34, height: 34)
                    .background(Color.physoraAccent.opacity(0.09), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Color.physoraAccent)
        .padding(15)
    }
}
