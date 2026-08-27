import XCTest
@testable import Toki

final class UsageServiceDateSyncBehaviorTests: XCTestCase {
    func test_usageService_ignoresWindowChangesForPastSelection() async throws {
        let service = await MainActor.run { UsageService(readers: []) }
        let pastDay = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -2, to: Date()))
        let handled = await MainActor.run { () -> Bool in
            service.selectDay(pastDay)
            return service.handleCurrentUsageWindowChange()
        }

        XCTAssertFalse(handled)
    }

    func test_currentUsageWindow_resolvesCalendarDayAndExactRollingDuration() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let now = tokiTestISODate("2026-03-08T12:00:00Z")

        let calendarDay = CurrentUsageWindow.calendarDay.dateInterval(
            at: now,
            calendar: calendar)
        let rolling = CurrentUsageWindow.rolling24Hours.dateInterval(
            at: now,
            calendar: calendar)
        let previousRolling = CurrentUsageWindow.rolling24Hours.previousDateInterval(
            before: rolling,
            calendar: calendar)

        XCTAssertEqual(calendarDay.start, calendar.startOfDay(for: now))
        XCTAssertEqual(calendarDay.duration, 23 * 60 * 60)
        XCTAssertEqual(rolling.end, now)
        XCTAssertEqual(rolling.duration, 24 * 60 * 60)
        XCTAssertEqual(previousRolling.end, rolling.start)
        XCTAssertEqual(previousRolling.duration, 24 * 60 * 60)
    }

    func test_usageService_refresh_keepsRangeModeWhenEnteringFromToday() async {
        let service = await MainActor.run { UsageService(readers: []) }
        let initialStart = await MainActor.run { service.startDate }
        let initialEnd = await MainActor.run { service.endDate }

        await MainActor.run {
            service.isRangeMode = true
        }
        await service.refresh()

        let isRangeMode = await MainActor.run { service.isRangeMode }
        let startDate = await MainActor.run { service.startDate }
        let endDate = await MainActor.run { service.endDate }

        XCTAssertTrue(isRangeMode)
        XCTAssertEqual(startDate, initialStart)
        XCTAssertEqual(endDate, initialEnd)
    }

    func test_usageService_syncSelectionWithTodayIfNeeded_advancesPinnedTodaySelection() async throws {
        let calendar = Calendar.current
        let service = await MainActor.run { UsageService(readers: []) }
        let initialToday = await MainActor.run { service.startDate }
        let nextDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: initialToday))
        let nextDayNoon = try XCTUnwrap(calendar.date(byAdding: .hour, value: 12, to: nextDay))
        let followingDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: nextDay))

        let changed = await MainActor.run {
            service.syncSelectionWithTodayIfNeeded(now: nextDayNoon)
        }

        let startDate = await MainActor.run { service.startDate }
        let endDate = await MainActor.run { service.endDate }

        XCTAssertTrue(changed)
        XCTAssertEqual(startDate, nextDay)
        XCTAssertEqual(endDate, followingDay)
    }

    func test_usageService_syncSelectionWithTodayIfNeeded_preservesManualPastSelection() async throws {
        let calendar = Calendar.current
        let service = await MainActor.run { UsageService(readers: []) }
        let initialToday = await MainActor.run { service.startDate }
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: initialToday))
        let nextDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: initialToday))
        let nextDayNoon = try XCTUnwrap(calendar.date(byAdding: .hour, value: 12, to: nextDay))
        let expectedEnd = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: yesterday))

        await MainActor.run {
            service.selectDay(yesterday)
        }

        let changed = await MainActor.run {
            service.syncSelectionWithTodayIfNeeded(now: nextDayNoon)
        }

        let startDate = await MainActor.run { service.startDate }
        let endDate = await MainActor.run { service.endDate }

        XCTAssertFalse(changed)
        XCTAssertEqual(startDate, yesterday)
        XCTAssertEqual(endDate, expectedEnd)
    }
}
