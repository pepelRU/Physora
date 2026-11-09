import SwiftUI

struct TaskComposerView: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let isAIConnected: Bool
    let onOpenSettings: () -> Void
    let onSolve: () -> Void

    private let characterLimit = 4_000

    private let examples: [(title: String, prompt: String)] = [
        (
            "Второй закон Ньютона",
            "Тело массой 2 кг движется с ускорением 3 м/с². Найдите равнодействующую силу."
        ),
        (
            "Кинетическая энергия",
            "Автомобиль массой 1,2 т движется со скоростью 72 км/ч. Найдите его кинетическую энергию."
        ),
        (
            "Наклонная плоскость",
            "Брусок массой 4 кг находится на наклонной плоскости с углом 30°. Коэффициент трения 0,2. Найдите ускорение бруска."
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                IconBadge(systemImage: "sparkles", tint: .physoraAccent, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Новая задача")
                        .font(.headline.weight(.bold))
                        .fontDesign(.rounded)
                    Text("Опишите условие")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button {
                    onOpenSettings()
                } label: {
                    CapsuleTag(
                        text: isAIConnected ? "DeepSeek" : "Подключить",
                        systemImage: isAIConnected ? "brain.head.profile" : "key.fill",
                        tint: isAIConnected ? .physoraAccent : .physoraAmber
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isAIConnected ? "Настроить DeepSeek" : "Подключить DeepSeek")
            }

            editor

            examplesRow

            Button(action: onSolve) {
                HStack(spacing: 9) {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.bold))
                    Text("Решить задачу")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .opacity(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            .buttonStyle(.glassProminent)
            .tint(.physoraAccent)
            .controlSize(.large)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityHint("Отправляет условие в DeepSeek и открывает оформленное решение")
        }
        .physoraCard(padding: 18, cornerRadius: 26, elevated: true)
        .onChange(of: text) { _, newValue in
            if newValue.count > characterLimit {
                text = String(newValue.prefix(characterLimit))
            }
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Например: камень брошен под углом 30° к горизонту со скоростью 15 м/с. Найдите дальность полёта…")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 16)
                    .padding(.trailing, 22)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .font(.body)
                .lineSpacing(3)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .textInputAutocapitalization(.sentences)
                .padding(11)
                .padding(.bottom, 12)
                .frame(minHeight: 132, maxHeight: 196)
                .background(Color.physoraSurfaceMuted.opacity(0.62), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if !text.isEmpty {
                        Button {
                            text = ""
                            isFocused = true
                            Haptics.light()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(10)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Очистить условие задачи")
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Text(verbatim: "\(text.count) / \(characterLimit)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(text.count > characterLimit ? Color.red : Color.secondary.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                        .allowsHitTesting(false)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .strokeBorder(
                            isFocused ? Color.physoraAccent.opacity(0.52) : Color.physoraStroke,
                            lineWidth: isFocused ? 1.5 : 1
                        )
                )
                .animation(.snappy(duration: 0.2), value: isFocused)
                .accessibilityLabel("Условие задачи")
        }
    }

    private var examplesRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Text("Примеры")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 2)
                ForEach(Array(examples.enumerated()), id: \.offset) { _, example in
                    Button {
                        text = example.prompt
                        isFocused = true
                        Haptics.light()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.left")
                                .font(.caption2.weight(.bold))
                            Text(example.title)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color.physoraAccent)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Color.physoraAccent.opacity(0.09), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.physoraAccent.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(PressableScaleButtonStyle())
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}
