import XCTest
@testable import Physora

final class MathParserTests: XCTestCase {
    func testFractionsPowersAndRootsAreCopiedAsUnicode() {
        XCTAssertEqual(
            MathParser.plainText("F = \\frac{mv^2}{2}"),
            "F = (mv²)/(2)"
        )
        XCTAssertEqual(MathParser.plainText("t^2"), "t²")
        XCTAssertEqual(MathParser.plainText("m_0"), "m₀")
        XCTAssertEqual(MathParser.plainText("\\sqrt{2gh}"), "√(2gh)")
        XCTAssertEqual(MathParser.plainText("\\sqrt[3]{V}"), "³√(V)")
    }

    func testGreekCommandsAndOperators() {
        XCTAssertEqual(MathParser.plainText("\\Delta p = F\\Delta t"), "Δ p = FΔ t")
        XCTAssertEqual(MathParser.plainText("v \\approx 3 \\cdot 10^8"), "v ≈ 3 · 10⁸")
        XCTAssertEqual(MathParser.plainText("\\alpha + \\beta"), "α + β")
    }

    func testRawCommandsNeverLeak() {
        let result = MathParser.plainText("\\unknown{value} + \\frac{1}{2}")
        XCTAssertFalse(result.contains("\\"))
        XCTAssertFalse(result.contains("unknown"))
        XCTAssertTrue(result.contains("value"))
    }

    func testTextCommandKeepsUnits() {
        XCTAssertEqual(MathParser.plainText("\\text{м/с}^2"), "м/с²")
        XCTAssertEqual(MathParser.plainText("F_{\\text{тр}}"), "F_(тр)")
    }

    func testParserHandlesEmptyAndBareScriptsWithoutCrashing() {
        XCTAssertEqual(MathParser.plainText(""), "")
        XCTAssertNoThrow(MathParser.parse("^2 + _"))
        XCTAssertNoThrow(MathParser.parse(String(repeating: "{", count: 100) + "x" + String(repeating: "}", count: 100)))
    }

    func testUnicodeSuperscriptsAndSubscriptsBecomeRenderedScripts() {
        XCTAssertEqual(MathParser.plainText("a = 1 м/с²"), "a = 1 м/с²")
        XCTAssertEqual(MathParser.plainText("10⁻³ кг"), "10⁻³ кг")
        XCTAssertEqual(MathParser.plainText("m₀ + x₁"), "m₀ + x₁")
        XCTAssertFalse(MathParser.plainText("a = 1 м/с²").contains("^"))
    }
}
