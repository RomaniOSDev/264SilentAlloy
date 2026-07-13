import SwiftUI

struct ReportExportView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var shareItems: [Any] = []
    @State private var showShare = false
    @State private var statusMessage: String?

    private var summary: ReportExporter.WeekSummary {
        ReportExporter.weekSummary(from: store.dewPointHistory)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScreenHeaderCell(
                title: "Weekly Report",
                subtitle: "Export moisture summaries for sharing or records",
                symbolName: "doc.richtext"
            )

            if !summary.hasData {
                EmptyStateView(
                    symbolName: "doc.text",
                    title: "No weekly data yet",
                    message: "Save readings this week to build a shareable moisture report."
                )
            } else {
                AppCard(accentBorder: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabelCell(
                            title: "Week summary",
                            accessory: "\(summary.readings.count) entries"
                        )

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            MetricTileCell(
                                title: "Peak",
                                value: summary.peak.map(store.formattedDewPoint) ?? "—",
                                symbolName: "arrow.up.right",
                                emphasize: true
                            )
                            MetricTileCell(
                                title: "Lowest",
                                value: summary.lowest.map(store.formattedDewPoint) ?? "—",
                                symbolName: "arrow.down.right"
                            )
                            MetricTileCell(
                                title: "Average",
                                value: summary.average.map(store.formattedDewPoint) ?? "—",
                                symbolName: "chart.bar"
                            )
                            MetricTileCell(
                                title: "Risk days",
                                value: "\(summary.riskDays)",
                                symbolName: "exclamationmark.triangle"
                            )
                        }
                    }
                }

                AppCard {
                    VStack(spacing: 12) {
                        Button(action: exportCSV) {
                            Text("Export CSV")
                                .primaryButtonStyle()
                        }
                        .frame(minHeight: 44)

                        Button(action: exportPDF) {
                            SecondaryButtonLabel(title: "Export PDF")
                        }
                        .frame(minHeight: 44)

                        if let statusMessage {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundStyle(Color("AppAccent"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ActivityView(activityItems: shareItems)
        }
    }

    private func exportCSV() {
        FeedbackService.tap()
        let csv = ReportExporter.csv(
            for: summary,
            unit: store.temperatureUnit,
            display: store.displayValue
        )
        guard let data = csv.data(using: .utf8),
              let url = ReportExporter.writeTemporaryFile(data: data, filename: "weekly-dew-point.csv") else {
            statusMessage = "Could not create CSV file."
            FeedbackService.warning()
            return
        }
        finishExport(with: url)
    }

    private func exportPDF() {
        FeedbackService.tap()
        let data = ReportExporter.pdfData(for: summary, formatted: store.formattedDewPoint)
        guard let url = ReportExporter.writeTemporaryFile(data: data, filename: "weekly-dew-point.pdf") else {
            statusMessage = "Could not create PDF file."
            FeedbackService.warning()
            return
        }
        finishExport(with: url)
    }

    private func finishExport(with url: URL) {
        store.registerReportExport()
        FeedbackService.success()
        shareItems = [url]
        showShare = true
        statusMessage = "Report ready to share."
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
