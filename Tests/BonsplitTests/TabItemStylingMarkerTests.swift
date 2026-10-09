import XCTest
@testable import Bonsplit

final class TabItemStylingMarkerTests: XCTestCase {
    func testSplitsColorAndLastFocusMarkers() {
        let title = "\u{2}F3B9AF\u{2}\u{3}1790000000\u{3} golf — Scoring"
        let parsed = TabItemStyling.splitLeadingMarkers(title)
        XCTAssertNotNil(parsed.color)
        XCTAssertNil(parsed.dot)
        XCTAssertEqual(parsed.lastFocusedAt, Date(timeIntervalSince1970: 1_790_000_000))
        XCTAssertEqual(parsed.rest, "golf — Scoring")
    }

    func testColorOnlyTitleHasNoLastFocus() {
        let parsed = TabItemStyling.splitLeadingMarkers("\u{2}3AF199\u{2} plain")
        XCTAssertNotNil(parsed.color)
        XCTAssertNil(parsed.lastFocusedAt)
        XCTAssertEqual(parsed.rest, "plain")
    }

    func testLegacySplitStripsLastFocusMarker() {
        let (color, dot, rest) = TabItemStyling.splitLeadingColorDot("\u{2}3AF199\u{2}\u{3}42\u{3} shell")
        XCTAssertNotNil(color)
        XCTAssertNil(dot)
        XCTAssertEqual(rest, "shell", "the age marker must never leak into rendered titles")
    }

    func testLeadingColorHex() {
        XCTAssertEqual(TabItemStyling.leadingColorHex("\u{2}F3B9AF\u{2} x"), "F3B9AF")
        XCTAssertNil(TabItemStyling.leadingColorHex("no marker"))
        XCTAssertNil(TabItemStyling.leadingColorHex("\u{2}ZZZZZZ\u{2} bad"))
    }

    func testFocusAgeLabelBuckets() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        func label(_ ago: TimeInterval) -> String {
            TabItemStyling.focusAgeLabel(since: now.addingTimeInterval(-ago), now: now)
        }
        XCTAssertEqual(label(5), "now")
        XCTAssertEqual(label(90), "1m")
        XCTAssertEqual(label(59 * 60), "59m")
        XCTAssertEqual(label(3 * 3600 + 5), "3h")
        XCTAssertEqual(label(2 * 86_400 + 100), "2d")
    }

    func testFocusAgeFillIsLogarithmicAndEmptiesAtTwoWeeks() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        func fill(_ ago: TimeInterval) -> Double {
            TabItemStyling.focusAgeFill(since: now.addingTimeInterval(-ago), now: now)
        }
        XCTAssertEqual(fill(0), 1.0)
        XCTAssertEqual(fill(9 * 60), 1.0, "fresh for the first 10 minutes")
        XCTAssertEqual(fill(3600), 0.765, accuracy: 0.01, "about three quarters at an hour")
        XCTAssertEqual(fill(6 * 3600), 0.53, accuracy: 0.01, "about half at six hours")
        XCTAssertEqual(fill(86_400), 0.35, accuracy: 0.01, "about a third at a day")
        XCTAssertGreaterThan(fill(3 * 86_400), fill(7 * 86_400))
        XCTAssertEqual(fill(14 * 86_400), 0.0, accuracy: 0.0001, "empty at two weeks")
        XCTAssertEqual(fill(60 * 86_400), 0.0, "never negative")
    }
}
