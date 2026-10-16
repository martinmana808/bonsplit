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

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso)!
    }

    func testDayBoundariesCrossAtFiveInTheMorning() {
        let calendar = utc
        func days(_ from: String, _ to: String) -> Int {
            TabItemStyling.dayBoundariesCrossed(since: date(from), now: date(to), calendar: calendar)
        }
        XCTAssertEqual(days("2026-10-15T03:00:00Z", "2026-10-15T04:59:00Z"), 0, "03:00 and 04:59 share a day")
        XCTAssertEqual(days("2026-10-15T03:00:00Z", "2026-10-15T14:00:00Z"), 1, "05:00 passed: one day less")
        XCTAssertEqual(days("2026-10-15T06:00:00Z", "2026-10-16T04:00:00Z"), 0, "late night still counts as today")
        XCTAssertEqual(days("2026-10-15T06:00:00Z", "2026-10-16T05:00:00Z"), 1)
        XCTAssertEqual(days("2026-10-01T12:00:00Z", "2026-10-15T12:00:00Z"), 14)
        XCTAssertEqual(days("2026-10-15T12:00:00Z", "2026-10-15T11:00:00Z"), 0, "never negative")
    }

    func testFocusAgeFillStepsPerDayAndEmptiesAtThirtyDays() {
        XCTAssertEqual(TabItemStyling.focusAgeFill(daysCrossed: 0), 1.0, "acted today: full")
        XCTAssertEqual(TabItemStyling.focusAgeFill(daysCrossed: 1), 0.80, accuracy: 0.01)
        XCTAssertEqual(TabItemStyling.focusAgeFill(daysCrossed: 6), 0.43, accuracy: 0.01)
        XCTAssertEqual(TabItemStyling.focusAgeFill(daysCrossed: 13), 0.23, accuracy: 0.01)
        XCTAssertEqual(TabItemStyling.focusAgeFill(daysCrossed: 20), 0.11, accuracy: 0.01)
        XCTAssertEqual(TabItemStyling.focusAgeFill(daysCrossed: 30), 0.0, accuracy: 0.0001, "empty at thirty days")
        XCTAssertEqual(TabItemStyling.focusAgeFill(daysCrossed: 90), 0.0, "never negative")
    }

    func testFocusAgeFillDoesNotMoveInsideADay() {
        let calendar = utc
        let morning = date("2026-10-15T06:00:00Z")
        XCTAssertEqual(
            TabItemStyling.focusAgeFill(since: morning, now: date("2026-10-15T06:01:00Z"), calendar: calendar),
            TabItemStyling.focusAgeFill(since: morning, now: date("2026-10-16T04:59:00Z"), calendar: calendar)
        )
        XCTAssertLessThan(
            TabItemStyling.focusAgeFill(since: morning, now: date("2026-10-16T05:01:00Z"), calendar: calendar),
            1.0
        )
    }

    func testFocusAgeTooltipNamesTheDate() {
        let calendar = utc
        let now = date("2026-10-15T12:00:00Z")
        XCTAssertEqual(TabItemStyling.focusAgeTooltip(lastFocusedAt: nil, now: now, calendar: calendar), "No action recorded in this pane")
        XCTAssertTrue(TabItemStyling.focusAgeTooltip(lastFocusedAt: date("2026-10-15T06:00:00Z"), now: now, calendar: calendar).hasSuffix("(today)"))
        XCTAssertTrue(TabItemStyling.focusAgeTooltip(lastFocusedAt: date("2026-10-14T06:00:00Z"), now: now, calendar: calendar).hasSuffix("(1 day ago)"))
        XCTAssertTrue(TabItemStyling.focusAgeTooltip(lastFocusedAt: date("2026-09-26T06:00:00Z"), now: now, calendar: calendar).hasSuffix("(19 days ago)"))
    }
}
