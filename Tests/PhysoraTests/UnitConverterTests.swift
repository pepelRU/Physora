import XCTest
@testable import Physora

final class UnitConverterTests: XCTestCase {
    func testLengthAndMassConversions() throws {
        let length = UnitCategory.length.units
        let meters = try XCTUnwrap(length.first(where: { $0.symbol == "м" }))
        let kilometers = try XCTUnwrap(length.first(where: { $0.symbol == "км" }))
        let centimeters = try XCTUnwrap(length.first(where: { $0.symbol == "см" }))
        XCTAssertEqual(try UnitConverter.convert(1, from: kilometers, to: meters), 1_000, accuracy: 1e-9)
        XCTAssertEqual(try UnitConverter.convert(2.5, from: meters, to: centimeters), 250, accuracy: 1e-9)

        let mass = UnitCategory.mass.units
        let kilograms = try XCTUnwrap(mass.first(where: { $0.symbol == "кг" }))
        let grams = try XCTUnwrap(mass.first(where: { $0.symbol == "г" }))
        XCTAssertEqual(try UnitConverter.convert(1.2, from: kilograms, to: grams), 1_200, accuracy: 1e-9)
    }

    func testSpeedPressureAndEnergy() throws {
        let speed = UnitCategory.speed.units
        let kilometersPerHour = try XCTUnwrap(speed.first(where: { $0.symbol == "км/ч" }))
        let metersPerSecond = try XCTUnwrap(speed.first(where: { $0.symbol == "м/с" }))
        XCTAssertEqual(try UnitConverter.convert(72, from: kilometersPerHour, to: metersPerSecond), 20, accuracy: 1e-9)

        let pressure = UnitCategory.pressure.units
        let atmosphere = try XCTUnwrap(pressure.first(where: { $0.symbol == "атм" }))
        let pascal = try XCTUnwrap(pressure.first(where: { $0.symbol == "Па" }))
        XCTAssertEqual(try UnitConverter.convert(1, from: atmosphere, to: pascal), 101_325, accuracy: 1e-9)

        let energy = UnitCategory.energy.units
        let kilowattHour = try XCTUnwrap(energy.first(where: { $0.symbol == "кВт·ч" }))
        let joule = try XCTUnwrap(energy.first(where: { $0.symbol == "Дж" }))
        XCTAssertEqual(try UnitConverter.convert(1, from: kilowattHour, to: joule), 3_600_000, accuracy: 1e-6)
    }

    func testTemperatureUsesAffineConversion() throws {
        let temperature = UnitCategory.temperature.units
        let celsius = try XCTUnwrap(temperature.first(where: { $0.symbol == "°C" }))
        let fahrenheit = try XCTUnwrap(temperature.first(where: { $0.symbol == "°F" }))
        let kelvin = try XCTUnwrap(temperature.first(where: { $0.symbol == "K" }))

        XCTAssertEqual(try UnitConverter.convert(0, from: celsius, to: fahrenheit), 32, accuracy: 1e-9)
        XCTAssertEqual(try UnitConverter.convert(212, from: fahrenheit, to: celsius), 100, accuracy: 1e-9)
        XCTAssertEqual(try UnitConverter.convert(273.15, from: kelvin, to: celsius), 0, accuracy: 1e-9)
        XCTAssertEqual(try UnitConverter.convert(100, from: celsius, to: kelvin), 373.15, accuracy: 1e-9)
    }

    func testEveryCategoryHasUniqueUsableUnits() {
        for category in UnitCategory.allCases {
            XCTAssertGreaterThanOrEqual(category.units.count, 2, category.title)
            XCTAssertEqual(Set(category.units.map(\.id)).count, category.units.count, category.title)
            XCTAssertTrue(category.units.allSatisfy { $0.scale != 0 })
        }
    }

    func testNumberParsing() {
        XCTAssertEqual(NumberText.parse("12,5"), 12.5)
        XCTAssertEqual(NumberText.parse(" 2e3 "), 2_000)
        XCTAssertNil(NumberText.parse("abc"))
        XCTAssertFalse(NumberText.compact(1e12).isEmpty)
    }
}
