import SwiftUI

struct HistoryListSection: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: HistoryViewModel

    private var records: [DewPointRecord] {
        store.filteredHistory
    }

    var body: some View {
        Group {
            if store.sortedHistory.isEmpty {
                EmptyStateView(
                    symbolName: "cloud.drizzle.fill",
                    title: "No dew point data available yet.",
                    message: "Calculate and save readings from the Calc tab to build your history."
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if records.isEmpty {
                EmptyStateView(
                    symbolName: "line.3.horizontal.decrease.circle",
                    title: "No matching tags",
                    message: "Try another filter or add tags when saving a reading."
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(records) { record in
                    HistoryReadingCell(
                        record: record,
                        dewPointText: store.formattedDewPoint(record.dewPoint),
                        temperatureText: store.formattedDewPoint(record.temperature),
                        expanded: viewModel.expandedIDs.contains(record.id),
                        bounce: viewModel.bounceToken > 0
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.toggleExpand(record.id)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            FeedbackService.tap()
                            store.deleteReading(id: record.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}
