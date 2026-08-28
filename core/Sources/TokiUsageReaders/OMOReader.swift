import Foundation
import TokiUsageCore

/// Reads OMO/Senpi/pi-family JSONL sessions from current, legacy, profile, and XDG stores.
public struct OMOReader: TokenReader {
    public static let sourceName = "OMO"

    public let name = Self.sourceName
    private let sessionDirectories: [URL]

    public init(sessionDirectoriesOverride: [URL]? = nil) {
        sessionDirectories = sessionDirectoriesOverride
            ?? LocalUsageReaderPaths().omoSessionDirectories
    }

    public func readUsage(from startDate: Date, to endDate: Date) async throws -> RawTokenUsage {
        readPiSessionUsage(
            in: sessionDirectories,
            sourceName: Self.sourceName,
            from: startDate,
            to: endDate)
    }

    static func usage(
        fromJSONLLines lines: [String],
        streamID: String,
        from startDate: Date,
        to endDate: Date) -> RawTokenUsage {
        GJCReader.usage(
            fromJSONLLines: lines,
            streamID: streamID,
            from: startDate,
            to: endDate,
            sourceName: sourceName)
    }
}

func readPiSessionUsage(
    in sessionDirectories: [URL],
    sourceName: String,
    from startDate: Date,
    to endDate: Date) -> RawTokenUsage {
    var result = RawTokenUsage()

    for directory in sessionDirectories where FileManager.default.fileExists(atPath: directory.path) {
        let files = findFiles(in: directory, withExtension: "jsonl", modifiedAfter: startDate)
        for file in files {
            result += GJCReader.usage(
                fromJSONLLines: readJSONLLines(at: file),
                streamID: file.path,
                from: startDate,
                to: endDate,
                sourceName: sourceName)
        }
    }

    return result
}
