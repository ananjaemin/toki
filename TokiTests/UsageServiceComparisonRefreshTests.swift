import XCTest
@testable import Toki

final class UsageServiceComparisonRefreshTests: XCTestCase {
    func test_usageService_yesterdayComparisonUsesLightweightTotalTokenPath() async throws {
        let suiteName = "UsageServiceComparisonRefreshTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let recorder = LightweightUsageRecorder()
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let reader = LightweightComparisonReader(
            today: today,
            yesterday: yesterday,
            recorder: recorder)

        let service = await MainActor.run {
            UsageService(
                readers: [reader],
                settings: UsagePanelSettings(
                    defaults: UserDefaults(suiteName: suiteName)!,
                    readerNames: ["Mock"]),
                comparisonDebounce: .zero)
        }
        await service.refresh()

        var snapshot = await recorder.snapshot()
        var yesterdayTotal = await MainActor.run { service.yesterdayTotalTokens }
        for _ in 0..<20 where yesterdayTotal != 77 {
            try? await Task.sleep(for: .milliseconds(10))
            snapshot = await recorder.snapshot()
            yesterdayTotal = await MainActor.run { service.yesterdayTotalTokens }
        }

        let usageData = await MainActor.run { service.usageData }
        XCTAssertEqual(usageData.totalTokens, 120)
        XCTAssertEqual(yesterdayTotal, 77)
        XCTAssertEqual(snapshot.usageStarts, [today])
        XCTAssertEqual(snapshot.totalStarts, [yesterday])
    }

    func test_usageService_preservesZeroYesterdayTotalForTodayComparison() async throws {
        let suiteName = "UsageServiceComparisonRefreshTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let recorder = MockReaderRecorder()
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let reader = MockReader(name: "Mock", recorder: recorder) { startDate, _ in
            switch startDate {
            case today:
                mockUsage(totalTokens: 120)
            case yesterday:
                mockUsage(totalTokens: 0)
            default:
                mockUsage(totalTokens: 5)
            }
        }

        let service = await MainActor.run {
            UsageService(
                readers: [reader],
                settings: UsagePanelSettings(
                    defaults: UserDefaults(suiteName: suiteName)!,
                    readerNames: ["Mock"]),
                comparisonDebounce: .zero)
        }
        await service.refresh()

        var calls = await recorder.snapshot()
        var yesterdayTotal = await MainActor.run { service.yesterdayTotalTokens }
        for _ in 0..<20 where calls.count < 2 || yesterdayTotal == nil {
            try? await Task.sleep(for: .milliseconds(10))
            calls = await recorder.snapshot()
            yesterdayTotal = await MainActor.run { service.yesterdayTotalTokens }
        }
        let shouldCompare = await MainActor.run { service.shouldCompareAgainstYesterday }
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls.first?.start, today)
        XCTAssertEqual(calls.last?.start, yesterday)
        XCTAssertEqual(yesterdayTotal, 0)
        XCTAssertTrue(shouldCompare)
    }

    func test_usageService_preservesYesterdayTotalDuringSameRangeRefresh() async throws {
        let suiteName = "UsageServiceComparisonRefreshTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let tracker = YesterdayRequestTracker()
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let reader = DelayedSecondYesterdayReader(
            today: today,
            yesterday: yesterday,
            tracker: tracker)

        let service = await MainActor.run {
            UsageService(
                readers: [reader],
                settings: UsagePanelSettings(
                    defaults: UserDefaults(suiteName: suiteName)!,
                    readerNames: ["Mock"]),
                comparisonDebounce: .zero)
        }
        await service.refresh()

        var yesterdayTotal = await MainActor.run { service.yesterdayTotalTokens }
        for _ in 0..<20 where yesterdayTotal != 1 {
            try? await Task.sleep(for: .milliseconds(10))
            yesterdayTotal = await MainActor.run { service.yesterdayTotalTokens }
        }

        let refreshTask = Task { await service.refresh() }
        var yesterdayRequestCount = await tracker.snapshot()
        for _ in 0..<20 where yesterdayRequestCount < 2 {
            try? await Task.sleep(for: .milliseconds(10))
            yesterdayRequestCount = await tracker.snapshot()
        }

        let preservedTotal = await MainActor.run { service.yesterdayTotalTokens }
        XCTAssertEqual(yesterdayRequestCount, 2)
        XCTAssertEqual(preservedTotal, 1)

        await refreshTask.value
    }

    func test_usageService_ignoresCanceledYesterdayComparisonAfterSelectionChanges() async throws {
        let recorder = MockReaderRecorder()
        let today = Calendar.current.startOfDay(for: Date())
        let pastDay = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -2, to: today))
        let reader = MockReader(
            name: "Mock",
            recorder: recorder) { startDate, _ in
                switch startDate {
                case today:
                    mockUsage(totalTokens: 120)
                case pastDay:
                    mockUsage(totalTokens: 42)
                default:
                    mockUsage(totalTokens: 5)
                }
            }

        let service = await MainActor.run {
            UsageService(readers: [reader], comparisonDebounce: .seconds(30))
        }
        await service.refresh()

        await MainActor.run { service.selectDay(pastDay) }
        try? await Task.sleep(for: .milliseconds(20))

        let calls = await recorder.snapshot()
        let yesterdayTotal = await MainActor.run { service.yesterdayTotalTokens }
        let selectedStart = await MainActor.run { service.startDate }
        XCTAssertEqual(calls.count, 1)
        XCTAssertNil(yesterdayTotal)
        XCTAssertEqual(selectedStart, pastDay)
    }

    func test_usageService_ignoresDuplicateRefreshForSameRangeDuringLoad() async throws {
        let gate = BlockingReaderGate()
        let today = Calendar.current.startOfDay(for: Date())
        let pastDay = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -3, to: today))
        let reader = BlockingMockReader(name: "Mock", gate: gate) { _, _ in
            mockUsage(totalTokens: 100)
        }

        let service = await MainActor.run { UsageService(readers: [reader]) }
        await MainActor.run { service.selectDay(pastDay) }
        let initialRefresh = Task { await service.refresh() }

        await gate.waitForFirstRequest()
        await service.refresh()
        await gate.release()
        await initialRefresh.value
        try? await Task.sleep(for: .milliseconds(20))

        let calls = await gate.requestCountSnapshot()
        let totalTokens = await MainActor.run { service.usageData.totalTokens }

        XCTAssertEqual(calls, 1)
        XCTAssertEqual(totalTokens, 100)
    }

    func test_usageService_lastSelectionWinsWhenRangeChangesRepeatedlyDuringLoad() async throws {
        let gate = BlockingReaderGate()
        let today = Calendar.current.startOfDay(for: Date())
        let firstDay = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -3, to: today))
        let secondDay = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -2, to: today))
        let reader = BlockingMockReader(name: "Mock", gate: gate) { startDate, _ in
            mockUsage(totalTokens: startDate == firstDay ? 100 : 200)
        }

        let service = await MainActor.run {
            UsageService(readers: [reader], comparisonDebounce: .zero)
        }
        await MainActor.run { service.selectDay(firstDay) }
        let initialRefresh = Task { await service.refresh() }

        await gate.waitForFirstRequest()
        await MainActor.run { service.selectDay(secondDay) }
        let secondRefresh = Task { await service.refresh() }
        await gate.waitForRequestCount(2)
        await MainActor.run { service.selectDay(firstDay) }
        let finalRefresh = Task { await service.refresh() }
        await gate.waitForRequestCount(3)
        await gate.release()
        await initialRefresh.value
        await secondRefresh.value
        await finalRefresh.value
        try? await Task.sleep(for: .milliseconds(20))

        let calls = await gate.requestCountSnapshot()
        let totalTokens = await MainActor.run { service.usageData.totalTokens }
        let selectedStart = await MainActor.run { service.startDate }

        XCTAssertEqual(calls, 3)
        XCTAssertEqual(totalTokens, 100)
        XCTAssertEqual(selectedStart, firstDay)
    }
}
