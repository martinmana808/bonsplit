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

    func testFocusAgeOpacityFadesMonotonically() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        func opacity(_ ago: TimeInterval) -> Double {
            TabItemStyling.focusAgeOpacity(since: now.addingTimeInterval(-ago), now: now)
        }
        XCTAssertEqual(opacity(0), 1.0)
        XCTAssertEqual(opacity(9 * 60), 1.0)
        XCTAssertLessThan(opacity(3600), 1.0)
        XCTAssertGreaterThan(opacity(3600), opacity(6 * 3600))
        XCTAssertGreaterThan(opacity(6 * 3600), opacity(86_400))
        XCTAssertEqual(opacity(86_400), 0.45, accuracy: 0.001)
        XCTAssertEqual(opacity(7 * 86_400), 0.45, accuracy: 0.001, "never fades below the floor")
    }
}
