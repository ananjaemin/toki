import Foundation

enum CurrentUsageWindow: String, CaseIterable, Codable, Identifiable {
    case calendarDay
    case rolling24Hours

    private static let rollingDuration: TimeInterval = 24 * 60 * 60

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .calendarDay:
            "Today"
        case .rolling24Hours:
            "Last 24 Hours"
        }
    }

    var compactTitle: String {
        switch self {
        case .calendarDay:
            "Since 00:00"
        case .rolling24Hours:
            "Last 24h"
        }
    }

    func dateInterval(
        at now: Date,
        calendar: Calendar = .autoupdatingCurrent) -> DateInterval {
        switch self {
        case .calendarDay:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            return DateInterval(start: start, end: end)
        case .rolling24Hours:
            return DateInterval(
                start: now.addingTimeInterval(-Self.rollingDuration),
                end: now)
        }
    }

    func previousDateInterval(
        before interval: DateInterval,
        calendar: Calendar = .autoupdatingCurrent) -> DateInterval {
        switch self {
        case .calendarDay:
            let start = calendar.date(byAdding: .day, value: -1, to: interval.start) ?? interval.start
            return DateInterval(start: start, end: interval.start)
        case .rolling24Hours:
            return DateInterval(
                start: interval.start.addingTimeInterval(-Self.rollingDuration),
                end: interval.start)
        }
    }
}
