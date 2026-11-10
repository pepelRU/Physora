import Foundation
import SwiftUI

struct CalculatorView: View {
    @State private var expression = ""
    @State private var result = ""
    @State private var errorMessage: String?
    @State private var angleMode: AngleMode = .degrees
    @State private var justEvaluated = false
    @State private var lastValue: Double?
    @State private var records: [CalculationRecord] = []
    @State private var copied = false
    @FocusState private var expressionFocused: Bool

    private let keyRows: [[CalculatorKey]] = [
        [
            .function("sin", action: .insert("sin(")),
            .function("cos", action: .insert("cos(")),
            .function("tan", action: .insert("tan(")),
            .function("ln", action: .insert("ln(")),
            .function("log", action: .insert("log("))
        ],
        [
            .operation("(", action: .insert("(")),
            .operation(")", action: .insert(")")),
            .function("√", action: .insert("√")),
            .function("xʸ", action: .insert("^")),
            .function("π", action: .insert("π"))
        ],
        [
            .digit("7", action: .insert("7")),
            .digit("8", action: .insert("8")),
            .digit("9", action: .insert("9")),
            .operation("÷", action: .insert("÷")),
            .control("⌫", systemImage: "delete.left", action: .backspace)
        ],
        [
            .digit("4", action: .insert("4")),
            .digit("5", action: .insert("5")),
            .digit("6", action: .insert("6")),
            .operation("×", action: .insert("×")),
            .control("C", action: .clear)
        ],
        [
            .digit("1", action: .insert("1")),
            .digit("2", action: .insert("2")),
            .digit("3", action: .insert("3")),
            .operation("−", action: .insert("−")),
            .function("×10ⁿ", action: .insert("×10^"))
        ],
        [
            .digit("0", action: .insert("0")),
            .digit(".", action: .insert(".")),
            .function("e", action: .insert("e")),
            .operation("+", action: .insert("+")),
            .equals
        ]
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                displayCard
                keypad
                if !records.isEmpty {
                    historySection
                }
                offlineNote
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(PhysoraBackground())
        .navigationTitle("Калькулятор")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: expression) { _, _ in
            errorMessage = nil
        }
        .onChange(of: angleMode) { _, _ in
            result = ""
            justEvaluated = false
            errorMessage = nil
        }
    }

    private var displayCard: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Picker("Углы", selection: $angleMode) {
                    ForEach(AngleMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
                Spacer()
                Text("DEG / RAD")
                    .font(.caption2.weight(.semibold).monospaced())
                    .foregroundStyle(.tertiary)
            }

            HStack(alignment: .top, spacing: 8) {
                TextField("0", text: $expression, axis: .vertical)
                    .font(.system(size: 38, weight: .light, design: .rounded).monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($expressionFocused)
                    .lineLimit(1...3)
                    .minimumScaleFactor(0.5)
                    .submitLabel(.done)
                    .onSubmit { evaluate() }
                    .accessibilityLabel("Выражение")
                if !expression.isEmpty {
                    Button {
                        clearAll()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Очистить выражение")
                }
            }

            if let errorMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(errorMessage)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .font(.caption)
                .foregroundStyle(Color.physoraAmber)
            } else if !result.isEmpty {
                Divider()
                    .overlay(Color.physoraSeparator)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("=")
                        .font(.title3.weight(.medium).monospaced())
                        .foregroundStyle(.tertiary)
                    Text(result)
                        .font(.system(size: 42, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.physoraAccent)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Button {
                        guard Clipboard.copy(result) else { return }
                        withAnimation(.snappy) { copied = true }
                        Task {
                            try? await Task.sleep(for: .seconds(1.2))
                            withAnimation(.snappy) { copied = false }
                        }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(copied ? Color.physoraMint : Color.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.physoraSurfaceMuted, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Скопировать результат")
                }
            } else {
                Text("Введите выражение или используйте клавиши ниже")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(18)
        .background(
            Color.physoraSurface,
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
        .animation(.snappy(duration: 0.2), value: result)
    }

    private var keypad: some View {
        VStack(spacing: 7) {
            ForEach(Array(keyRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 7) {
                    ForEach(row) { key in
                        CalculatorKeyButton(key: key) {
                            perform(key.action)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("В этой сессии")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                Spacer()
                Button("Очистить") {
                    withAnimation { records.removeAll() }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            VStack(spacing: 0) {
                ForEach(records) { record in
                    Button {
                        expression = record.expression
                        result = record.result
                        lastValue = record.value
                        justEvaluated = true
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(record.expression)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("= \(record.result)")
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Color.physoraAccent)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if record.id != records.last?.id {
                        Divider()
                            .overlay(Color.physoraSeparator)
                    }
                }
            }
        }
        .padding(15)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }

    private var offlineNote: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(Color.physoraMint)
                .padding(.top, 1)
            Text("Вычисления выполняются локально. Углы переключаются между градусами и радианами; логарифм log — десятичный, ln — натуральный.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
    }

    private func perform(_ action: CalculatorKeyAction) {
        Haptics.light()
        switch action {
        case .insert(let token):
            insert(token)
        case .clear:
            clearAll()
        case .backspace:
            backspace()
        case .equals:
            evaluate()
        }
    }

    private func insert(_ token: String) {
        if justEvaluated {
            if isOperatorToken(token), let lastValue {
                expression = String(format: "%.15g", lastValue)
            } else {
                expression = ""
            }
            result = ""
            justEvaluated = false
        }
        if expression == "0", token.first?.isNumber == true {
            expression = ""
        }
        if expression.count < 220 {
            expression.append(token)
        }
        errorMessage = nil
    }

    private func isOperatorToken(_ token: String) -> Bool {
        let operators = ["+", "−", "×", "÷", "^", "×10^"]
        return operators.contains(token)
    }

    private func backspace() {
        guard !expression.isEmpty else { return }
        expression.removeLast()
        result = ""
        justEvaluated = false
        errorMessage = nil
    }

    private func clearAll() {
        expression = ""
        result = ""
        errorMessage = nil
        justEvaluated = false
        lastValue = nil
    }

    private func evaluate() {
        let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let calculator = ScientificCalculator(angleMode: angleMode)
            let value = try calculator.evaluate(trimmed)
            let formatted = NumberText.compact(value, significantDigits: 12)
            result = formatted
            lastValue = value
            errorMessage = nil
            justEvaluated = true
            expressionFocused = false
            withAnimation(.snappy) {
                records.insert(
                    CalculationRecord(
                        expression: trimmed,
                        result: formatted,
                        value: value
                    ),
                    at: 0
                )
                if records.count > 8 { records.removeLast(records.count - 8) }
            }
            Haptics.success()
        } catch {
            result = ""
            lastValue = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Не удалось вычислить выражение."
            justEvaluated = false
            Haptics.warning()
        }
    }
}

private struct CalculationRecord: Identifiable {
    let id = UUID()
    let expression: String
    let result: String
    let value: Double
}

private enum CalculatorKeyAction {
    case insert(String)
    case clear
    case backspace
    case equals
}

private enum CalculatorKeyKind {
    case digit
    case function
    case operation
    case control
    case equals
}

private struct CalculatorKey: Identifiable {
    let title: String
    let systemImage: String?
    let kind: CalculatorKeyKind
    let action: CalculatorKeyAction

    var id: String { title }

    static func digit(_ title: String, action: CalculatorKeyAction) -> CalculatorKey {
        CalculatorKey(title: title, systemImage: nil, kind: .digit, action: action)
    }

    static func function(_ title: String, action: CalculatorKeyAction) -> CalculatorKey {
        CalculatorKey(title: title, systemImage: nil, kind: .function, action: action)
    }

    static func operation(_ title: String, action: CalculatorKeyAction) -> CalculatorKey {
        CalculatorKey(title: title, systemImage: nil, kind: .operation, action: action)
    }

    static func control(_ title: String, systemImage: String? = nil, action: CalculatorKeyAction) -> CalculatorKey {
        CalculatorKey(title: title, systemImage: systemImage, kind: .control, action: action)
    }

    static var equals: CalculatorKey {
        CalculatorKey(title: "=", systemImage: nil, kind: .equals, action: .equals)
    }
}

private struct CalculatorKeyButton: View {
    let key: CalculatorKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let image = key.systemImage {
                    Image(systemName: image)
                        .font(.system(size: 17, weight: .semibold))
                } else {
                    Text(key.title)
                        .font(font)
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(border, lineWidth: key.kind == .equals ? 0 : 0.7)
            )
        }
        .buttonStyle(PressableScaleButtonStyle())
        .accessibilityLabel(accessibilityTitle)
    }

    private var font: Font {
        switch key.kind {
        case .digit:
            .system(size: 21, weight: .regular, design: .rounded).monospacedDigit()
        case .function:
            .system(size: 14, weight: .semibold, design: .rounded)
        case .operation:
            .system(size: 21, weight: .medium, design: .rounded)
        case .control:
            .system(size: 16, weight: .semibold, design: .rounded)
        case .equals:
            .system(size: 23, weight: .bold, design: .rounded)
        }
    }

    private var foreground: Color {
        switch key.kind {
        case .function:
            Color.physoraAccent
        case .control:
            Color.secondary
        case .equals:
            Color.white
        default:
            Color.primary
        }
    }

    private var background: Color {
        switch key.kind {
        case .digit:
            Color.physoraSurfaceMuted.opacity(0.8)
        case .function:
            Color.physoraAccent.opacity(0.09)
        case .operation:
            Color.physoraSurfaceMuted
        case .control:
            Color.physoraSurfaceMuted.opacity(0.7)
        case .equals:
            Color.physoraAccent
        }
    }

    private var border: Color {
        key.kind == .equals ? .clear : Color.physoraStroke
    }

    private var accessibilityTitle: String {
        switch key.title {
        case "×": "Умножить"
        case "÷": "Разделить"
        case "−": "Минус"
        case "+": "Плюс"
        case "√": "Квадратный корень"
        case "×10ⁿ": "Умножить на десять в степени"
        case "⌫": "Удалить символ"
        case "C": "Очистить"
        case "=": "Вычислить"
        default: key.title
        }
    }
}
