import SwiftUI

enum PanelHeroComparisonReference {
    case yesterday
    case previous24Hours

    var comparisonText: String {
        switch self {
        case .yesterday:
            "yesterday"
        case .previous24Hours:
            "previous 24h"
        }
    }

    var noUsageText: String {
        switch self {
        case .yesterday:
            "No usage yesterday"
        case .previous24Hours:
            "No usage in previous 24h"
        }
    }
}

struct PanelHeroComparisonContent {
    let symbolName: String?
    let text: String
    let color: Color

    static func make(
        currentTotal: Int,
        previousTotal: Int?,
        reference: PanelHeroComparisonReference) -> PanelHeroComparisonContent? {
        guard let previousTotal else { return nil }

        if previousTotal == 0 {
            if currentTotal == 0 {
                return PanelHeroComparisonContent(
                    symbolName: "minus",
                    text: "0% from \(reference.comparisonText)",
                    color: Color.white.opacity(0.35))
            }

            return PanelHeroComparisonContent(
                symbolName: nil,
                text: reference.noUsageText,
                color: Color.white.opacity(0.35))
        }

        let delta = currentTotal - previousTotal
        if delta == 0 {
            return PanelHeroComparisonContent(
                symbolName: "minus",
                text: "0% from \(reference.comparisonText)",
                color: Color.white.opacity(0.35))
        }

        let pct = Int(abs(Double(delta) / Double(previousTotal) * 100))
        let isUp = delta > 0

        return PanelHeroComparisonContent(
            symbolName: isUp ? "arrow.up" : "arrow.down",
            text: "\(pct)% from \(reference.comparisonText)",
            color: isUp
                ? Color(red: 1.0, green: 0.45, blue: 0.4)
                : Color(red: 0.4, green: 0.9, blue: 0.6))
    }
}
