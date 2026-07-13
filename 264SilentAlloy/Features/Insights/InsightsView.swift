import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = InsightsViewModel()
    @State private var selectedIndex: Int?
    @State private var analyzedOnce = false

    var body: some View {
        let baseRecords = viewModel.filteredRecords(from: store)
        let records: [DewPointRecord] = {
            guard store.historyTagFilter != "all" else { return baseRecords }
            return baseRecords.filter { $0.tags.contains(store.historyTagFilter) }
        }()
        let points = records.map { ($0.timestamp, store.displayValue($0.dewPoint)) }
        let riskDays = Set(
            records
                .filter { ComfortRiskEngine.isRiskDay(dewPointC: $0.dewPoint) }
                .map { Calendar.current.startOfDay(for: $0.timestamp) }
        ).count

        VStack(spacing: 16) {
            if store.dewPointHistory.isEmpty {
                EmptyStateView(
                    symbolName: "sun.max.fill",
                    title: "Track your first dew point!",
                    message: "No historical data yet. Begin tracking by calculating temperature and humidity."
                )
            } else {
                ChartCardCell(title: "Moisture Trend") {
                    DewPointLineChart(points: points, selectedIndex: selectedIndex) { index in
                        selectedIndex = index
                    }
                    .frame(height: 180)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 50)
                            .onEnded { value in
                                guard abs(value.translation.width) > abs(value.translation.height) * 1.2 else { return }
                                let frames = InsightsTimeFrame.allCases
                                guard let current = frames.firstIndex(of: viewModel.selectedFrame) else { return }
                                if value.translation.width < 0, current < frames.count - 1 {
                                    viewModel.applyFrame(frames[current + 1], store: store)
                                    markAnalyzed()
                                } else if value.translation.width > 0, current > 0 {
                                    viewModel.applyFrame(frames[current - 1], store: store)
                                    markAnalyzed()
                                }
                            }
                    )

                    Picker("Time Frame", selection: Binding(
                        get: { viewModel.selectedFrame },
                        set: { newValue in
                            viewModel.applyFrame(newValue, store: store)
                            markAnalyzed()
                        }
                    )) {
                        ForEach(InsightsTimeFrame.allCases) { frame in
                            Text(frame.rawValue).tag(frame)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MetricTileCell(
                        title: "Average",
                        value: viewModel.average(from: records).map(store.formattedDewPoint) ?? "—",
                        symbolName: "chart.bar",
                        emphasize: true
                    )
                    MetricTileCell(
                        title: "Peak",
                        value: viewModel.peak(from: records).map(store.formattedDewPoint) ?? "—",
                        symbolName: "arrow.up.right"
                    )
                    MetricTileCell(
                        title: "Lowest",
                        value: viewModel.lowest(from: records).map(store.formattedDewPoint) ?? "—",
                        symbolName: "arrow.down.right"
                    )
                    MetricTileCell(
                        title: "Risk days",
                        value: "\(riskDays)",
                        symbolName: "exclamationmark.triangle"
                    )
                }

                AppCard {
                    StatRowCell(
                        title: "Average variation",
                        value: viewModel.variation(from: records).map(store.formattedDewPoint) ?? "—",
                        symbolName: "waveform.path"
                    )
                }
            }
        }
        .onAppear {
            viewModel.sync(from: store)
        }
    }

    private func markAnalyzed() {
        if !analyzedOnce {
            analyzedOnce = true
            store.markInsightsReviewed()
        }
        FeedbackService.insightsUpdated()
    }
}

struct TrendsHubView: View {
    let bottomInset: CGFloat

    @EnvironmentObject private var store: AppDataStore
    @StateObject private var historyViewModel = HistoryViewModel()
    @State private var segment = 0

    private var filterOptions: [String] {
        ["all"] + ReadingTag.allCases.map(\.rawValue)
    }

    var body: some View {
        NavigationStack {
            AppScreenShell {
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        ScreenHeaderCell(
                            title: "Trends",
                            subtitle: "History, insights, and weekly reports",
                            symbolName: "chart.xyaxis.line"
                        )

                        Picker("Section", selection: $segment) {
                            Text("History").tag(0)
                            Text("Insights").tag(1)
                            Text("Report").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: segment) { _ in
                            FeedbackService.tap()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    if segment == 0 {
                        historyContent
                    } else if segment == 1 {
                        ScrollView {
                            VStack(spacing: 16) {
                                tagFilterBar
                                InsightsView()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, bottomInset)
                        }
                        .clearScrollBackground()
                    } else {
                        ScrollView {
                            ReportExportView()
                                .padding(.horizontal, 20)
                                .padding(.bottom, bottomInset)
                        }
                        .clearScrollBackground()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .transparentScreenChrome()
    }

    private var tagFilterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabelCell(title: "Filter by tag")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filterOptions, id: \.self) { option in
                        FilterChipCell(
                            title: option == "all" ? "All" : option.capitalized,
                            isSelected: store.historyTagFilter == option
                        ) {
                            FeedbackService.tap()
                            store.historyTagFilter = option
                        }
                    }
                }
            }
        }
    }

    private var historyContent: some View {
        List {
            Section {
                tagFilterBar
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                HistoryListSection(viewModel: historyViewModel)
            }

            Section {
                Button {
                    historyViewModel.refresh(store: store)
                } label: {
                    Text("Refresh Data")
                        .primaryButtonStyle()
                }
                .disabled(store.sortedHistory.isEmpty)
                .opacity(store.sortedHistory.isEmpty ? 0.5 : 1)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if let lastRefreshed = store.lastRefreshed {
                    Text("Last refreshed \(lastRefreshed.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Color.clear
                    .frame(height: bottomInset)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .clearListBackground()
    }
}
