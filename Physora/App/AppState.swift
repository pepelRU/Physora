import Observation
import SwiftUI

enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case home
    case reference
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Главная"
        case .reference: "Справочник"
        case .settings: "Настройки"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .reference: "book.closed.fill"
        case .settings: "gearshape.fill"
        }
    }
}

enum InterfaceSize: String, CaseIterable, Identifiable, Sendable {
    case compact
    case standard
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: "Мельче"
        case .standard: "Обычный"
        case .large: "Крупнее"
        }
    }

    var offset: Int {
        switch self {
        case .compact: -1
        case .standard: 0
        case .large: 1
        }
    }

    func adjusted(_ size: DynamicTypeSize) -> DynamicTypeSize {
        let sizes: [DynamicTypeSize] = [
            .xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge,
            .accessibility1, .accessibility2, .accessibility3,
            .accessibility4, .accessibility5
        ]
        guard let current = sizes.firstIndex(of: size) else { return size }
        let target = min(max(current + offset, 0), sizes.count - 1)
        return sizes[target]
    }
}

enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Авто"
        case .light: "Светлая"
        case .dark: "Тёмная"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.stars.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Все задачи"
        case .favorites: "Избранное"
        }
    }
}

/// App-wide, non-secret preferences and navigational intent.
/// The DeepSeek key deliberately lives in KeychainManager instead of this type.
@MainActor
@Observable
final class AppState {
    enum DefaultsKey {
        static let theme = "physora.theme"
        static let interfaceSize = "physora.interfaceSize"
        static let modelID = "physora.modelID"
        static let explanationDetail = "physora.explanationDetail"
        static let autoSI = "physora.autoSI"
        static let buildDiagrams = "physora.buildDiagrams"
        static let extraExplanations = "physora.extraExplanations"
        static let showAnalysis = "physora.showAnalysis"
        static let separateFormulas = "physora.separateFormulas"
        static let separateCalculations = "physora.separateCalculations"
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored let persistenceMessage: String?

    var selectedTab: AppTab = .home
    var historyFilter: HistoryFilter = .all
    var composerDraft: String = ""
    var composerFocusRequest: Int = 0
    var hasStoredAPIKey: Bool

    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: DefaultsKey.theme) }
    }

    var interfaceSize: InterfaceSize {
        didSet { defaults.set(interfaceSize.rawValue, forKey: DefaultsKey.interfaceSize) }
    }

    var modelID: String {
        didSet { defaults.set(modelID, forKey: DefaultsKey.modelID) }
    }

    var explanationDetail: ExplanationDetail {
        didSet { defaults.set(explanationDetail.rawValue, forKey: DefaultsKey.explanationDetail) }
    }

    var autoSI: Bool {
        didSet { defaults.set(autoSI, forKey: DefaultsKey.autoSI) }
    }

    var buildDiagrams: Bool {
        didSet { defaults.set(buildDiagrams, forKey: DefaultsKey.buildDiagrams) }
    }

    var showExtraExplanations: Bool {
        didSet { defaults.set(showExtraExplanations, forKey: DefaultsKey.extraExplanations) }
    }

    var showAnalysis: Bool {
        didSet { defaults.set(showAnalysis, forKey: DefaultsKey.showAnalysis) }
    }

    var showSeparateFormulas: Bool {
        didSet { defaults.set(showSeparateFormulas, forKey: DefaultsKey.separateFormulas) }
    }

    var showSeparateCalculations: Bool {
        didSet { defaults.set(showSeparateCalculations, forKey: DefaultsKey.separateCalculations) }
    }

    init(defaults: UserDefaults = .standard, persistenceMessage: String? = nil) {
        self.defaults = defaults
        self.persistenceMessage = persistenceMessage
        self.theme = AppTheme(rawValue: defaults.string(forKey: DefaultsKey.theme) ?? "") ?? .system
        self.interfaceSize = InterfaceSize(
            rawValue: defaults.string(forKey: DefaultsKey.interfaceSize) ?? ""
        ) ?? .standard
        let savedModel = defaults.string(forKey: DefaultsKey.modelID) ?? AIModelInfo.deepSeekOptions[0].id
        self.modelID = AIModelInfo.deepSeekOptions.contains(where: { $0.id == savedModel })
            ? savedModel
            : AIModelInfo.deepSeekOptions[0].id
        self.explanationDetail = ExplanationDetail(
            rawValue: defaults.string(forKey: DefaultsKey.explanationDetail) ?? ""
        ) ?? .concise
        self.autoSI = defaults.object(forKey: DefaultsKey.autoSI) as? Bool ?? true
        self.buildDiagrams = defaults.object(forKey: DefaultsKey.buildDiagrams) as? Bool ?? true
        self.showExtraExplanations = defaults.object(forKey: DefaultsKey.extraExplanations) as? Bool ?? false
        self.showAnalysis = defaults.object(forKey: DefaultsKey.showAnalysis) as? Bool ?? false
        self.showSeparateFormulas = defaults.object(forKey: DefaultsKey.separateFormulas) as? Bool ?? false
        self.showSeparateCalculations = defaults.object(forKey: DefaultsKey.separateCalculations) as? Bool ?? false
        self.hasStoredAPIKey = KeychainManager.hasAPIKey()
    }

    var solutionPreferences: SolutionPreferences {
        SolutionPreferences(
            explanationDetail: explanationDetail,
            autoSI: autoSI,
            buildDiagrams: buildDiagrams,
            showExtraExplanations: showExtraExplanations,
            showAnalysis: showAnalysis,
            showSeparateFormulas: showSeparateFormulas,
            showSeparateCalculations: showSeparateCalculations
        )
    }

    var modelTitle: String {
        AIModelInfo.title(for: modelID)
    }

    func showSettings() {
        selectedTab = .settings
    }

    func prepareReSolution(prompt: String) {
        composerDraft = prompt
        composerFocusRequest += 1
        selectedTab = .home
    }

    func refreshAPIKeyStatus() {
        hasStoredAPIKey = KeychainManager.hasAPIKey()
    }
}
