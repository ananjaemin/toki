import XCTest
@testable import Toki

// swiftlint:disable file_length

@MainActor
private final class UsageTestClock {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}

final class UsageServiceRefreshLifecycleTests: XCTestCase {
    func test_usageService_dateSelectionClearsPreviouslyPresentedUsage() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let firstDay = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today))
        let secondDay = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let reader = MockReader(name: "Mock", recorder: MockReaderRecorder()) { _, _ in
            mockUsage(totalTokens: 100)
        }
        let service = await MainActor.run { UsageService(readers: [reader]) }
        await MainActor.run { service.selectDay(firstDay) }
        await service.refresh()

        await MainActor.run { service.selectDay(secondDay) }

        let snapshot = await MainActor.run { service.presentationSnapshot }
        XCTAssertEqual(snapshot.combinedUsageData.totalTokens, 0)
        XCTAssertTrue(snapshot.originReports.isEmpty)
        XCTAssertNil(snapshot.lastFetchedAt)
    }

    @MainActor
    func test_usageService_overlappingRollingRefreshesCoalesce() async throws {
        let suiteName = "UsageServiceRollingWindowTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let tracker = CancellableUsageRequestTracker()
        let reader = CancellableSequencedReader(
            name: "Mock",
            blockedRequestNumber: 1,
            tracker: tracker) { _, _ in
                mockUsage(totalTokens: 100)
            }
        let clock = UsageTestClock(now: Date())
        let settings = try UsagePanelSettings(
            defaults: XCTUnwrap(UserDefaults(suiteName: suiteName)),
            readerNames: ["Mock"])
        settings.setCurrentUsageWindow(.rolling24Hours)
        let service = UsageService(
            readers: [reader],
            settings: settings,
            comparisonDebounce: .seconds(30),
            now: { clock.now })
        let initialRefresh = Task { await service.refresh() }
        await tracker.waitForRequestCount(1)

        clock.now = clock.now.addingTimeInterval(60)
        await service.refresh()

        let overlappingSnapshot = await tracker.snapshot()
        XCTAssertEqual(overlappingSnapshot.requestCount, 1)
        XCTAssertEqual(overlappingSnapshot.cancellationCount, 0)
        initialRefresh.cancel()
        await initialRefresh.value
    }

    func test_usageService_rangeModeClearsPresentedRollingWindow() async throws {
        let suiteName = "UsageServiceRollingWindowTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let reader = MockReader(name: "Mock", recorder: MockReaderRecorder()) { _, _ in
            mockUsage(totalTokens: 100)
        }
        let service = await MainActor.run {
            let settings = UsagePanelSettings(
                defaults: UserDefaults(suiteName: suiteName)!,
                readerNames: ["Mock"])
            settings.setCurrentUsageWindow(.rolling24Hours)
            return UsageService(
                readers: [reader],
                settings: settings,
                comparisonDebounce: .seconds(30))
        }
        await service.refresh()

        await MainActor.run { service.isRangeMode = true }

        let snapshot = await MainActor.run { service.presentationSnapshot }
        let presentedWindow = await MainActor.run { service.currentUsageWindowForPresentation }
        XCTAssertEqual(snapshot.combinedUsageData.totalTokens, 0)
        XCTAssertNil(presentedWindow)
        XCTAssertFalse(snapshot.isLoading)
        XCTAssertFalse(snapshot.isRefreshing)
    }

    func test_usageService_callerCancellationStopsActiveAggregation() async throws {
        let suiteName = "UsageServiceRollingWindowTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let tracker = CancellableUsageRequestTracker()
        let reader = CancellableSequencedReader(
            name: "Mock",
            blockedRequestNumber: 1,
            tracker: tracker) { _, _ in
                mockUsage(totalTokens: 100)
            }
        let service = await MainActor.run {
            UsageService(
                readers: [reader],
                settings: UsagePanelSettings(
                    defaults: UserDefaults(suiteName: suiteName)!,
                    readerNames: ["Mock"]),
                comparisonDebounce: .seconds(30))
        }
        let refreshTask = Task { await service.refresh() }
        await tracker.waitForRequestCount(1)

        refreshTask.cancel()
        await refreshTask.value

        let requestSnapshot = await tracker.snapshot()
        let usageSnapshot = await MainActor.run { service.presentationSnapshot }
        XCTAssertEqual(requestSnapshot.cancellationCount, 1)
        XCTAssertEqual(usageSnapshot.combinedUsageData.totalTokens, 0)
        XCTAssertFalse(usageSnapshot.isLoading)
        XCTAssertFalse(usageSnapshot.isRefreshing)
    }
}

final class UsageServiceRollingWindowTests: XCTestCase {
    func test_usageService_windowChangeCancelsInFlightLoadAndPublishesLatestWindow() async throws {
        let suiteName = "UsageServiceRollingWindowTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let now = Date()
        let rollingStart = now.addingTimeInterval(-24 * 60 * 60)
        let tracker = CancellableUsageRequestTracker()
        let reader = CancellableSequencedReader(
            name: "Mock",
            blockedRequestNumber: 1,
            tracker: tracker) { startDate, _ in
                mockUsage(totalTokens: startDate == rollingStart ? 200 : 100)
            }
        let service = await MainActor.run {
            let settings = UsagePanelSettings(
                defaults: UserDefaults(suiteName: suiteName)!,
                readerNames: ["Mock"])
            return UsageService(
                readers: [reader],
                settings: settings,
                comparisonDebounce: .seconds(30),
                now: { now })
        }
        let initialRefresh = Task { await service.refresh() }
        await tracker.waitForRequestCount(1)

        await MainActor.run {
            service.settings.setCurrentUsageWindow(.rolling24Hours)
            service.handleCurrentUsageWindowChange()
        }
        await service.refresh(usesWindowResultCache: true)
        await initialRefresh.value

        let requestSnapshot = await tracker.snapshot()
        let usageSnapshot = await MainActor.run { service.presentationSnapshot }
        XCTAssertEqual(requestSnapshot.requestCount, 2)
        XCTAssertEqual(requestSnapshot.cancellationCount, 1)
        XCTAssertEqual(usageSnapshot.combinedUsageData.totalTokens, 200)
        XCTAssertFalse(usageSnapshot.isLoading)
        XCTAssertFalse(usageSnapshot.isRefreshing)
    }

    func test_usageService_cachedWindowRestoresImmediatelyWhileCancelingReplacementLoad() async throws {
        let suiteName = "UsageServiceRollingWindowTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let now = Date()
        let tracker = CancellableUsageRequestTracker()
        let reader = CancellableSequencedReader(
            name: "Mock",
            blockedRequestNumbers: [2, 3],
            tracker: tracker,
            requestHandler: { requestNumber, _, _ in
                mockUsage(totalTokens: requestNumber == 1 ? 100 : 999)
            })
        let service = await MainActor.run {
            let settings = UsagePanelSettings(
                defaults: UserDefaults(suiteName: suiteName)!,
                readerNames: ["Mock"])
            return UsageService(
                readers: [reader],
                settings: settings,
                comparisonDebounce: .seconds(30),
                now: { now })
        }
        await service.refresh()

        await MainActor.run {
            service.settings.setCurrentUsageWindow(.rolling24Hours)
            service.handleCurrentUsageWindowChange()
        }
        let rollingRefresh = Task { await service.refresh(usesWindowResultCache: true) }
        await tracker.waitForRequestCount(2)

        let refreshingSnapshot = await MainActor.run { service.presentationSnapshot }
        let presentedWindow = await MainActor.run { service.currentUsageWindowForPresentation }
        XCTAssertEqual(refreshingSnapshot.combinedUsageData.totalTokens, 100)
        XCTAssertFalse(refreshingSnapshot.isLoading)
        XCTAssertTrue(refreshingSnapshot.isRefreshing)
        XCTAssertEqual(presentedWindow, .calendarDay)

        await MainActor.run {
            service.settings.setCurrentUsageWindow(.calendarDay)
            service.handleCurrentUsageWindowChange()
        }
        let cachedRefresh = Task { await service.refresh(usesWindowResultCache: true) }
        await tracker.waitForRequestCount(3)

        let cachedSnapshot = await MainActor.run { service.presentationSnapshot }
        let cachedWindow = await MainActor.run { service.currentUsageWindowForPresentation }
        XCTAssertEqual(cachedSnapshot.combinedUsageData.totalTokens, 100)
        XCTAssertFalse(cachedSnapshot.isLoading)
        XCTAssertTrue(cachedSnapshot.isRefreshing)
        XCTAssertEqual(cachedWindow, .calendarDay)

        cachedRefresh.cancel()
        await cachedRefresh.value
        await rollingRefresh.value

        let requestSnapshot = await tracker.snapshot()
        let settledSnapshot = await MainActor.run { service.presentationSnapshot }
        XCTAssertEqual(requestSnapshot.requestCount, 3)
        XCTAssertEqual(requestSnapshot.cancellationCount, 2)
        XCTAssertFalse(settledSnapshot.isLoading)
        XCTAssertFalse(settledSnapshot.isRefreshing)
    }

    func test_usageService_rollingWindowUsesCurrentAndPrevious24HourIntervals() async throws {
        let suiteName = "UsageServiceComparisonRefreshTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let now = tokiTestISODate("2026-08-26T12:34:56Z")
        let recorder = MockReaderRecorder()
        let reader = MockReader(name: "Mock", recorder: recorder) { _, _ in
            mockUsage(totalTokens: 120)
        }
        let service = await MainActor.run {
            let settings = UsagePanelSettings(
                defaults: UserDefaults(suiteName: suiteName)!,
                readerNames: ["Mock"])
            settings.setCurrentUsageWindow(.rolling24Hours)
            return UsageService(
                readers: [reader],
                settings: settings,
                comparisonDebounce: .zero,
                now: { now })
        }

        await service.refresh()

        await recorder.waitForCallCount(2)
        let calls = await recorder.snapshot()

        let currentStart = now.addingTimeInterval(-24 * 60 * 60)
        let previousStart = currentStart.addingTimeInterval(-24 * 60 * 60)
        XCTAssertEqual(calls.count, 2)
        let currentCall = try XCTUnwrap(calls.first)
        let previousCall = try XCTUnwrap(calls.dropFirst().first)
        XCTAssertEqual(currentCall.start, currentStart)
        XCTAssertEqual(currentCall.end, now)
        XCTAssertEqual(previousCall.start, previousStart)
        XCTAssertEqual(previousCall.end, currentStart)
    }

    func test_usageService_rollingSettingKeepsPastSelectionCalendarAligned() async throws {
        let suiteName = "UsageServiceComparisonRefreshTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let pastDay = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today))
        let pastEnd = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: pastDay))
        let recorder = MockReaderRecorder()
        let reader = MockReader(name: "Mock", recorder: recorder) { _, _ in
            mockUsage(totalTokens: 120)
        }
        let service = await MainActor.run {
            let settings = UsagePanelSettings(
                defaults: UserDefaults(suiteName: suiteName)!,
                readerNames: ["Mock"])
            settings.setCurrentUsageWindow(.rolling24Hours)
            let service = UsageService(
                readers: [reader],
                settings: settings,
                now: { now })
            service.selectDay(pastDay)
            return service
        }

        await service.refresh()

        let calls = await recorder.snapshot()
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls[0].start, pastDay)
        XCTAssertEqual(calls[0].end, pastEnd)
    }
}

final class UsageWindowResultCacheTests: XCTestCase {
    func test_cachePrunesExpiredEntriesAndBoundsItsSize() {
        let cache = UsageWindowResultCache(maximumAge: 10, maximumEntryCount: 2)
        let base = Date(timeIntervalSince1970: 1000)
        let request = UsageAggregationRequest(
            start: base,
            end: base.addingTimeInterval(1),
            enabledReaderNames: [:],
            includesEmptySourceRows: false)
        let result = UsageAggregationResult(
            usageData: .empty,
            modelReports: [:],
            originReports: [],
            readerStatuses: [])

        for offset in 0..<3 {
            let fetchedAt = base.addingTimeInterval(TimeInterval(offset))
            let key = UsageWindowResultCacheKey(
                window: .calendarDay,
                calendarDayStart: fetchedAt,
                enabledReaderNames: [],
                includesEmptySourceRows: false)
            cache.store(
                UsageWindowResultCacheEntry(
                    request: request,
                    result: result,
                    fetchedAt: fetchedAt,
                    previousTotalTokens: nil),
                for: key,
                now: fetchedAt)
        }

        XCTAssertEqual(cache.count, 2)
        let latestKey = UsageWindowResultCacheKey(
            window: .calendarDay,
            calendarDayStart: base.addingTimeInterval(2),
            enabledReaderNames: [],
            includesEmptySourceRows: false)
        let differentRequest = UsageAggregationRequest(
            start: base.addingTimeInterval(10),
            end: base.addingTimeInterval(11),
            enabledReaderNames: [:],
            includesEmptySourceRows: false)
        cache.storePreviousTotalTokens(999, for: latestKey, matching: differentRequest)
        XCTAssertNil(cache.entry(for: latestKey, now: base.addingTimeInterval(2))?.previousTotalTokens)
        XCTAssertNil(cache.entry(for: latestKey, now: base.addingTimeInterval(20)))
        XCTAssertEqual(cache.count, 0)
    }
}

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
}

final class UsageServiceRefreshCancellationTests: XCTestCase {
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

        let service = await MainActor.run {
            UsageService(readers: [reader], comparisonDebounce: .zero)
        }
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

    func test_usageService_selectionChangeRejectsActiveLoadWithoutReplacementRefresh() async throws {
        let gate = BlockingReaderGate()
        let today = Calendar.current.startOfDay(for: Date())
        let firstDay = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -3, to: today))
        let secondDay = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -2, to: today))
        let reader = BlockingMockReader(name: "Mock", gate: gate) { _, _ in
            mockUsage(totalTokens: 100)
        }
        let service = await MainActor.run { UsageService(readers: [reader]) }
        await MainActor.run { service.selectDay(firstDay) }
        let initialRefresh = Task { await service.refresh() }
        await gate.waitForFirstRequest()

        await MainActor.run { service.selectDay(secondDay) }
        await gate.release()
        await initialRefresh.value

        let totalTokens = await MainActor.run { service.usageData.totalTokens }
        let selectedStart = await MainActor.run { service.startDate }
        let loadingSnapshot = await MainActor.run { service.presentationSnapshot }
        XCTAssertEqual(totalTokens, 0)
        XCTAssertEqual(selectedStart, secondDay)
        XCTAssertFalse(loadingSnapshot.isLoading)
        XCTAssertFalse(loadingSnapshot.isRefreshing)
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
