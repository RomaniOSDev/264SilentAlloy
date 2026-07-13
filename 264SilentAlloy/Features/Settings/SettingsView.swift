import SwiftUI
import StoreKit

struct SettingsView: View {
    let bottomInset: CGFloat

    @EnvironmentObject private var store: AppDataStore
    @State private var showResetConfirm = false
    @State private var showMilestones = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            AppScreenShell {
                ScrollView {
                    VStack(spacing: 18) {
                        ScreenHeaderCell(
                            title: "Settings",
                            subtitle: "Stats, units, milestones, and data controls",
                            symbolName: "gearshape.fill"
                        )

                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabelCell(title: "Your Stats")
                                StatRowCell(title: "Entries created", value: "\(store.itemsCreated)", symbolName: "square.stack.3d.up")
                                StatRowCell(title: "Minutes used", value: "\(store.totalMinutesUsed)", symbolName: "clock")
                                StatRowCell(title: "Current streak", value: "\(store.streakDays) days", symbolName: "flame")
                                StatRowCell(title: "Calculations", value: "\(store.calculationsPerformed)", symbolName: "function")
                                StatRowCell(title: "Reports exported", value: "\(store.reportsExported)", symbolName: "square.and.arrow.up")
                                StatRowCell(title: "Sessions completed", value: "\(store.totalSessionsCompleted)", symbolName: "checkmark.circle")
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionLabelCell(title: "Temperature Unit")
                                Picker("Unit", selection: Binding(
                                    get: { store.temperatureUnit },
                                    set: { newValue in
                                        FeedbackService.tap()
                                        store.temperatureUnit = newValue
                                    }
                                )) {
                                    Text("°C").tag(TemperatureUnit.celsius)
                                    Text("°F").tag(TemperatureUnit.fahrenheit)
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        VStack(spacing: 10) {
                            SettingsRowCell(title: "Rate Us", symbolName: "star.fill") {
                                FeedbackService.tap()
                                rateApp()
                            }
                            SettingsRowCell(title: "Privacy Policy", symbolName: "hand.raised.fill") {
                                FeedbackService.tap()
                                openLink(.privacyPolicy)
                            }
                            SettingsRowCell(title: "Terms of Use", symbolName: "doc.text") {
                                FeedbackService.tap()
                                openLink(.termsOfUse)
                            }
                            SettingsRowCell(title: "Milestones", symbolName: "flag.fill") {
                                FeedbackService.tap()
                                showMilestones = true
                            }
                            SettingsRowCell(title: "Reset All Data", symbolName: "trash", destructive: true) {
                                FeedbackService.tap()
                                showResetConfirm = true
                            }
                        }

                        Text("Version \(appVersion)")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, bottomInset)
                }
                .clearScrollBackground()
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showMilestones) {
                NavigationStack {
                    AppScreenShell {
                        MilestonesView(bottomInset: 24)
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                FeedbackService.tap()
                                showMilestones = false
                            }
                        }
                    }
                    .toolbarBackground(Color("AppSurface"), for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .preferredColorScheme(.dark)
                .environmentObject(store)
            }
            .alert("Reset All Data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {
                    FeedbackService.tap()
                }
                Button("Reset", role: .destructive) {
                    FeedbackService.warning()
                    store.resetAllData()
                }
            } message: {
                Text("This permanently clears all readings, alerts, streaks, and milestones stored on this device.")
            }
        }
        .transparentScreenChrome()
    }

    private func openLink(_ link: AppLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
