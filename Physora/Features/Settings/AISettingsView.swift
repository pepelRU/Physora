import SwiftUI

struct AISettingsView: View {
    @Environment(AppState.self) private var appState

    @State private var newKey = ""
    @State private var maskedPreview: String?
    @State private var status: AIConnectionStatus = .notChecked
    @State private var inlineError: String?
    @State private var inlineSuccess: String?
    @State private var showingDeleteConfirmation = false
    @State private var testTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                modelSection
                apiKeySection
                connectionSection
                securityNote
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(PhysoraBackground())
        .navigationTitle("DeepSeek")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            refreshStoredKey()
        }
        .onDisappear {
            testTask?.cancel()
        }
        .confirmationDialog(
            "Удалить API-ключ?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Удалить ключ", role: .destructive) {
                deleteKey()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Ключ будет удалён из Apple Keychain на этом устройстве. История решений останется.")
        }
        .onChange(of: appState.modelID) { _, _ in
            status = .notChecked
            inlineError = nil
            inlineSuccess = nil
        }
    }

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhysoraSectionHeader("Модель", subtitle: "Можно переключаться без изменения ключа", systemImage: "cpu")
            VStack(spacing: 9) {
                ForEach(AIModelInfo.deepSeekOptions) { model in
                    Button {
                        appState.modelID = model.id
                        Haptics.light()
                    } label: {
                        HStack(spacing: 13) {
                            Image(systemName: model.id == "deepseek-flash" ? "bolt.fill" : "brain.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(appState.modelID == model.id ? Color.physoraAccent : Color.secondary)
                                .frame(width: 38, height: 38)
                                .background(
                                    (appState.modelID == model.id ? Color.physoraAccent : Color.secondary).opacity(0.09),
                                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(model.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    if model.id == "deepseek-v4-pro" {
                                        Text("PRO")
                                            .font(.system(size: 7.5, weight: .bold))
                                            .tracking(0.5)
                                            .foregroundStyle(Color.physoraAccent)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.physoraAccent.opacity(0.10), in: Capsule())
                                    }
                                }
                                Text(model.id == "deepseek-flash"
                                     ? "Быстрая модель для большинства школьных задач."
                                     : "Усиленная модель для сложных и многошаговых задач.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(model.id)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer(minLength: 4)
                            Image(systemName: appState.modelID == model.id ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(appState.modelID == model.id ? Color.physoraAccent : Color.secondary.opacity(0.45))
                        }
                        .padding(14)
                        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 19, style: .continuous)
                                .strokeBorder(
                                    appState.modelID == model.id ? Color.physoraAccent.opacity(0.38) : Color.physoraStroke,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(PressableScaleButtonStyle())
                    .disabled(isTesting)
                }
            }
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhysoraSectionHeader(
                "API-ключ",
                subtitle: "Хранится в Apple Keychain",
                systemImage: "key.fill"
            )
            VStack(alignment: .leading, spacing: 13) {
                if let maskedPreview {
                    HStack(spacing: 9) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.physoraMint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ключ сохранён")
                                .font(.subheadline.weight(.medium))
                            Text(maskedPreview)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.physoraMint.opacity(0.07), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                } else {
                    HStack(spacing: 9) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.physoraAmber)
                        Text("Добавьте ключ DeepSeek, чтобы решать задачи.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.physoraAmber.opacity(0.07), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }

                SecureField(maskedPreview == nil ? "sk-…" : "Новый ключ для замены", text: $newKey)
                    .font(.body.monospaced())
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .padding(13)
                    .background(Color.physoraSurfaceMuted, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.physoraStroke, lineWidth: 1)
                    )

                Button {
                    saveKey()
                } label: {
                    HStack {
                        Image(systemName: "key.fill")
                        Text(newKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                             ? "Вставьте API-ключ"
                             : "Сохранить ключ")
                        Spacer()
                        Image(systemName: "arrow.down.to.line")
                            .opacity(0.65)
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                }
                .buttonStyle(.glassProminent)
                .tint(.physoraAccent)
                .controlSize(.large)
                .disabled(newKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)

                HStack(spacing: 12) {
                    Link(destination: URL(string: "https://platform.deepseek.com/api_keys")!) {
                        Label("Получить ключ", systemImage: "arrow.up.right.square")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.physoraAccent)

                    if maskedPreview != nil {
                        Spacer()
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Удалить", systemImage: "trash")
                                .font(.caption.weight(.semibold))
                        }
                        .disabled(isTesting)
                    }
                }

                if let inlineError {
                    callout(inlineError, color: .physoraAmber, systemImage: "exclamationmark.circle.fill")
                }
                if let inlineSuccess {
                    callout(inlineSuccess, color: .physoraMint, systemImage: "checkmark.circle.fill")
                }
            }
            .padding(16)
            .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
            )
        }
    }

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhysoraSectionHeader("Подключение", systemImage: "network")
            VStack(alignment: .leading, spacing: 14) {
                connectionStatusView

                Button {
                    testConnection()
                } label: {
                    HStack(spacing: 8) {
                        if isTesting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(Color.physoraAccent)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text(isTesting ? "Проверяем…" : "Проверить подключение")
                        Spacer()
                        if !isTesting {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .opacity(0.6)
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 4)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .disabled(!appState.hasStoredAPIKey || isTesting)

                Text("Проверка отправляет запрос к api.deepseek.com/models и убеждается, что выбранная модель доступна ключу. Ключ передаётся только DeepSeek по HTTPS.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var connectionStatusView: some View {
        switch status {
        case .notChecked:
            statusRow(
                color: appState.hasStoredAPIKey ? Color.physoraAmber : Color.secondary,
                title: appState.hasStoredAPIKey ? "Подключение не проверено" : "Ключ не добавлен",
                detail: appState.hasStoredAPIKey
                    ? "Нажмите «Проверить подключение», чтобы протестировать ключ и модель."
                    : "Сначала сохраните API-ключ."
            )
        case .testing:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.physoraAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Проверяем подключение")
                        .font(.subheadline.weight(.semibold))
                    Text("Запрос к DeepSeek · \(appState.modelTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        case .success(let check):
            statusRow(
                color: Color.physoraMint,
                title: "Подключение работает",
                detail: "\(Int(check.latency * 1_000)) мс · доступно моделей: \(check.models.count)"
            )
        case .failure(let message):
            statusRow(
                color: Color(red: 0.96, green: 0.34, blue: 0.36),
                title: "Не удалось подключиться",
                detail: message
            )
        }
    }

    private func statusRow(color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
                .shadow(color: color.opacity(0.4), radius: 4)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var securityNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(Color.physoraMint)
                    .padding(.top, 1)
                Text("Ключ не сохраняется в UserDefaults, SwiftData, исходном коде или логах. Он хранится в Keychain с доступом ThisDeviceOnly и не синхронизируется через iCloud.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Link(destination: URL(string: "https://api-docs.deepseek.com/")!) {
                Label("Документация DeepSeek API", systemImage: "doc.text")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.physoraAccent)
            }
        }
        .padding(15)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }

    private func callout(_ text: String, color: Color, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(color)
                .padding(.top, 1)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var isTesting: Bool {
        if case .testing = status { return true }
        return false
    }

    private func refreshStoredKey() {
        maskedPreview = KeychainManager.maskedKeyPreview()
        if maskedPreview == nil {
            status = .notChecked
        }
        appState.refreshAPIKeyStatus()
    }

    private func saveKey() {
        let trimmed = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            inlineError = "Введите API-ключ DeepSeek."
            return
        }
        do {
            try KeychainManager.saveAPIKey(trimmed)
            newKey = ""
            inlineError = nil
            inlineSuccess = "Ключ сохранён в Keychain. Теперь проверьте подключение."
            status = .notChecked
            refreshStoredKey()
            Haptics.success()
        } catch {
            inlineError = error.localizedDescription
            inlineSuccess = nil
            Haptics.warning()
        }
    }

    private func deleteKey() {
        testTask?.cancel()
        do {
            try KeychainManager.deleteAPIKey()
            newKey = ""
            maskedPreview = nil
            status = .notChecked
            inlineError = nil
            inlineSuccess = "Ключ удалён с этого устройства."
            appState.refreshAPIKeyStatus()
            Haptics.success()
        } catch {
            inlineError = error.localizedDescription
            inlineSuccess = nil
            Haptics.warning()
        }
    }

    private func testConnection() {
        guard let key = try? KeychainManager.readAPIKey(), let key else {
            status = .failure("Сначала сохраните API-ключ DeepSeek.")
            return
        }
        inlineError = nil
        inlineSuccess = nil
        status = .testing
        let modelID = appState.modelID
        testTask?.cancel()
        testTask = Task { @MainActor in
            do {
                let service = AIServiceFactory.make(provider: .deepSeek, apiKey: key, modelID: modelID)
                let check = try await service.checkConnection()
                try Task.checkCancellation()
                status = .success(check)
                Haptics.success()
            } catch is CancellationError {
                status = .notChecked
            } catch {
                status = .failure((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
                Haptics.warning()
            }
        }
    }
}

private enum AIConnectionStatus {
    case notChecked
    case testing
    case success(ConnectionCheck)
    case failure(String)
}
