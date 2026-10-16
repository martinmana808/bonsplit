import Foundation

/// Public face of the tab chip's age gauge so hosts can draw the same gauge
/// elsewhere (sidebar rows, menus) with identical semantics: full while no
/// 05:00 day boundary has passed since the last action, then one step down
/// per day on a log scale, empty at 30 days.
public enum BonsplitPaneAge {
    public static var dayBoundaryHour: Int { TabItemStyling.focusAgeDayBoundaryHour }
    public static var emptyDays: Int { TabItemStyling.focusAgeEmptyDays }

    public static func daysCrossed(since lastActionAt: Date, now: Date = Date(), calendar: Calendar = .current) -> Int {
        TabItemStyling.dayBoundariesCrossed(since: lastActionAt, now: now, calendar: calendar)
    }

    public static func fill(since lastActionAt: Date, now: Date = Date(), calendar: Calendar = .current) -> Double {
        TabItemStyling.focusAgeFill(since: lastActionAt, now: now, calendar: calendar)
    }

    public static func fill(daysCrossed days: Int) -> Double {
        TabItemStyling.focusAgeFill(daysCrossed: days)
    }

    public static func tooltip(lastActionAt: Date?, now: Date = Date(), calendar: Calendar = .current) -> String {
        TabItemStyling.focusAgeTooltip(lastFocusedAt: lastActionAt, now: now, calendar: calendar)
    }
}
