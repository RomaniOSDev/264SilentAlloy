import SwiftUI
import Combine

enum AppTab: Int, CaseIterable {
    case home
    case tracker
    case trends
    case settings

    var title: String {
        switch self {
        case .home: return "Home"
        case .tracker: return "Calc"
        case .trends: return "Trends"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .tracker: return "function"
        case .trends: return "chart.xyaxis.line"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @State private var pressedTab: AppTab?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button {
                    FeedbackService.tap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selectedTab == tab ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selectedTab == tab {
                                Capsule().fill(DepthChrome.primaryButtonFill)
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .scaleEffect(pressedTab == tab ? 0.95 : 1)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in pressedTab = tab }
                        .onEnded { _ in pressedTab = nil }
                )
                .frame(minHeight: 44)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DepthChrome.elevatedFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(DepthChrome.hairline, lineWidth: 1)
                )
        )
        .softShadow(.floating)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @EnvironmentObject private var successBus: SuccessFeedbackBus
    @State private var selectedTab: AppTab = .home
    @State private var bannerMilestone: MilestoneDefinition?
    @State private var bannerVisible = false

    private let tabBarClearance: CGFloat = 96

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackgroundView()

            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        bottomInset: tabBarClearance,
                        onOpenCalculator: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedTab = .tracker
                            }
                        },
                        onOpenTrends: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedTab = .trends
                            }
                        }
                    )
                case .tracker:
                    TrackerView(bottomInset: tabBarClearance)
                case .trends:
                    TrendsHubView(bottomInset: tabBarClearance)
                case .settings:
                    SettingsView(bottomInset: tabBarClearance)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)

            CustomTabBar(selectedTab: $selectedTab)

            if bannerVisible, let bannerMilestone {
                VStack {
                    AchievementBannerView(
                        title: bannerMilestone.title,
                        detail: bannerMilestone.detail,
                        symbolName: bannerMilestone.symbolName
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 8)
                .allowsHitTesting(false)
            }

            SuccessOverlayHost()
        }
        .onAppear {
            store.startSessionTracking()
            presentNextMilestoneIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { _ in
            presentNextMilestoneIfNeeded()
        }
        .onChange(of: store.pendingAchievementIds) { _ in
            presentNextMilestoneIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            store.flushSessionMinutes()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            store.startSessionTracking()
        }
    }

    private func presentNextMilestoneIfNeeded() {
        guard !bannerVisible else { return }
        guard let next = store.consumeNextPendingAchievement() else { return }
        FeedbackService.achievement()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            bannerMilestone = next
            bannerVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                bannerVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                bannerMilestone = nil
                presentNextMilestoneIfNeeded()
            }
        }
    }
}

private struct SuccessOverlayHost: View {
    @EnvironmentObject private var successBus: SuccessFeedbackBus

    var body: some View {
        SuccessCheckmarkOverlay(isVisible: successBus.showCheckmark)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: successBus.showCheckmark)
    }
}

@MainActor
final class SuccessFeedbackBus: ObservableObject {
    @Published var showCheckmark = false

    func flashSuccess() {
        FeedbackService.success()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCheckmark = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showCheckmark = false
            }
        }
    }
}
