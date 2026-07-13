import SwiftUI
import Combine

enum InsightsTimeFrame: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
}

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var selectedFrame: InsightsTimeFrame = .week

    func sync(from store: AppDataStore) {
        if let frame = InsightsTimeFrame(rawValue: store.selectedTimeFrame) {
            selectedFrame = frame
        }
    }

    func applyFrame(_ frame: InsightsTimeFrame, store: AppDataStore) {
        selectedFrame = frame
        store.selectedTimeFrame = frame.rawValue
        FeedbackService.tap()
    }

    func filteredRecords(from store: AppDataStore) -> [DewPointRecord] {
        let calendar = Calendar.current
        let now = Date()
        let cutoff: Date
        switch selectedFrame {
        case .day:
            cutoff = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .week:
            cutoff = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            cutoff = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            cutoff = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        return store.dewPointHistory
            .filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp < $1.timestamp }
    }

    func average(from records: [DewPointRecord]) -> Double? {
        guard !records.isEmpty else { return nil }
        return records.map(\.dewPoint).reduce(0, +) / Double(records.count)
    }

    func peak(from records: [DewPointRecord]) -> Double? {
        records.map(\.dewPoint).max()
    }

    func lowest(from records: [DewPointRecord]) -> Double? {
        records.map(\.dewPoint).min()
    }

    func variation(from records: [DewPointRecord]) -> Double? {
        guard let peak = peak(from: records), let lowest = lowest(from: records) else { return nil }
        return peak - lowest
    }
}
