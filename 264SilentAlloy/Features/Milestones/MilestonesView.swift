import SwiftUI

struct MilestonesView: View {
    let bottomInset: CGFloat

    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        AppScreenShell {
            ScrollView {
                VStack(spacing: 18) {
                    ScreenHeaderCell(
                        title: "Milestones",
                        subtitle: "Progress from real tracking actions",
                        symbolName: "flag.fill"
                    )

                    AppCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabelCell(
                                title: "Progress",
                                accessory: "\(store.achievementsUnlocked.count)/\(MilestoneCatalog.all.count)"
                            )
                            StatRowCell(title: "Readings saved", value: "\(store.itemsCreated)", symbolName: "square.stack.3d.up")
                            StatRowCell(title: "Calculations", value: "\(store.calculationsPerformed)", symbolName: "function")
                            StatRowCell(title: "Reports exported", value: "\(store.reportsExported)", symbolName: "square.and.arrow.up")
                            StatRowCell(title: "Risk checks", value: "\(store.consecutiveRiskChecks)", symbolName: "eye")
                        }
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(MilestoneCatalog.all) { milestone in
                            MilestoneCardCell(
                                milestone: milestone,
                                isReached: store.achievementsUnlocked[milestone.id] != nil
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, bottomInset)
            }
            .clearScrollBackground()
        }
    }
}
