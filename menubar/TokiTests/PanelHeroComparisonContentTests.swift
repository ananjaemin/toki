import XCTest
@testable import Toki

final class PanelHeroComparisonContentTests: XCTestCase {
    func test_noUsageYesterdayUsesTextOnlyNeutralState() throws {
        let content = try XCTUnwrap(PanelHeroComparisonContent.make(
            currentTotal: 120,
            previousTotal: 0,
            reference: .yesterday))

        XCTAssertNil(content.symbolName)
        XCTAssertEqual(content.text, "No usage yesterday")
    }

    func test_equalTotalsUsesNeutralMinusState() throws {
        let content = try XCTUnwrap(PanelHeroComparisonContent.make(
            currentTotal: 120,
            previousTotal: 120,
            reference: .yesterday))

        XCTAssertEqual(content.symbolName, Optional("minus"))
        XCTAssertEqual(content.text, "0% from yesterday")
    }

    func test_increasedAndDecreasedTotalsUseDirectionalStates() throws {
        let increased = try XCTUnwrap(PanelHeroComparisonContent.make(
            currentTotal: 150,
            previousTotal: 100,
            reference: .yesterday))
        let decreased = try XCTUnwrap(PanelHeroComparisonContent.make(
            currentTotal: 50,
            previousTotal: 100,
            reference: .yesterday))

        XCTAssertEqual(increased.symbolName, Optional("arrow.up"))
        XCTAssertEqual(increased.text, "50% from yesterday")
        XCTAssertEqual(decreased.symbolName, Optional("arrow.down"))
        XCTAssertEqual(decreased.text, "50% from yesterday")
    }

    func test_rollingComparisonUsesPrevious24HourCopy() throws {
        let content = try XCTUnwrap(PanelHeroComparisonContent.make(
            currentTotal: 120,
            previousTotal: 0,
            reference: .previous24Hours))

        XCTAssertNil(content.symbolName)
        XCTAssertEqual(content.text, "No usage in previous 24h")
    }
}
