import SwiftUI

struct AboutPhysoraView: View {
    private var version: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(value) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                InfoCard(title: "Зачем существует Physora", systemImage: "lightbulb") {
                    Text("Physora решает школьные задачи по физике и оформляет их как аккуратную запись в тетради: «Дано», «Найти», «СИ», формулы, пошаговое решение, чертёж и ответ. Приложение не прячет физику за одним числом — оно показывает ход мысли.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                InfoCard(title: "Что внутри", systemImage: "square.grid.2x2") {
                    VStack(alignment: .leading, spacing: 12) {
                        AboutFeature(icon: "sparkles", title: "AI-решатель", text: "DeepSeek анализирует условие и возвращает структурированное решение.")
                        AboutFeature(icon: "scribble.variable", title: "Настоящие схемы", text: "Чертежи и графики строятся кодом приложения из примитивов и данных, а не вставляются картинкой из интернета.")
                        AboutFeature(icon: "clock.arrow.circlepath", title: "Личная библиотека", text: "История и избранное хранятся локально в SwiftData и доступны без сети.")
                        AboutFeature(icon: "books.vertical", title: "Справочник и инструменты", text: "Формулы, конвертер единиц и научный калькулятор работают офлайн.")
                    }
                }
                InfoCard(title: "Важно помнить", systemImage: "exclamationmark.shield", accent: .physoraAmber) {
                    Text("Physora — учебный инструмент, а не замена учителю. AI может ошибаться в физике, единицах или трактовке условия. Решение проверяется приложением только на структурную целостность JSON и оформления. Всегда сверяйте вычисления и размерности.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(spacing: 4) {
                    Text("Physora · \(version)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Link("github.com/pepelRU/Physora", destination: URL(string: "https://github.com/pepelRU/Physora")!)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.physoraAccent)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(PhysoraBackground())
        .navigationTitle("О Physora")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            BrandTile(size: 82)
            VStack(spacing: 4) {
                Text("Physora")
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                Text("ФИЗИКА · ЯСНО")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2.6)
                    .foregroundStyle(Color.physoraAccent)
            }
            Text("Спокойный способ разобраться\nв задаче по физике")
                .font(.headline.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            Color.physoraSurface,
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }
}

private struct AboutFeature: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.physoraAccent)
                .frame(width: 28, height: 28)
                .background(Color.physoraAccent.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TechnologiesView: View {
    private let items: [(icon: String, title: String, detail: String)] = [
        ("swift", "Swift 6", "Строгая конкурентность, современный синтаксис и нативные типы."),
        ("paintbrush", "SwiftUI + iOS 26", "Декларативный интерфейс, Liquid Glass в навигационном слое, семантическая типографика и Dynamic Type."),
        ("cylinder.split.1x2", "SwiftData", "Локальная история и избранное с сохранением между запусками."),
        ("chart.xyaxis.line", "Swift Charts", "Графики физических зависимостей с осями, подписями и легендой."),
        ("scribble", "Canvas и Core Graphics", "Программное построение чертежей, векторов, электрических цепей и оптических схем."),
        ("network", "URLSession", "HTTPS-запросы к официальному DeepSeek API, тайм-ауты, повторные попытки и понятные ошибки."),
        ("key.fill", "Apple Keychain", "API-ключ хранится вне UserDefaults и SwiftData, с защитой ThisDeviceOnly."),
        ("doc.richtext", "UIGraphicsPDFRenderer", "PDF собирается как отдельный печатный лист с типографикой, разбиением на страницы и векторным текстом."),
        ("sparkles", "DeepSeek API", "Официальный endpoint /chat/completions и /models. Модели deepseek-flash и deepseek-v4-pro."),
        ("square.stack.3d.up", "Swift Concurrency", "Сетевые операции не блокируют интерфейс, задача решения поддерживает отмену.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Только нативные технологии Apple и открытый HTTP API. Без сторонних UI-библиотек и WebView.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.physoraAccent)
                            .frame(width: 36, height: 36)
                            .background(Color.physoraAccent.opacity(0.09), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(15)
                    .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .strokeBorder(Color.physoraStroke, lineWidth: 1)
                    )
                }
                Text("Внешняя зависимость — только DeepSeek HTTP API. Модели и их возможности могут меняться на стороне провайдера.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(PhysoraBackground())
        .navigationTitle("Технологии")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Политика конфиденциальности Physora")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                Text("Обновлено 9 ноября 2026 года")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                privacyCard("Коротко") {
                    Text("Physora не создаёт аккаунт, не показывает рекламу, не использует аналитику и не передаёт историю решений разработчику. Для работы AI-решателя условие отправляется напрямую в DeepSeek с вашим API-ключом.")
                }

                privacyCard("Какие данные остаются на устройстве") {
                    VStack(alignment: .leading, spacing: 8) {
                        PrivacyPoint(text: "Условия задач, структурированные решения, даты, модель и отметки избранного хранятся в SwiftData на этом iPhone.")
                        PrivacyPoint(text: "История не синхронизируется между устройствами и не загружается на сервер Physora.")
                        PrivacyPoint(text: "PDF-файл создаётся локально. Он попадает в другое место только если вы сами выберете «Сохранить в Файлы» или отправите его через системное меню.")
                    }
                }

                privacyCard("API-ключ") {
                    VStack(alignment: .leading, spacing: 8) {
                        PrivacyPoint(text: "Ключ DeepSeek хранится в Apple Keychain с атрибутом ThisDeviceOnly и не записывается в UserDefaults, SwiftData, файлы проекта или журналы.")
                        PrivacyPoint(text: "Ключ используется только для HTTPS-запросов к api.deepseek.com и не передаётся другим лицам.")
                        PrivacyPoint(text: "Удалить ключ можно на экране «Настройки → DeepSeek». После удаления AI-решатель перестанет работать до добавления нового ключа.")
                    }
                }

                privacyCard("Сетевые запросы") {
                    VStack(alignment: .leading, spacing: 8) {
                        PrivacyPoint(text: "При решении задачи в DeepSeek отправляются ваше условие и настройки оформления. Модель возвращает решение.")
                        PrivacyPoint(text: "При проверке подключения отправляется запрос списка моделей с вашим ключом. Другие данные не добавляются.")
                        PrivacyPoint(text: "Соединение выполняется по HTTPS. Обработка данных на стороне DeepSeek регулируется политикой DeepSeek.")
                    }
                }

                privacyCard("Аналитика и реклама") {
                    Text("В Physora нет SDK аналитики, рекламных сетей, трекеров, отпечатков устройства и сторонних библиотек. Разработчик не получает автоматических отчётов о ваших задачах.")
                }

                privacyCard("Ваши действия") {
                    VStack(alignment: .leading, spacing: 8) {
                        PrivacyPoint(text: "Удалить отдельное решение или всю историю можно на экране «История».")
                        PrivacyPoint(text: "Удаление истории не затрагивает API-ключ; удаление ключа не затрагивает историю.")
                        PrivacyPoint(text: "Полное удаление данных приложения доступно через удаление приложения с устройства.")
                    }
                }

                privacyCard("Внешние ссылки") {
                    Text("Приложение открывает сайт DeepSeek для получения ключа и документации. После перехода в Safari действует политика соответствующего сайта.")
                }

                Link(destination: URL(string: "https://cdn.deepseek.com/policies/en-US/deepseek-privacy-policy.html")!) {
                    Label("Политика конфиденциальности DeepSeek", systemImage: "arrow.up.right.square")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.physoraAccent)
                }
                .padding(.horizontal, 2)

                Text("Physora — независимый образовательный проект. DeepSeek — товарный знак соответствующего правообладателя.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(PhysoraBackground())
        .navigationTitle("Конфиденциальность")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func privacyCard<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.semibold))
                .fontDesign(.rounded)
            content()
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(2.5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }
}

private struct PrivacyPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.physoraAccent.opacity(0.55))
                .frame(width: 4, height: 4)
                .padding(.top, 8)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let systemImage: String
    var accent: Color = .physoraAccent
    let content: Content

    init(
        title: String,
        systemImage: String,
        accent: Color = .physoraAccent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                    .frame(width: 28, height: 28)
                    .background(accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(title)
                    .font(.headline.weight(.semibold))
                    .fontDesign(.rounded)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
    }
}
