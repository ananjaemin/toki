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

    func scheduleSettingsRefresh(refresh: @escaping @MainActor () async -> Void) {
        settingsRefreshTask?.cancel()
        settingsRefreshTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    func cancel() {
        refreshLoopTask?.cancel()
        settingsRefreshTask?.cancel()
        refreshLoopTask = nil
        settingsRefreshTask = nil
    }
}
