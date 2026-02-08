import XCTest
@testable import MindfulBites

final class WeightUnitTests: XCTestCase {

    func testConvertFromKgToKg() {
        XCTAssertEqual(WeightUnit.kg.convert(fromKg: 70.0), 70.0)
    }

    func testConvertFromKgToLbs() {
        let result = WeightUnit.lbs.convert(fromKg: 1.0)
        XCTAssertEqual(result, 2.20462, accuracy: 0.001)
    }

    func testConvertToKgFromKg() {
        XCTAssertEqual(WeightUnit.kg.convertToKg(from: 70.0), 70.0)
    }

    func testConvertToKgFromLbs() {
        let result = WeightUnit.lbs.convertToKg(from: 2.20462)
        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }

    func testRoundTripKg() {
        let original = 85.5
        let converted = WeightUnit.kg.convert(fromKg: original)
        let backToKg = WeightUnit.kg.convertToKg(from: converted)
        XCTAssertEqual(backToKg, original, accuracy: 0.001)
    }

    func testRoundTripLbs() {
        let originalKg = 85.5
        let inLbs = WeightUnit.lbs.convert(fromKg: originalKg)
        let backToKg = WeightUnit.lbs.convertToKg(from: inLbs)
        XCTAssertEqual(backToKg, originalKg, accuracy: 0.001)
    }

    func testZeroConversion() {
        XCTAssertEqual(WeightUnit.lbs.convert(fromKg: 0.0), 0.0)
        XCTAssertEqual(WeightUnit.lbs.convertToKg(from: 0.0), 0.0)
    }

    func testDisplayName() {
        XCTAssertEqual(WeightUnit.kg.displayName, "Kilograms")
        XCTAssertEqual(WeightUnit.lbs.displayName, "Pounds")
    }

    func testAbbreviation() {
        XCTAssertEqual(WeightUnit.kg.abbreviation, "kg")
        XCTAssertEqual(WeightUnit.lbs.abbreviation, "lbs")
    }

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for unit in WeightUnit.allCases {
            let data = try encoder.encode(unit)
            let decoded = try decoder.decode(WeightUnit.self, from: data)
            XCTAssertEqual(decoded, unit)
        }
    }
}
