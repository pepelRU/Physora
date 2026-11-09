import Foundation

enum AngleMode: String, CaseIterable, Identifiable, Sendable {
    case degrees
    case radians

    var id: String { rawValue }

    var title: String {
        switch self {
        case .degrees: "Градусы"
        case .radians: "Радианы"
        }
    }
}

enum CalculatorError: LocalizedError, Sendable, Equatable {
    case emptyExpression
    case unexpectedCharacter(Character, Int)
    case invalidNumber
    case unexpectedToken(String)
    case missingClosingParenthesis
    case expectedParenthesis(String)
    case unknownIdentifier(String)
    case divisionByZero
    case domainError(String)
    case factorial(String)
    case resultNotFinite

    var errorDescription: String? {
        switch self {
        case .emptyExpression:
            "Введите выражение."
        case .unexpectedCharacter(let character, let position):
            "Недопустимый символ «\(character)» (позиция \(position))."
        case .invalidNumber:
            "Не удалось прочитать число."
        case .unexpectedToken(let token):
            "Неожиданный элемент «\(token)»."
        case .missingClosingParenthesis:
            "Не закрыта скобка."
        case .expectedParenthesis(let function):
            "После функции \(function) нужна скобка."
        case .unknownIdentifier(let name):
            "Неизвестная функция или константа «\(name)»."
        case .divisionByZero:
            "Деление на ноль невозможно."
        case .domainError(let message):
            message
        case .factorial(let message):
            message
        case .resultNotFinite:
            "Результат слишком велик или не определён."
        }
    }
}

/// A small, deterministic scientific calculator. It never calls the AI or the
/// network: tokenizing, parsing and evaluation all happen on-device.
struct ScientificCalculator: Sendable {
    let angleMode: AngleMode

    init(angleMode: AngleMode = .degrees) {
        self.angleMode = angleMode
    }

    func evaluate(_ expression: String) throws -> Double {
        let normalized = Self.normalize(expression)
        guard !normalized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CalculatorError.emptyExpression
        }
        var lexer = Tokenizer(normalized)
        let tokens = try lexer.tokenize()
        var parser = ExpressionParser(tokens: tokens, angleMode: angleMode)
        let result = try parser.parse()
        guard result.isFinite else { throw CalculatorError.resultNotFinite }
        return result
    }

    static func normalize(_ expression: String) -> String {
        expression
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "π", with: "pi")
            .replacingOccurrences(of: "√", with: "sqrt")
            .replacingOccurrences(of: "²", with: "^2")
            .replacingOccurrences(of: "³", with: "^3")
            .replacingOccurrences(of: ",", with: ".")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Tokenizer

private enum MathToken: Equatable {
    case number(Double)
    case identifier(String)
    case symbol(Character)

    var display: String {
        switch self {
        case .number(let number): String(number)
        case .identifier(let name): name
        case .symbol(let symbol): String(symbol)
        }
    }
}

private struct Tokenizer {
    private let characters: [Character]
    private var index = 0

    init(_ expression: String) {
        self.characters = Array(expression)
    }

    mutating func tokenize() throws -> [MathToken] {
        var tokens: [MathToken] = []
        while index < characters.count {
            let character = characters[index]
            if character.isWhitespace {
                index += 1
                continue
            }
            if character.isNumber || character == "." {
                tokens.append(try readNumber())
                continue
            }
            if character.isLetter {
                let start = index
                while index < characters.count, characters[index].isLetter {
                    index += 1
                }
                tokens.append(.identifier(String(characters[start..<index])))
                continue
            }
            let symbols: Set<Character> = ["+", "-", "*", "/", "^", "(", ")", "!", "%"]
            if symbols.contains(character) {
                tokens.append(.symbol(character))
                index += 1
                continue
            }
            throw CalculatorError.unexpectedCharacter(character, index + 1)
        }
        return tokens
    }

    private mutating func readNumber() throws -> MathToken {
        let start = index
        var hasDigits = false

        while index < characters.count, characters[index].isNumber {
            hasDigits = true
            index += 1
        }
        if index < characters.count, characters[index] == "." {
            index += 1
            while index < characters.count, characters[index].isNumber {
                hasDigits = true
                index += 1
            }
        }
        guard hasDigits else { throw CalculatorError.invalidNumber }

        if index < characters.count, characters[index] == "e" {
            let exponentStart = index
            var cursor = index + 1
            if cursor < characters.count, characters[cursor] == "+" || characters[cursor] == "-" {
                cursor += 1
            }
            let digitStart = cursor
            while cursor < characters.count, characters[cursor].isNumber {
                cursor += 1
            }
            if cursor > digitStart {
                index = cursor
            } else {
                index = exponentStart
            }
        }

        let raw = String(characters[start..<index])
        guard let value = Double(raw), value.isFinite else {
            throw CalculatorError.invalidNumber
        }
        return .number(value)
    }
}

// MARK: - Recursive descent parser

private struct ExpressionParser {
    let tokens: [MathToken]
    var index = 0
    let angleMode: AngleMode

    mutating func parse() throws -> Double {
        guard !tokens.isEmpty else { throw CalculatorError.emptyExpression }
        let result = try parseExpression()
        if let token = peek {
            throw CalculatorError.unexpectedToken(token.display)
        }
        return try finite(result)
    }

    private var peek: MathToken? {
        index < tokens.count ? tokens[index] : nil
    }

    private mutating func match(_ symbol: Character) -> Bool {
        if case .symbol(symbol)? = peek {
            index += 1
            return true
        }
        return false
    }

    private mutating func parseExpression() throws -> Double {
        var value = try parseTerm()
        while let token = peek {
            if token == .symbol("+") {
                index += 1
                value = try finite(value + (try parseTerm()))
            } else if token == .symbol("-") {
                index += 1
                value = try finite(value - (try parseTerm()))
            } else {
                break
            }
        }
        return value
    }

    private mutating func parseTerm() throws -> Double {
        var value = try parseUnary()
        while let token = peek {
            if token == .symbol("*") {
                index += 1
                value = try finite(value * (try parseUnary()))
            } else if token == .symbol("/") {
                index += 1
                let divisor = try parseUnary()
                guard divisor != 0 else { throw CalculatorError.divisionByZero }
                value = try finite(value / divisor)
            } else if startsPrimary(token) {
                // Implicit multiplication: 2π, 3(4+5), 2sin(30°).
                value = try finite(value * (try parseUnary()))
            } else {
                break
            }
        }
        return value
    }

    private func startsPrimary(_ token: MathToken) -> Bool {
        switch token {
        case .number, .identifier:
            true
        case .symbol(let symbol):
            symbol == "("
        }
    }

    private mutating func parseUnary() throws -> Double {
        if match("+") {
            return try parseUnary()
        }
        if match("-") {
            return try finite(-(try parseUnary()))
        }
        return try parsePower()
    }

    private mutating func parsePower() throws -> Double {
        let base = try parsePostfix()
        if match("^") {
            let exponent = try parseUnary()
            let result = pow(base, exponent)
            guard result.isFinite else { throw CalculatorError.resultNotFinite }
            return result
        }
        return base
    }

    private mutating func parsePostfix() throws -> Double {
        var value = try parsePrimary()
        while let token = peek {
            if token == .symbol("!") {
                index += 1
                value = try factorial(value)
            } else if token == .symbol("%") {
                index += 1
                value = try finite(value / 100)
            } else {
                break
            }
        }
        return value
    }

    private mutating func parsePrimary() throws -> Double {
        guard let token = peek else {
            throw CalculatorError.unexpectedToken("конец выражения")
        }
        switch token {
        case .number(let number):
            index += 1
            return number
        case .symbol("("):
            index += 1
            let value = try parseExpression()
            guard match(")") else { throw CalculatorError.missingClosingParenthesis }
            return value
        case .symbol(let symbol):
            throw CalculatorError.unexpectedToken(String(symbol))
        case .identifier(let name):
            index += 1
            return try parseIdentifier(name)
        }
    }

    private mutating func parseIdentifier(_ rawName: String) throws -> Double {
        let name = rawName.lowercased()
        if name == "pi" || name == "π" {
            return Double.pi
        }
        if name == "e" {
            return M_E
        }
        if name == "ans" {
            throw CalculatorError.unknownIdentifier("ans")
        }

        guard peek == .symbol("(") else {
            if functions.contains(name) {
                throw CalculatorError.expectedParenthesis(name)
            }
            throw CalculatorError.unknownIdentifier(name)
        }
        index += 1
        let argument = try parseExpression()
        guard match(")") else { throw CalculatorError.missingClosingParenthesis }
        return try apply(function: name, argument: argument)
    }

    private var functions: Set<String> {
        [
            "sin", "cos", "tan", "asin", "acos", "atan", "log", "log10", "ln",
            "sqrt", "cbrt", "abs", "exp", "floor", "ceil", "round"
        ]
    }

    private func apply(function name: String, argument: Double) throws -> Double {
        switch name {
        case "sin":
            return try finite(sin(angleToRadians(argument)))
        case "cos":
            return try finite(cos(angleToRadians(argument)))
        case "tan":
            let result = tan(angleToRadians(argument))
            guard result.isFinite, abs(result) < 1e15 else {
                throw CalculatorError.domainError("Тангенс не определён при этом угле.")
            }
            return result
        case "asin":
            guard (-1...1).contains(argument) else {
                throw CalculatorError.domainError("Арксинус определён только для значений от −1 до 1.")
            }
            return try finite(radiansToAngle(asin(argument)))
        case "acos":
            guard (-1...1).contains(argument) else {
                throw CalculatorError.domainError("Арккосинус определён только для значений от −1 до 1.")
            }
            return try finite(radiansToAngle(acos(argument)))
        case "atan":
            return try finite(radiansToAngle(atan(argument)))
        case "log", "log10":
            guard argument > 0 else {
                throw CalculatorError.domainError("Логарифм определён только для положительных чисел.")
            }
            return try finite(log10(argument))
        case "ln":
            guard argument > 0 else {
                throw CalculatorError.domainError("Натуральный логарифм определён только для положительных чисел.")
            }
            return try finite(log(argument))
        case "sqrt":
            guard argument >= 0 else {
                throw CalculatorError.domainError("Корень чётной степени из отрицательного числа не определён.")
            }
            return try finite(sqrt(argument))
        case "cbrt":
            return try finite(cbrt(argument))
        case "abs":
            return try finite(abs(argument))
        case "exp":
            return try finite(exp(argument))
        case "floor":
            return try finite(floor(argument))
        case "ceil":
            return try finite(ceil(argument))
        case "round":
            return try finite(round(argument))
        default:
            throw CalculatorError.unknownIdentifier(name)
        }
    }

    private func angleToRadians(_ value: Double) -> Double {
        angleMode == .degrees ? value * .pi / 180 : value
    }

    private func radiansToAngle(_ value: Double) -> Double {
        angleMode == .degrees ? value * 180 / .pi : value
    }

    private func factorial(_ value: Double) throws -> Double {
        guard value >= 0, value.rounded() == value else {
            throw CalculatorError.factorial("Факториал определён для целых неотрицательных чисел.")
        }
        guard value <= 170 else {
            throw CalculatorError.factorial("Факториал больше 170! слишком велик.")
        }
        var result = 1.0
        let count = Int(value)
        if count >= 2 {
            for number in 2...count {
                result *= Double(number)
            }
        }
        return result
    }

    private func finite(_ value: Double) throws -> Double {
        guard value.isFinite else { throw CalculatorError.resultNotFinite }
        return value
    }
}
