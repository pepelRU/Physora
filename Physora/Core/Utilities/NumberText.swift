import Foundation

enum NumberText {
    static func decimal(_ value: Double, maximumFractionDigits: Int = 8) -> String {
        guard value.isFinite else { return "—" }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = max(0, maximumFractionDigits)
        formatter.roundingMode = .halfUp
        if abs(value) < 1e-12 { return "0" }
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func compact(_ value: Double, significantDigits: Int = 6) -> String {
        guard value.isFinite else { return "—" }
        let magnitude = abs(value)
        if magnitude != 0, magnitude >= 1e9 || magnitude < 1e-5 {
            let raw = String(format: "%.\(max(1, significantDigits - 1))e", value)
            let parts = raw.split(separator: "e")
            guard parts.count == 2, let exponent = Int(parts[1]) else { return raw }
            let mantissa = String(parts[0]).replacingOccurrences(of: ".", with: ",")
            return "\(mantissa) × 10\(superscript(exponent))"
        }
        return decimal(value, maximumFractionDigits: max(0, significantDigits))
    }

    static func parse(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "−", with: "-")
        guard !normalized.isEmpty else { return nil }
        return Double(normalized)
    }

    static func superscript(_ exponent: Int) -> String {
        let map: [Character: Character] = [
            "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵",
            "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻", "+": "⁺"
        ]
        return String(String(exponent).compactMap { map[$0] })
    }

    static func plainScientific(_ value: Double, digits: Int = 6) -> String {
        guard value.isFinite else { return "—" }
        var text = String(format: "%.\(digits)g", value)
        text = text.replacingOccurrences(of: ".", with: ",")
        return text
    }
}

extension Date {
    var physoraDateTime: String {
        formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .year()
                .hour()
                .minute()
                .locale(Locale(identifier: "ru_RU"))
        )
    }

    var physoraShortDate: String {
        if Calendar.current.isDateInToday(self) {
            return "Сегодня, " + formatted(
                .dateTime.hour().minute().locale(Locale(identifier: "ru_RU"))
            )
        }
        if Calendar.current.isDateInYesterday(self) {
            return "Вчера, " + formatted(
                .dateTime.hour().minute().locale(Locale(identifier: "ru_RU"))
            )
        }
        return formatted(
            .dateTime.day().month(.abbreviated).locale(Locale(identifier: "ru_RU"))
        )
    }
}
