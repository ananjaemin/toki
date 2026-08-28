import Foundation
import TokiUsageCore

/// Reads Oh My Pi JSONL sessions from default, profile, and XDG stores.
public struct OMPReader: TokenReader {
    public static let sourceName = "OMP"

    public let name = Self.sourceName
    private let sessionDirectories: [URL]

    public init(sessionDirectoriesOverride: [URL]? = nil) {
        sessionDirectories = sessionDirectoriesOverride
            ?? LocalUsageReaderPaths().ompSessionDirectories
    }

    public func readUsage(from startDate: Date, to endDate: Date) async throws -> RawTokenUsage {
        readPiSessionUsage(
            in: sessionDirectories,
            sourceName: Self.sourceName,
            from: startDate,
            to: endDate)
    }
}
