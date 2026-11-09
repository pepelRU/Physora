import SwiftUI

extension PhysicsCategory {
    var tint: Color {
        switch self {
        case .mechanics: .physoraAccent
        case .molecular: .physoraMint
        case .thermodynamics: .physoraAmber
        case .electrodynamics: Color(red: 0.62, green: 0.48, blue: 0.98)
        case .optics: Color(red: 0.25, green: 0.80, blue: 0.88)
        case .oscillations: Color(red: 0.96, green: 0.48, blue: 0.60)
        case .quantum: Color(red: 0.52, green: 0.68, blue: 1.0)
        }
    }
}

struct ReferenceView: View {
    @State private var searchText = ""

    private var searchResults: [PhysicsFormula] {
        FormulaDatabase.search(searchText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PhysoraBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        referenceHeader
                        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            categoryGrid
                            offlineNote
                        } else {
                            searchSection
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Справочник")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Формула, величина или тема")
            .navigationDestination(for: PhysicsCategory.self) { category in
                FormulaCategoryView(category: category)
            }
            .navigationDestination(for: PhysicsFormula.self) { formula in
                FormulaDetailView(formula: formula)
            }
        }
    }

    private var referenceHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Школьная физика\nбез лишнего поиска")
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(PhysicsCategory.allCases.count) разделов · \(FormulaDatabase.count) формул с примерами.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                IconBadge(systemImage: "books.vertical.fill", tint: .physoraAccent, size: 48)
            }
            CapsuleTag(
                text: "Работает офлайн",
                systemImage: "checkmark.icloud",
                tint: .physoraMint
            )
            .padding(.top, 2)
        }
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhysoraSectionHeader("Разделы", systemImage: "square.grid.2x2")
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 156), spacing: 12)],
                spacing: 12
            ) {
                ForEach(PhysicsCategory.allCases) { category in
                    NavigationLink(value: category) {
                        CategoryTile(category: category)
                    }
                    .buttonStyle(PressableScaleButtonStyle())
                }
            }
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Результаты")
                    .font(.headline.weight(.bold))
                    .fontDesign(.rounded)
                Spacer()
                Text("\(searchResults.count)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.physoraSurfaceMuted, in: Capsule())
            }
            if searchResults.isEmpty {
                ContentUnavailableView(
                    "Ничего не найдено",
                    systemImage: "magnifyingglass",
                    description: Text("Попробуйте название величины, например «сила» или «сопротивление».")
                )
                .padding(.vertical, 36)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(searchResults) { formula in
                        NavigationLink(value: formula) {
                            FormulaSearchRow(formula: formula)
                        }
                        .buttonStyle(PressableScaleButtonStyle())
                    }
                }
            }
        }
    }

    private var offlineNote: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "wifi.slash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.physoraMint)
                .padding(.top, 1)
            Text("Справочник, конвертер и калькулятор работают полностью локально. Для задач по-прежнему нужен интернет и ключ DeepSeek.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.physoraMint.opacity(0.07), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(Color.physoraMint.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct CategoryTile: View {
    let category: PhysicsCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(category.tint)
                    .frame(width: 38, height: 38)
                    .background(category.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            Text(category.title)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(FormulaDatabase.formulas(for: category).count) формул")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .padding(15)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }
}

struct FormulaCategoryView: View {
    let category: PhysicsCategory
    private var formulas: [PhysicsFormula] { FormulaDatabase.formulas(for: category) }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 11) {
                ForEach(formulas) { formula in
                    NavigationLink(value: formula) {
                        FormulaCategoryRow(formula: formula)
                    }
                    .buttonStyle(PressableScaleButtonStyle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background(PhysoraBackground())
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: category.systemImage)
                    .foregroundStyle(category.tint)
            }
        }
    }
}

private struct FormulaSearchRow: View {
    let formula: PhysicsFormula

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: formula.category.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(formula.category.tint)
                .frame(width: 36, height: 36)
                .background(formula.category.tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(formula.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(formula.category.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                FormulaView(formula.expression, fontSize: 18)
                    .padding(.top, 1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.quaternary)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }
}

private struct FormulaCategoryRow: View {
    let formula: PhysicsFormula

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(formula.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.quaternary)
            }
            FormulaView(formula.expression, fontSize: 21)
                .padding(.vertical, 9)
                .padding(.horizontal, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    formula.category.tint.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            Text(formula.variables)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }
}

struct FormulaDetailView: View {
    let formula: PhysicsFormula

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                formulaHero
                SolutionBlock(
                    "Обозначения",
                    systemImage: "character.book.closed",
                    copyText: formula.variables
                ) {
                    Text(formula.variables)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                SolutionBlock(
                    "Единицы измерения",
                    systemImage: "ruler",
                    accent: .physoraMint,
                    copyText: formula.units
                ) {
                    Text(formula.units)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                SolutionBlock(
                    "Смысл формулы",
                    systemImage: "lightbulb",
                    accent: .physoraAmber,
                    copyText: formula.explanation
                ) {
                    Text(formula.explanation)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                SolutionBlock(
                    "Пример",
                    systemImage: "pencil.and.scribble",
                    copyText: formula.example
                ) {
                    Text(formula.example)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(PhysoraBackground())
        .navigationTitle(formula.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var formulaHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                CapsuleTag(
                    text: formula.category.title,
                    systemImage: formula.category.systemImage,
                    tint: formula.category.tint
                )
                Spacer()
                FormulaCopyButton("\(formula.name): \(SolutionTextFormatter.formula(formula.expression))")
            }
            FormulaView(formula.expression, fontSize: 32, centersWhenFits: true)
                .padding(.vertical, 8)
            Divider().overlay(Color.physoraSeparator)
            Text(formula.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    formula.category.tint.opacity(0.14),
                    formula.category.tint.opacity(0.045)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(formula.category.tint.opacity(0.20), lineWidth: 1)
        )
    }
}
