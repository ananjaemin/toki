import Foundation
import TokiUsageCore

struct UsageServiceSnapshot: Equatable {
    var combinedUsageData: UsageData = .empty
    var combinedModelReports: [String: UsageModelReport] = [:]
    var originReports: [UsageOriginReport] = []
    var isLoading = false
    var isRefreshing = false
    var lastFetchedAt: Date?
    var yesterdayTotalTokens: Int?
    var readerStatuses: [ReaderStatus] = []
    var periodTokenTotals: [TokenTotalSummary] = []
    var isLoadingPeriodTokenTotals = false
}

@MainActor
final class UsagePanelViewModel: ObservableObject {
    static let periodTokenTotalsCacheMaxAge: TimeInterval = 600

    @Published var startDate: Date
    @Published var endDate: Date
    @Published var isRangeMode = false {
        didSet {
            if isRangeMode {
                followsCurrentDaySelection = false
            }
        }
    }

    @Published private(set) var selectedUsageScope: UsageScope = .all
    @Published private(set) var selectedModelScope: UsageModelScope = .all

    @Published private var snapshot = UsageServiceSnapshot()

    let settings: UsagePanelSettings

    let aggregator: UsageAggregator
    let periodTokenTotalsCache: PeriodTokenTotalsCache
    private let usageWindowResultCache: UsageWindowResultCache
    private let comparisonDebounce: Duration
    private var followsCurrentDaySelection = true
    private var calendarDayObserver: NSObjectProtocol?
    private var yesterdayComparisonTask: Task<Void, Never>?
    private var activeUsageTask: Task<UsageAggregationResult, Never>?
    private var activeRefreshIdentity: UsageRefreshIdentity?
    private var usageRefreshGeneration: UInt64 = 0
    private var presentedUsageRequest: UsageAggregationRequest?
    var activePeriodTokenTotalsRequest: PeriodTokenTotalsRequest?
    var periodTokenTotalsGeneration: UInt64 = 0
    var lastPeriodTokenTotalsRequest: PeriodTokenTotalsRequest?
    var lastPeriodTokenTotalsFetchedAt: Date?
    private let now: () -> Date

    var calendar: Calendar {
        .autoupdatingCurrent
    }

    convenience init(
        readers: [any TokenReader] = UsageAggregator.defaultReaders,
        settings: UsagePanelSettings? = nil,
        periodTokenTotalsCache: PeriodTokenTotalsCache = PeriodTokenTotalsCache(),
        usageWindowResultCache: UsageWindowResultCache = UsageWindowResultCache(),
        comparisonDebounce: Duration = .milliseconds(300),
        now: @escaping () -> Date = { Date() }) {
        self.init(
            aggregator: UsageAggregator(readers: readers),
            settings: settings,
            periodTokenTotalsCache: periodTokenTotalsCache,
            usageWindowResultCache: usageWindowResultCache,
            comparisonDebounce: comparisonDebounce,
            now: now)
    }

    init(
        aggregator: UsageAggregator,
        settings: UsagePanelSettings? = nil,
        periodTokenTotalsCache: PeriodTokenTotalsCache = PeriodTokenTotalsCache(),
        usageWindowResultCache: UsageWindowResultCache = UsageWindowResultCache(),
        comparisonDebounce: Duration = .milliseconds(300),
        now: @escaping () -> Date = { Date() }) {
        self.aggregator = aggregator
        self.settings = settings ?? UsagePanelSettings(readerNames: aggregator.readerNames)
        self.periodTokenTotalsCache = periodTokenTotalsCache
        self.usageWindowResultCache = usageWindowResultCache
        self.comparisonDebounce = comparisonDebounce
        self.now = now

        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: now())
        startDate = today
        endDate = calendar.date(byAdding: .day, value: 1, to: today)!

        calendarDayObserver = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleCalendarDayChange()
                }
            }
    }

    deinit {
        yesterdayComparisonTask?.cancel()
        activeUsageTask?.cancel()
        if let calendarDayObserver {
            NotificationCenter.default.removeObserver(calendarDayObserver)
        }
    }

    func selectDay(_ date: Date) {
        resetYesterdayComparison()
        presentedUsageRequest = nil
        startDate = calendar.startOfDay(for: date)
        endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        followsCurrentDaySelection = calendar.isDateInToday(startDate)
    }

    func selectRangeStart(_ date: Date) {
        resetYesterdayComparison()
        presentedUsageRequest = nil
        startDate = calendar.startOfDay(for: date)
        if startDate >= endDate {
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        }
        followsCurrentDaySelection = false
    }

    func selectRangeEnd(_ date: Date) {
        resetYesterdayComparison()
        presentedUsageRequest = nil
        let selectedEnd = calendar.startOfDay(for: date)
        endDate = calendar.date(byAdding: .day, value: 1, to: selectedEnd)!
        if startDate >= endDate {
            startDate = selectedEnd
        }
        followsCurrentDaySelection = false
    }

    func selectRange(from: Date, to: Date) {
        resetYesterdayComparison()
        presentedUsageRequest = nil
        let normalizedFrom = calendar.startOfDay(for: from)
        let normalizedTo = calendar.startOfDay(for: to)
        let lowerBound = min(normalizedFrom, normalizedTo)
        let upperBound = max(normalizedFrom, normalizedTo)
        startDate = lowerBound
        endDate = calendar.date(byAdding: .day, value: 1, to: upperBound)!
        followsCurrentDaySelection = false
    }

    func refresh(usesWindowResultCache: Bool = false) async {
        let refreshNow = now()
        syncSelectionWithTodayIfNeeded(now: refreshNow)
        let request = makeUsageRequest(
            start: startDate,
            end: endDate,
            now: refreshNow)
        let refreshIdentity = makeUsageRefreshIdentity(request: request)
        var previousTotalTokens = presentedUsageRequest == request && canCachePreviousComparison
            ? snapshot.yesterdayTotalTokens
            : nil

        if activeUsageTask != nil {
            guard activeRefreshIdentity != refreshIdentity else { return }
            cancelActiveUsageRefresh()
        }

        cancelYesterdayComparison()
        let cacheKey = makeUsageWindowResultCacheKey()
        if usesWindowResultCache,
           let cacheKey,
           let cachedResult = publishCachedUsage(
               for: request,
               cacheKey: cacheKey,
               now: refreshNow) {
            previousTotalTokens = cachedResult.previousTotalTokens ?? previousTotalTokens
            refreshPeriodTokenTotalsAfterScopeFallbackIfNeeded(cachedResult.didFallBackToAllDevices)
        }

        usageRefreshGeneration &+= 1
        let generation = usageRefreshGeneration
        activeRefreshIdentity = refreshIdentity
        updateSnapshot {
            $0.isLoading = presentedUsageRequest == nil
            $0.isRefreshing = presentedUsageRequest != nil
        }
        let usageTask = Task { await aggregator.aggregateUsage(for: request) }
        activeUsageTask = usageTask
        let result = await withTaskCancellationHandler {
            await usageTask.value
        } onCancel: {
            usageTask.cancel()
        }

        guard !Task.isCancelled,
              !usageTask.isCancelled,
              generation == usageRefreshGeneration,
              activeRefreshIdentity == refreshIdentity else {
            finishCanceledUsageRefresh(generation: generation)
            return
        }

        activeUsageTask = nil
        activeRefreshIdentity = nil
        let fetchedAt = now()
        let didFallBackToAllDevices = publishUsageResult(
            result,
            request: request,
            fetchedAt: fetchedAt,
            previousTotalTokens: previousTotalTokens)
        if let cacheKey {
            usageWindowResultCache.store(
                UsageWindowResultCacheEntry(
                    request: request,
                    result: result,
                    fetchedAt: fetchedAt,
                    previousTotalTokens: previousTotalTokens),
                for: cacheKey,
                now: fetchedAt)
        }

        if shouldCompareAgainstYesterday(start: request.start, end: request.end) {
            startYesterdayComparison(
                for: request,
                scope: selectedUsageScope,
                modelScope: selectedModelScope,
                cacheKey: canCachePreviousComparison ? cacheKey : nil)
        }
        refreshPeriodTokenTotalsAfterScopeFallbackIfNeeded(didFallBackToAllDevices)
    }
}

typealias UsageService = UsagePanelViewModel

extension UsagePanelViewModel {
    @discardableResult
    func syncSelectionWithTodayIfNeeded(now: Date = Date()) -> Bool {
        guard followsCurrentDaySelection else { return false }

        let today = calendar.startOfDay(for: now)
        guard startDate != today || !isSingleDay else { return false }

        resetYesterdayComparison()
        presentedUsageRequest = nil
        startDate = today
        endDate = calendar.date(byAdding: .day, value: 1, to: today)!
        followsCurrentDaySelection = true
        return true
    }

    func refreshAfterRemoteSyncChange() async {
        cancelActiveUsageRefresh()
        usageWindowResultCache.clear()
        periodTokenTotalsCache.clear()
        invalidatePeriodTokenTotals()
        await refresh()
        await refreshPeriodTokenTotalsIfNeeded()
    }

    var readerNames: [String] {
        aggregator.readerNames
    }

    var presentationSnapshot: UsageServiceSnapshot {
        snapshot
    }

    var isSingleDay: Bool {
        calendar.dateComponents([.day], from: startDate, to: endDate).day == 1
    }

    var currentUsageWindowForPresentation: CurrentUsageWindow? {
        guard isShowingCurrentUsageWindow else { return nil }
        return settings.currentUsageWindow
    }

    var shouldCompareAgainstYesterday: Bool {
        isShowingCurrentUsageWindow
    }

    func handleCurrentUsageWindowChange() {
        guard isShowingCurrentUsageWindow else { return }
        cancelActiveUsageRefresh()
        resetYesterdayComparison()
        updateSnapshot {
            $0.isLoading = presentedUsageRequest == nil
            $0.isRefreshing = presentedUsageRequest != nil
        }
    }

    func selectUsageScope(_ scope: UsageScope) {
        guard scope != selectedUsageScope else { return }
        if case let .origin(originID) = scope,
           !snapshot.originReports.contains(where: { $0.id == originID }) {
            return
        }

        resetYesterdayComparison()
        selectedUsageScope = scope
        invalidatePeriodTokenTotals()

        let request = presentedUsageRequest ?? makeUsageRequest(
            start: startDate,
            end: endDate,
            now: now())
        if shouldCompareAgainstYesterday(start: request.start, end: request.end) {
            startYesterdayComparison(
                for: request,
                scope: scope,
                modelScope: selectedModelScope)
        }

        Task { [weak self] in
            await self?.refreshPeriodTokenTotalsIfNeeded()
        }
    }

    func selectModelScope(_ scope: UsageModelScope) {
        guard scope != selectedModelScope else { return }

        resetYesterdayComparison()
        selectedModelScope = scope
        invalidatePeriodTokenTotals()

        let request = presentedUsageRequest ?? makeUsageRequest(
            start: startDate,
            end: endDate,
            now: now())
        if shouldCompareAgainstYesterday(start: request.start, end: request.end) {
            startYesterdayComparison(
                for: request,
                scope: selectedUsageScope,
                modelScope: scope)
        }

        Task { [weak self] in
            await self?.refreshPeriodTokenTotalsIfNeeded()
        }
    }

    func updateSnapshot(_ update: (inout UsageServiceSnapshot) -> Void) {
        var nextSnapshot = snapshot
        update(&nextSnapshot)
        guard nextSnapshot != snapshot else { return }
        snapshot = nextSnapshot
    }
}

private extension UsagePanelViewModel {
    func publishCachedUsage(
        for request: UsageAggregationRequest,
        cacheKey: UsageWindowResultCacheKey,
        now: Date) -> (previousTotalTokens: Int?, didFallBackToAllDevices: Bool)? {
        guard let cachedEntry = usageWindowResultCache.entry(for: cacheKey, now: now) else { return nil }
        let previousTotalTokens = canCachePreviousComparison && cachedEntry.request == request
            ? cachedEntry.previousTotalTokens
            : nil
        let didFallBackToAllDevices = publishUsageResult(
            cachedEntry.result,
            request: cachedEntry.request,
            fetchedAt: cachedEntry.fetchedAt,
            previousTotalTokens: previousTotalTokens)
        updateSnapshot {
            $0.isLoading = false
            $0.isRefreshing = true
        }
        return (previousTotalTokens, didFallBackToAllDevices)
    }

    var isShowingCurrentUsageWindow: Bool {
        !isRangeMode && followsCurrentDaySelection && isSingleDay
    }

    var canCachePreviousComparison: Bool {
        selectedUsageScope == .all && selectedModelScope == .all
    }

    private func cancelActiveUsageRefresh() {
        usageRefreshGeneration &+= 1
        activeUsageTask?.cancel()
        activeUsageTask = nil
        activeRefreshIdentity = nil
    }

    private func finishCanceledUsageRefresh(generation: UInt64) {
        guard generation == usageRefreshGeneration else { return }
        activeUsageTask = nil
        activeRefreshIdentity = nil
        updateSnapshot {
            $0.isLoading = false
            $0.isRefreshing = false
        }
    }

    private func makeUsageWindowResultCacheKey() -> UsageWindowResultCacheKey? {
        guard let window = currentUsageWindowForPresentation else { return nil }
        let enabledReaderNames = settings.normalizedReaderSettings(for: readerNames)
            .filter(\.value)
            .map(\.key)
            .sorted()
        return UsageWindowResultCacheKey(
            window: window,
            calendarDayStart: window == .calendarDay ? startDate : nil,
            enabledReaderNames: enabledReaderNames,
            includesEmptySourceRows: settings.showsZeroSourceRows)
    }

    @discardableResult
    private func publishUsageResult(
        _ result: UsageAggregationResult,
        request: UsageAggregationRequest,
        fetchedAt: Date,
        previousTotalTokens: Int?) -> Bool {
        let didFallBackToAllDevices = resolveSelectedUsageScope(
            availableReports: result.originReports)
        updateSnapshot {
            $0.combinedUsageData = result.usageData
            $0.combinedModelReports = result.modelReports
            $0.originReports = result.originReports
            $0.readerStatuses = result.readerStatuses
            $0.lastFetchedAt = fetchedAt
            $0.yesterdayTotalTokens = previousTotalTokens
            $0.isLoading = false
            $0.isRefreshing = false
        }
        presentedUsageRequest = request
        return didFallBackToAllDevices
    }

    private func refreshPeriodTokenTotalsAfterScopeFallbackIfNeeded(_ isNeeded: Bool) {
        guard isNeeded else { return }
        Task { [weak self] in
            await self?.refreshPeriodTokenTotalsIfNeeded()
        }
    }

    private func handleCalendarDayChange(now: Date = Date()) {
        guard syncSelectionWithTodayIfNeeded(now: now) else { return }
        Task {
            await refresh()
            await refreshPeriodTokenTotalsIfNeeded()
        }
    }

    private func makeUsageRefreshIdentity(request: UsageAggregationRequest) -> UsageRefreshIdentity {
        UsageRefreshIdentity(
            selectionStart: startDate,
            selectionEnd: endDate,
            requestStart: request.start,
            requestEnd: request.end,
            isRangeMode: isRangeMode,
            currentUsageWindow: currentUsageWindowForPresentation,
            enabledReaderNames: settings.normalizedReaderSettings(for: readerNames),
            includesEmptySourceRows: settings.showsZeroSourceRows)
    }

    private func makeUsageRequest(
        start: Date,
        end: Date,
        now: Date) -> UsageAggregationRequest {
        let interval = currentUsageWindowForPresentation?.dateInterval(
            at: now,
            calendar: calendar) ?? DateInterval(start: start, end: end)
        return UsageAggregationRequest(
            start: interval.start,
            end: interval.end,
            enabledReaderNames: settings.normalizedReaderSettings(for: readerNames),
            includesEmptySourceRows: settings.showsZeroSourceRows)
    }

    private func cancelYesterdayComparison() {
        yesterdayComparisonTask?.cancel()
        yesterdayComparisonTask = nil
    }

    @discardableResult
    private func resolveSelectedUsageScope(
        availableReports: [UsageOriginReport]) -> Bool {
        guard case let .origin(originID) = selectedUsageScope,
              !availableReports.contains(where: { $0.id == originID }) else {
            return false
        }

        resetYesterdayComparison()
        selectedUsageScope = .all
        invalidatePeriodTokenTotals()
        return true
    }

    private func resetYesterdayComparison() {
        cancelYesterdayComparison()
        if snapshot.yesterdayTotalTokens != nil {
            updateSnapshot { $0.yesterdayTotalTokens = nil }
        }
    }

    private func shouldCompareAgainstYesterday(start _: Date, end _: Date) -> Bool {
        isShowingCurrentUsageWindow
    }

    private func startYesterdayComparison(
        for request: UsageAggregationRequest,
        scope: UsageScope,
        modelScope: UsageModelScope,
        cacheKey: UsageWindowResultCacheKey? = nil) {
        guard let window = currentUsageWindowForPresentation else { return }
        yesterdayComparisonTask = Task { [weak self] in
            guard let self else { return }
            if comparisonDebounce > .zero {
                try? await Task.sleep(for: comparisonDebounce)
            }
            guard !Task.isCancelled else { return }
            let previousInterval = window.previousDateInterval(
                before: request.dateInterval,
                calendar: calendar)
            guard !Task.isCancelled else { return }

            let previousRequest = UsageAggregationRequest(
                start: previousInterval.start,
                end: previousInterval.end,
                enabledReaderNames: request.enabledReaderNames,
                includesEmptySourceRows: request.includesEmptySourceRows)
            let previousTotalTokens = await aggregator.aggregateTotalTokens(
                for: previousRequest,
                scope: scope,
                modelScope: modelScope)

            guard !Task.isCancelled else { return }
            guard request == presentedUsageRequest,
                  currentUsageWindowForPresentation == window,
                  selectedUsageScope == scope,
                  selectedModelScope == modelScope,
                  shouldCompareAgainstYesterday(start: request.start, end: request.end) else {
                return
            }

            updateSnapshot { $0.yesterdayTotalTokens = previousTotalTokens }
            if let cacheKey {
                usageWindowResultCache.storePreviousTotalTokens(
                    previousTotalTokens,
                    for: cacheKey,
                    matching: request)
            }
            yesterdayComparisonTask = nil
        }
    }
}
