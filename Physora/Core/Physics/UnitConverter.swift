import Foundation

struct UnitDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let symbol: String
    let scale: Double
    let offset: Double

    init(_ symbol: String, name: String? = nil, scale: Double, offset: Double = 0) {
        self.id = symbol
        self.name = name ?? symbol
        self.symbol = symbol
        self.scale = scale
        self.offset = offset
    }
}

enum UnitCategory: String, CaseIterable, Identifiable, Sendable {
    case length
    case mass
    case time
    case speed
    case acceleration
    case force
    case pressure
    case energy
    case power
    case temperature
    case current
    case voltage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .length: "Длина"
        case .mass: "Масса"
        case .time: "Время"
        case .speed: "Скорость"
        case .acceleration: "Ускорение"
        case .force: "Сила"
        case .pressure: "Давление"
        case .energy: "Энергия"
        case .power: "Мощность"
        case .temperature: "Температура"
        case .current: "Сила тока"
        case .voltage: "Напряжение"
        }
    }

    var systemImage: String {
        switch self {
        case .length: "ruler"
        case .mass: "scalemass"
        case .time: "clock"
        case .speed: "gauge.with.dots.needle.67percent"
        case .acceleration: "arrow.up.right"
        case .force: "arrow.down.to.line"
        case .pressure: "circle.dotted"
        case .energy: "bolt"
        case .power: "engine.combustion"
        case .temperature: "thermometer.medium"
        case .current: "waveform.path"
        case .voltage: "bolt.batteryblock"
        }
    }

    var units: [UnitDefinition] {
        switch self {
        case .length:
            [
                UnitDefinition("м", name: "метр", scale: 1),
                UnitDefinition("см", name: "сантиметр", scale: 0.01),
                UnitDefinition("мм", name: "миллиметр", scale: 0.001),
                UnitDefinition("км", name: "километр", scale: 1_000),
                UnitDefinition("мкм", name: "микрометр", scale: 1e-6),
                UnitDefinition("нм", name: "нанометр", scale: 1e-9),
                UnitDefinition("миля", name: "миля", scale: 1_609.344),
                UnitDefinition("фут", name: "фут", scale: 0.3048),
                UnitDefinition("дюйм", name: "дюйм", scale: 0.0254),
                UnitDefinition("ярд", name: "ярд", scale: 0.9144)
            ]
        case .mass:
            [
                UnitDefinition("кг", name: "килограмм", scale: 1),
                UnitDefinition("г", name: "грамм", scale: 0.001),
                UnitDefinition("мг", name: "миллиграмм", scale: 1e-6),
                UnitDefinition("т", name: "тонна", scale: 1_000),
                UnitDefinition("фунт", name: "фунт", scale: 0.453_592_37),
                UnitDefinition("унция", name: "унция", scale: 0.028_349_523_125)
            ]
        case .time:
            [
                UnitDefinition("с", name: "секунда", scale: 1),
                UnitDefinition("мин", name: "минута", scale: 60),
                UnitDefinition("ч", name: "час", scale: 3_600),
                UnitDefinition("сут", name: "сутки", scale: 86_400),
                UnitDefinition("мс", name: "миллисекунда", scale: 0.001),
                UnitDefinition("мкс", name: "микросекунда", scale: 1e-6)
            ]
        case .speed:
            [
                UnitDefinition("м/с", name: "метр в секунду", scale: 1),
                UnitDefinition("км/ч", name: "километр в час", scale: 1 / 3.6),
                UnitDefinition("миль/ч", name: "миля в час", scale: 0.447_04),
                UnitDefinition("уз", name: "узел", scale: 0.514_444_444_444),
                UnitDefinition("см/с", name: "сантиметр в секунду", scale: 0.01)
            ]
        case .acceleration:
            [
                UnitDefinition("м/с²", name: "метр в секунду²", scale: 1),
                UnitDefinition("см/с²", name: "сантиметр в секунду²", scale: 0.01),
                UnitDefinition("км/с²", name: "километр в секунду²", scale: 1_000),
                UnitDefinition("g", name: "ускорение свободного падения", scale: 9.806_65)
            ]
        case .force:
            [
                UnitDefinition("Н", name: "ньютон", scale: 1),
                UnitDefinition("кН", name: "килоньютон", scale: 1_000),
                UnitDefinition("мН", name: "миллиньютон", scale: 0.001),
                UnitDefinition("дин", name: "дина", scale: 1e-5),
                UnitDefinition("кгс", name: "килограмм-сила", scale: 9.806_65),
                UnitDefinition("фунт-с", name: "фунт-сила", scale: 4.448_221_615_260_5)
            ]
        case .pressure:
            [
                UnitDefinition("Па", name: "паскаль", scale: 1),
                UnitDefinition("кПа", name: "килопаскаль", scale: 1_000),
                UnitDefinition("МПа", name: "мегапаскаль", scale: 1_000_000),
                UnitDefinition("бар", name: "бар", scale: 100_000),
                UnitDefinition("атм", name: "атмосфера", scale: 101_325),
                UnitDefinition("мм рт. ст.", name: "миллиметр ртутного столба", scale: 133.322_387_415),
                UnitDefinition("psi", name: "фунт на дюйм²", scale: 6_894.757_293_168)
            ]
        case .energy:
            [
                UnitDefinition("Дж", name: "джоуль", scale: 1),
                UnitDefinition("кДж", name: "килоджоуль", scale: 1_000),
                UnitDefinition("кал", name: "калория", scale: 4.184),
                UnitDefinition("ккал", name: "килокалория", scale: 4_184),
                UnitDefinition("Вт·ч", name: "ватт-час", scale: 3_600),
                UnitDefinition("кВт·ч", name: "киловатт-час", scale: 3_600_000),
                UnitDefinition("эВ", name: "электрон-вольт", scale: 1.602_176_634e-19)
            ]
        case .power:
            [
                UnitDefinition("Вт", name: "ватт", scale: 1),
                UnitDefinition("кВт", name: "киловатт", scale: 1_000),
                UnitDefinition("МВт", name: "мегаватт", scale: 1_000_000),
                UnitDefinition("л.с.", name: "метрическая лошадиная сила", scale: 735.498_75),
                UnitDefinition("кал/с", name: "калория в секунду", scale: 4.184)
            ]
        case .temperature:
            [
                UnitDefinition("°C", name: "градус Цельсия", scale: 1, offset: 273.15),
                UnitDefinition("°F", name: "градус Фаренгейта", scale: 5 / 9, offset: 255.372_222_222),
                UnitDefinition("K", name: "кельвин", scale: 1),
                UnitDefinition("°R", name: "градус Ренкина", scale: 5 / 9)
            ]
        case .current:
            [
                UnitDefinition("А", name: "ампер", scale: 1),
                UnitDefinition("мА", name: "миллиампер", scale: 0.001),
                UnitDefinition("мкА", name: "микроампер", scale: 1e-6),
                UnitDefinition("кА", name: "килоампер", scale: 1_000)
            ]
        case .voltage:
            [
                UnitDefinition("В", name: "вольт", scale: 1),
                UnitDefinition("мВ", name: "милливольт", scale: 0.001),
                UnitDefinition("мкВ", name: "микровольт", scale: 1e-6),
                UnitDefinition("кВ", name: "киловольт", scale: 1_000)
            ]
        }
    }
}

enum UnitConverter {
    static func convert(_ value: Double, from: UnitDefinition, to: UnitDefinition) throws -> Double {
        guard value.isFinite, from.scale != 0, to.scale != 0 else {
            throw ConversionError.invalidNumber
        }
        let base = value * from.scale + from.offset
        let result = (base - to.offset) / to.scale
        guard result.isFinite else { throw ConversionError.invalidNumber }
        return result
    }

    enum ConversionError: LocalizedError {
        case invalidNumber

        var errorDescription: String? {
            "Введите корректное числовое значение."
        }
    }
}
