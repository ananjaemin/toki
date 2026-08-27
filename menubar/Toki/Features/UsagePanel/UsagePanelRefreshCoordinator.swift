import Foundation

struct UsageRefreshIdentity: Equatable {
    let selectionStart: Date
    let selectionEnd: Date
    let isRangeMode: Bool
    let currentUsageWindow: CurrentUsageWindow?
    let enabledReaderNames: [String: Bool]
    let includesEmptySourceRows: Bool
}

struct UsageWindowResultCacheKey: Hashable {
    let window: CurrentUsageWindow
    let calendarDayStart: Date?
    let enabledReaderNames: [String]
    let includesEmptySourceRows: Bool
}

struct UsageWindowResultCacheEntry {
    let request: UsageAggregationRequest
    let result: UsageAggregationResult
    let fetchedAt: Date
    var previousTotalTokens: Int?
}

final class UsageWindowResultCache {
    private let maximumAge: TimeInterval
    private let maximumEntryCount: Int
    private var entries: [UsageWindowResultCacheKey: UsageWindowResultCacheEntry] = [:]

    init(maximumAge: TimeInterval = 60, maximumEntryCount: Int = 8) {
        precondition(maximumEntryCount > 0)
        self.maximumAge = maximumAge
        self.maximumEntryCount = maximumEntryCount
    }

    func entry(for key: UsageWindowResultCacheKey, now: Date = Date()) -> UsageWindowResultCacheEntry? {
        removeExpiredEntries(now: now)
        return entries[key]
    }

    func store(
        _ entry: UsageWindowResultCacheEntry,
        for key: UsageWindowResultCacheKey,
        now: Date = Date()) {
        removeExpiredEntries(now: now)
        entries[key] = entry
        while entries.count > maximumEntryCount,
              let oldestKey = entries.min(by: { $0.value.fetchedAt < $1.value.fetchedAt })?.key {
            entries[oldestKey] = nil
        }
    }

    func storePreviousTotalTokens(
        _ totalTokens: Int,
        for key: UsageWindowResultCacheKey,
        matching request: UsageAggregationRequest) {
        guard var entry = entries[key], entry.request == request else { return }
        entry.previousTotalTokens = totalTokens
        entries[key] = entry
    }

    var count: Int {
        entries.count
    }

    func clear() {
        entries.removeAll()
    }

    private func removeExpiredEntries(now: Date) {
        entries = entries.filter { _, entry in
            let age = now.timeIntervalSince(entry.fetchedAt)
            return age >= 0 && age <= maximumAge
        }
    }
}

@MainActor
final class UsagePanelRefreshCoordinator {
    private var refreshLoopTask: Task<Void, Never>?
    private var settingsRefreshTask: Task<Void, Never>?
    private var settingsRefreshGeneration: UInt64 = 0
    private var hasPendingSettingsRefresh = false
    private var isRunningSettingsRefresh = false
    private var pendingSettingsRefreshAction: (@MainActor (Bool, Bool) async -> Void)?
    private var pendingRefreshesPeriodTokenTotals = false
    private var pendingUsesWindowResultCache = true

    func startLoop(
        refreshImmediately: Bool,
        intervalSeconds: @escaping @MainActor () -> Int,
        refresh: @escaping @MainActor () async -> Void) {
        refreshLoopTask?.cancel()
        refreshLoopTask = Task { @MainActor in
            if refreshImmediately {
                await refresh()
            }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(intervalSeconds()))
                guard !Task.isCancelled else { return }
                await refresh()
            }
        }
    }

    func scheduleSettingsRefresh(
        refreshesPeriodTokenTotals: Bool,
        usesWindowResultCache: Bool,
        refresh: @escaping @MainActor (Bool, Bool) async -> Void) {
        if !hasPendingSettingsRefresh {
            pendingRefreshesPeriodTokenTotals = refreshesPeriodTokenTotals
            pendingUsesWindowResultCache = usesWindowResultCache
        } else {
            pendingRefreshesPeriodTokenTotals = pendingRefreshesPeriodTokenTotals || refreshesPeriodTokenTotals
            pendingUsesWindowResultCache = pendingUsesWindowResultCache && usesWindowResultCache
        }
        hasPendingSettingsRefresh = true
        pendingSettingsRefreshAction = refresh
        guard !isRunningSettingsRefresh else { return }

        startPendingSettingsRefresh()
    }

    private func startPendingSettingsRefresh() {
        settingsRefreshTask?.cancel()
        settingsRefreshGeneration &+= 1
        let generation = settingsRefreshGeneration
        settingsRefreshTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            let refreshesPeriodTokenTotals = pendingRefreshesPeriodTokenTotals
            let usesWindowResultCache = pendingUsesWindowResultCache
            guard let refresh = pendingSettingsRefreshAction else { return }
            hasPendingSettingsRefresh = false
            pendingRefreshesPeriodTokenTotals = false
            pendingUsesWindowResultCache = true
            pendingSettingsRefreshAction = nil
            isRunningSettingsRefresh = true
            await refresh(refreshesPeriodTokenTotals, usesWindowResultCache)
            guard generation == settingsRefreshGeneration else { return }
            isRunningSettingsRefresh = false
            settingsRefreshTask = nil
            if hasPendingSettingsRefresh {
                startPendingSettingsRefresh()
            }
        }
    }

    func cancel() {
        refreshLoopTask?.cancel()
        settingsRefreshTask?.cancel()
        settingsRefreshGeneration &+= 1
        refreshLoopTask = nil
        settingsRefreshTask = nil
        hasPendingSettingsRefresh = false
        isRunningSettingsRefresh = false
        pendingSettingsRefreshAction = nil
        pendingRefreshesPeriodTokenTotals = false
        pendingUsesWindowResultCache = true
    }
}
