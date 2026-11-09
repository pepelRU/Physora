import SwiftUI

struct UnitConverterView: View {
    @State private var category: UnitCategory = .length
    @State private var input = ""
    @State private var fromUnitID = UnitCategory.length.units[0].id
    @State private var toUnitID = UnitCategory.length.units[1].id
    @State private var copied = false
    @FocusState private var inputFocused: Bool

    private var units: [UnitDefinition] { category.units }
    private var fromUnit: UnitDefinition {
        units.first(where: { $0.id == fromUnitID }) ?? units[0]
    }
    private var toUnit: UnitDefinition {
        units.first(where: { $0.id == toUnitID }) ?? units[1]
    }

    private var parsedValue: Double? {
        NumberText.parse(input)
    }

    private var conversionResult: Double? {
        guard let parsedValue else { return nil }
        return try? UnitConverter.convert(parsedValue, from: fromUnit, to: toUnit)
    }

    private var formattedResult: String {
        guard let conversionResult else { return "—" }
        return NumberText.compact(conversionResult, significantDigits: 9)
    }

    private var hasInvalidInput: Bool {
        !input.isEmpty && parsedValue == nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                categoryPicker
                inputCard
                swapButton
                resultCard
                referenceLine
                localNote
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(PhysoraBackground())
        .navigationTitle("Конвертер единиц")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: category) { _, newCategory in
            let available = newCategory.units
            fromUnitID = available[0].id
            toUnitID = available[1].id
            inputFocused = false
            withAnimation(.snappy) { copied = false }
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Величина")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                HStack(spacing: 7) {
                    ForEach(UnitCategory.allCases) { item in
                        Button {
                            withAnimation(.snappy(duration: 0.25)) {
                                category = item
                            }
                            Haptics.light()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: item.systemImage)
                                    .font(.caption2)
                                Text(item.title)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(category == item ? Color.white : Color.secondary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(
                                category == item ? Color.physoraAccent : Color.physoraSurfaceMuted,
                                in: Capsule()
                            )
                        }
                        .buttonStyle(PressableScaleButtonStyle())
                    }
                }
                .padding(.vertical, 1)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Значение")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !input.isEmpty {
                    Button {
                        input = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Очистить значение")
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                TextField("0", text: $input)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .keyboardType(.numbersAndPunctuation)
                    .focused($inputFocused)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityLabel("Исходное значение")
                unitMenu(selection: $fromUnitID, units: units, label: "Из единицы")
            }
            if hasInvalidInput {
                Text("Введите число, например 12,5 или 2e3.")
                    .font(.caption)
                    .foregroundStyle(Color.physoraAmber)
            }
        }
        .padding(18)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .strokeBorder(inputFocused ? Color.physoraAccent.opacity(0.45) : Color.physoraStroke, lineWidth: 1)
        )
    }

    private var swapButton: some View {
        HStack {
            Spacer()
            Button {
                let previousFrom = fromUnitID
                fromUnitID = toUnitID
                toUnitID = previousFrom
                Haptics.light()
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.physoraAccent)
                    .frame(width: 42, height: 42)
                    .background(Color.physoraSurface, in: Circle())
                    .overlay(Circle().strokeBorder(Color.physoraStroke, lineWidth: 1))
            }
            .buttonStyle(PressableScaleButtonStyle())
            .accessibilityLabel("Поменять единицы местами")
            Spacer()
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Результат")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.physoraMint)
                Spacer()
                if conversionResult != nil {
                    Button {
                        let text = "\(formattedResult) \(toUnit.symbol)"
                        guard Clipboard.copy(text) else { return }
                        withAnimation(.snappy) { copied = true }
                        Task {
                            try? await Task.sleep(for: .seconds(1.3))
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
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(formattedResult)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(hasInvalidInput ? Color.secondary : Color.primary)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text(toUnit.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.physoraAccent)
                Spacer(minLength: 4)
                unitMenu(selection: $toUnitID, units: units, label: "В единицу")
            }
            if category == .temperature {
                Text("Температура пересчитывается по формуле со смещением шкалы, а не простым умножением.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.physoraMint.opacity(0.13), Color.physoraAccent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .strokeBorder(Color.physoraMint.opacity(0.20), lineWidth: 1)
        )
        .animation(.snappy(duration: 0.25), value: formattedResult)
    }

    @ViewBuilder
    private var referenceLine: some View {
        if let value = try? UnitConverter.convert(1, from: fromUnit, to: toUnit) {
            HStack(spacing: 7) {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("1 \(fromUnit.symbol) = \(NumberText.compact(value, significantDigits: 6)) \(toUnit.symbol)")
                    .font(.caption)
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 3)
        }
    }

    private var localNote: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(Color.physoraMint)
                .padding(.top, 1)
            Text("Все коэффициенты встроены в приложение. Перевод выполняется мгновенно и не отправляется в DeepSeek.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
    }

    private func unitMenu(
        selection: Binding<String>,
        units: [UnitDefinition],
        label: String
    ) -> some View {
        Menu {
            ForEach(units) { unit in
                Button {
                    selection.wrappedValue = unit.id
                } label: {
                    if selection.wrappedValue == unit.id {
                        Label("\(unit.name) (\(unit.symbol))", systemImage: "checkmark")
                    } else {
                        Text("\(unit.name) (\(unit.symbol))")
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                let selected = units.first(where: { $0.id == selection.wrappedValue }) ?? units[0]
                Text(selected.symbol)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(Color.physoraAccent)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Color.physoraAccent.opacity(0.09), in: Capsule())
        }
        .accessibilityLabel(label)
    }
}
