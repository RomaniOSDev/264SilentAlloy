import SwiftUI
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var expandedIDs: Set<UUID> = []
    @Published var bounceToken = 0

    func toggleExpand(_ id: UUID) {
        FeedbackService.tap()
        if expandedIDs.contains(id) {
            expandedIDs.remove(id)
        } else {
            expandedIDs.insert(id)
        }
    }

    func refresh(store: AppDataStore) {
        store.markRefreshed()
        FeedbackService.softRefresh()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
            bounceToken += 1
        }
    }
}
