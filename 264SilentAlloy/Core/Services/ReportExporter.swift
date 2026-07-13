import Foundation
import UIKit

enum ReportExporter {
    struct WeekSummary {
        let start: Date
        let end: Date
        let readings: [DewPointRecord]
        let peak: Double?
        let lowest: Double?
        let average: Double?
        let riskDays: Int

        var hasData: Bool { !readings.isEmpty }
    }

    static func weekSummary(from history: [DewPointRecord], now: Date = Date()) -> WeekSummary {
        let calendar = Calendar.current
        let end = now
        let start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        let readings = history
            .filter { $0.timestamp >= start && $0.timestamp <= end }
            .sorted { $0.timestamp < $1.timestamp }

        let values = readings.map(\.dewPoint)
        let peak = values.max()
        let lowest = values.min()
        let average = values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)

        let riskDaySet = Set(
            readings
                .filter { ComfortRiskEngine.isRiskDay(dewPointC: $0.dewPoint) }
                .map { calendar.startOfDay(for: $0.timestamp) }
        )

        return WeekSummary(
            start: start,
            end: end,
            readings: readings,
            peak: peak,
            lowest: lowest,
            average: average,
            riskDays: riskDaySet.count
        )
    }

    static func csv(for summary: WeekSummary, unit: TemperatureUnit, display: (Double) -> Double) -> String {
        var lines: [String] = [
            "timestamp,dew_point_\(unit.symbol),temperature_\(unit.symbol),humidity_percent,tags,note,comfort,mold_risk"
        ]

        let formatter = ISO8601DateFormatter()
        for record in summary.readings {
            let tags = record.tags.joined(separator: "|")
            let note = record.note.replacingOccurrences(of: ",", with: ";")
            let comfort = ComfortRiskEngine.comfortZone(dewPointC: record.dewPoint).title
            let mold = ComfortRiskEngine.moldRisk(dewPointC: record.dewPoint).title
            let humidity = record.humidity.map { String(format: "%.1f", $0) } ?? ""
            lines.append(
                [
                    formatter.string(from: record.timestamp),
                    String(format: "%.2f", display(record.dewPoint)),
                    String(format: "%.2f", display(record.temperature)),
                    humidity,
                    tags,
                    note,
                    comfort,
                    mold
                ].joined(separator: ",")
            )
        }

        lines.append("")
        lines.append("summary_peak,\(summary.peak.map { String(format: "%.2f", display($0)) } ?? "")")
        lines.append("summary_lowest,\(summary.lowest.map { String(format: "%.2f", display($0)) } ?? "")")
        lines.append("summary_average,\(summary.average.map { String(format: "%.2f", display($0)) } ?? "")")
        lines.append("summary_risk_days,\(summary.riskDays)")
        return lines.joined(separator: "\n")
    }

    static func pdfData(for summary: WeekSummary, formatted: (Double) -> String) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()
            let title = "Weekly Dew Point Report"
            let subtitle = "\(summary.start.formatted(date: .abbreviated, time: .omitted)) – \(summary.end.formatted(date: .abbreviated, time: .omitted))"

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.black
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]

            title.draw(at: CGPoint(x: 36, y: 40), withAttributes: titleAttrs)
            subtitle.draw(at: CGPoint(x: 36, y: 70), withAttributes: bodyAttrs)

            var y: CGFloat = 110
            let rows = [
                "Readings: \(summary.readings.count)",
                "Peak: \(summary.peak.map(formatted) ?? "—")",
                "Lowest: \(summary.lowest.map(formatted) ?? "—")",
                "Average: \(summary.average.map(formatted) ?? "—")",
                "Risk days: \(summary.riskDays)"
            ]

            for row in rows {
                row.draw(at: CGPoint(x: 36, y: y), withAttributes: bodyAttrs)
                y += 22
            }

            y += 16
            "Recent entries".draw(at: CGPoint(x: 36, y: y), withAttributes: titleAttrs)
            y += 28

            for record in summary.readings.suffix(12) {
                let line = "\(record.timestamp.formatted(date: .abbreviated, time: .shortened))  \(formatted(record.dewPoint))  \(record.tags.joined(separator: ", "))"
                line.draw(at: CGPoint(x: 36, y: y), withAttributes: bodyAttrs)
                y += 18
                if y > 740 {
                    context.beginPage()
                    y = 40
                }
            }
        }
    }

    static func writeTemporaryFile(data: Data, filename: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
