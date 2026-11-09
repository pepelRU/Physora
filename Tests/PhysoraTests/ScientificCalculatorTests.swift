import XCTest
@testable import Physora

final class ScientificCalculatorTests: XCTestCase {
    func testArithmeticPrecedence() throws {
        let calculator = ScientificCalculator(angleMode: .radians)
        XCTAssertEqual(try calculator.evaluate("2 + 3 * 4"), 14, accuracy: 1e-12)
        XCTAssertEqual(try calculator.evaluate("(2 + 3) * 4"), 20, accuracy: 1e-12)
        XCTAssertEqual(try calculator.evaluate("2^3^2"), 512, accuracy: 1e-9)
        XCTAssertEqual(try calculator.evaluate("-2^2"), -4, accuracy: 1e-12)
    }

    func testScientificNotationAndImplicitMultiplication() throws {
        let calculator = ScientificCalculator(angleMode: .radians)
        XCTAssertEqual(try calculator.evaluate("1.5e3"), 1_500, accuracy: 1e-9)
        XCTAssertEqual(try calculator.evaluate("2π"), 2 * Double.pi, accuracy: 1e-12)
        XCTAssertEqual(try calculator.evaluate("2(3 + 4)"), 14, accuracy: 1e-12)
        XCTAssertEqual(try calculator.evaluate("2,5 * 4"), 10, accuracy: 1e-12)
    }

    func testTrigonometryModes() throws {
        let degrees = ScientificCalculator(angleMode: .degrees)
        XCTAssertEqual(try degrees.evaluate("sin(30)"), 0.5, accuracy: 1e-12)
        XCTAssertEqual(try degrees.evaluate("cos(60)"), 0.5, accuracy: 1e-12)
        XCTAssertEqual(try degrees.evaluate("asin(0.5)"), 30, accuracy: 1e-9)

        let radians = ScientificCalculator(angleMode: .radians)
        XCTAssertEqual(try radians.evaluate("sin(pi/2)"), 1, accuracy: 1e-12)
    }

    func testRootsLogarithmsAndFactorial() throws {
        let calculator = ScientificCalculator(angleMode: .radians)
        XCTAssertEqual(try calculator.evaluate("√(9)"), 3, accuracy: 1e-12)
        XCTAssertEqual(try calculator.evaluate("log(1000)"), 3, accuracy: 1e-12)
        XCTAssertEqual(try calculator.evaluate("ln(e)"), 1, accuracy: 1e-12)
        XCTAssertEqual(try calculator.evaluate("5!"), 120, accuracy: 1e-12)
    }

    func testDomainErrorsAreReported() {
        let calculator = ScientificCalculator(angleMode: .radians)
        XCTAssertThrowsError(try calculator.evaluate("1/0")) { error in
            XCTAssertEqual(error as? CalculatorError, .divisionByZero)
        }
        XCTAssertThrowsError(try calculator.evaluate("sqrt(-4)")) { error in
            guard let calculatorError = error as? CalculatorError,
                  case .domainError = calculatorError else {
                return XCTFail("Expected domain error, got \(error)")
            }
        }
        XCTAssertThrowsError(try calculator.evaluate("(-2)!"))
        XCTAssertThrowsError(try calculator.evaluate("(2+3"))
        XCTAssertThrowsError(try calculator.evaluate("unknown(2)"))
    }
}
