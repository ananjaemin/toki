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
    private var entries: [UsageWindowResultCacheKey: UsageWindowResultCacheEntry] = [:]

    init(maximumAge: TimeInterval = 60) {
        self.maximumAge = maximumAge
    }

    func entry(for key: UsageWindowResultCacheKey, now: Date = Date()) -> UsageWindowResultCacheEntry? {
        guard let entry = entries[key] else { return nil }
        let age = now.timeIntervalSince(entry.fetchedAt)
        guard age >= 0, age <= maximumAge else {
            entries[key] = nil
            return nil
        }
        return entry
    }

    func store(_ entry: UsageWindowResultCacheEntry, for key: UsageWindowResultCacheKey) {
        entries[key] = entry
    }

    func storePreviousTotalTokens(_ totalTokens: Int, for key: UsageWindowResultCacheKey) {
        guard var entry = entries[key] else { return }
        entry.previousTotalTokens = totalTokens
        entries[key] = entry
    }

    func clear() {
        entries.removeAll()
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
