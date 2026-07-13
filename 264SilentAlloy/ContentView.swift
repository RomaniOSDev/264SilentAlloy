import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore()
    @StateObject private var successBus = SuccessFeedbackBus()

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    FeedbackService.save()
                    store.completeOnboarding()
                }
            }
        }
        .environmentObject(store)
        .environmentObject(successBus)
        .preferredColorScheme(.dark)
        .background(Color.clear)
        .onAppear {
            UITableView.appearance().backgroundColor = .clear
            UITableViewCell.appearance().backgroundColor = .clear
            UICollectionView.appearance().backgroundColor = .clear
        }
    }
}

#Preview {
    ContentView()
}
