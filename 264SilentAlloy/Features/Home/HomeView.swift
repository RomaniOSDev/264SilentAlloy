import SwiftUI

struct HomeView: View {
    let bottomInset: CGFloat
    var onOpenCalculator: (() -> Void)? = nil
    var onOpenTrends: (() -> Void)? = nil

    @EnvironmentObject private var store: AppDataStore
    @EnvironmentObject private var successBus: SuccessFeedbackBus
    @State private var appearWidgets = false
    @State private var showDecisionSheet = false
    @State private var showPresetsSheet = false
    @State private var showGuidesHub = false

    private var latest: DewPointRecord? { store.latestReading }
    private var weekSummary: ReportExporter.WeekSummary {
        ReportExporter.weekSummary(from: store.dewPointHistory)
    }

    var body: some View {
        NavigationStack {
            AppScreenShell {
                ScrollView {
                    VStack(spacing: 18) {
                        heroWidget
                        quickActionsRow
                        statusWidgetsRow
                        decisionWidget
                        weekWidget
                        recentWidget
                        milestonesTeaser
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, bottomInset)
                    .opacity(appearWidgets ? 1 : 0)
                    .offset(y: appearWidgets ? 0 : 12)
                }
                .clearScrollBackground()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDecisionSheet) {
                NavigationStack {
                    AppScreenShell {
                        ScrollView {
                            DecisionHelperView()
                                .padding(20)
                        }
                        .clearScrollBackground()
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                FeedbackService.tap()
                                showDecisionSheet = false
                            }
                        }
                    }
                    .toolbarBackground(Color("AppSurface"), for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .preferredColorScheme(.dark)
                .environmentObject(store)
            }
            .sheet(isPresented: $showPresetsSheet) {
                NavigationStack {
                    AppScreenShell {
                        ScrollView {
                            PresetsView()
                                .padding(20)
                        }
                        .clearScrollBackground()
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                FeedbackService.tap()
                                showPresetsSheet = false
                            }
                        }
                    }
                    .toolbarBackground(Color("AppSurface"), for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .preferredColorScheme(.dark)
                .environmentObject(store)
                .environmentObject(successBus)
            }
            .fullScreenCover(isPresented: $showGuidesHub) {
                ZStack(alignment: .topTrailing) {
                    GuidesHubView(bottomInset: 24)
                        .environmentObject(store)
                        .environmentObject(successBus)

                    Button {
                        FeedbackService.tap()
                        showGuidesHub = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(16)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }
                .preferredColorScheme(.dark)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    appearWidgets = true
                }
            }
        }
        .transparentScreenChrome()
    }

    // MARK: - Hero

    private var heroWidget: some View {
        ZStack(alignment: .bottomLeading) {
            Image("home_hero_moisture")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color("AppBackground").opacity(0.15),
                            Color("AppBackground").opacity(0.88)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 10) {
                Text(greetingText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))

                if let latest {
                    Text(store.formattedDewPoint(latest.dewPoint))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    HStack(spacing: 8) {
                        StatusPillCell(
                            title: ComfortRiskEngine.comfortZone(dewPointC: latest.dewPoint).title,
                            tone: .positive
                        )
                        StatusPillCell(
                            title: "Mold \(ComfortRiskEngine.moldRisk(dewPointC: latest.dewPoint).title)",
                            tone: ComfortRiskEngine.moldRisk(dewPointC: latest.dewPoint) == .high ? .negative : .caution
                        )
                    }

                    Text(latest.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    Text("Ready to measure")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text("Calculate dew point from temperature and humidity.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(DepthChrome.accentHairline, lineWidth: 1.2)
        )
        .softShadow(.floating)
    }

    // MARK: - Quick actions

    private var quickActionsRow: some View {
        HStack(spacing: 10) {
            HomeActionWidget(
                title: "Calculate",
                symbol: "function",
                imageName: nil
            ) {
                FeedbackService.tap()
                onOpenCalculator?()
            }

            HomeActionWidget(
                title: "Should I…?",
                symbol: "questionmark.circle",
                imageName: nil
            ) {
                FeedbackService.tap()
                showDecisionSheet = true
            }

            HomeActionWidget(
                title: "Guides",
                symbol: "lightbulb.fill",
                imageName: nil
            ) {
                FeedbackService.tap()
                showGuidesHub = true
            }

            HomeActionWidget(
                title: "Trends",
                symbol: "chart.xyaxis.line",
                imageName: nil
            ) {
                FeedbackService.tap()
                onOpenTrends?()
            }
        }
    }

    // MARK: - Status widgets

    private var statusWidgetsRow: some View {
        HStack(spacing: 12) {
            HomeImageWidget(
                imageName: "home_widget_gauge",
                title: "Dew Point",
                value: latest.map { store.formattedDewPoint($0.dewPoint) } ?? "—",
                detail: latest == nil ? "No reading yet" : "Latest saved"
            ) {
                FeedbackService.tap()
                onOpenCalculator?()
            }

            HomeImageWidget(
                imageName: "home_widget_comfort",
                title: "Comfort",
                value: latest.map { ComfortRiskEngine.comfortZone(dewPointC: $0.dewPoint).title } ?? "—",
                detail: latest.map { ComfortRiskEngine.hvacTip(dewPointC: $0.dewPoint) } ?? "Save a reading to see tips"
            ) {
                FeedbackService.tap()
                showDecisionSheet = true
            }
        }
    }

    // MARK: - Decision preview

    private var decisionWidget: some View {
        let dew = latest?.dewPoint
        let result: (DecisionVerdict, String)? = dew.map {
            DecisionHelper.evaluate(
                questionId: "windows",
                dewPointC: $0,
                highThreshold: store.alertThresholds["high"],
                lowThreshold: store.alertThresholds["low"]
            )
        }

        return AppCard(accentBorder: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionLabelCell(title: "Right now")
                    Spacer(minLength: 0)
                    Button {
                        FeedbackService.tap()
                        showDecisionSheet = true
                    } label: {
                        Text("Open")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                            .frame(minHeight: 32)
                    }
                    .buttonStyle(.plain)
                }

                Text("Open windows now?")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                if let result {
                    VerdictResultCell(verdict: result.0, explanation: result.1)
                } else {
                    Text("Add a reading to unlock live recommendations.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }

    // MARK: - Week

    private var weekWidget: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionLabelCell(title: "This week", accessory: weekSummary.hasData ? "\(weekSummary.readings.count) entries" : nil)
                    Spacer(minLength: 0)
                    Button {
                        FeedbackService.tap()
                        onOpenTrends?()
                    } label: {
                        Text("Report")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                            .frame(minHeight: 32)
                    }
                    .buttonStyle(.plain)
                }

                if weekSummary.hasData {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MetricTileCell(
                            title: "Average",
                            value: weekSummary.average.map(store.formattedDewPoint) ?? "—",
                            symbolName: "chart.bar",
                            emphasize: true
                        )
                        MetricTileCell(
                            title: "Risk days",
                            value: "\(weekSummary.riskDays)",
                            symbolName: "exclamationmark.triangle"
                        )
                        MetricTileCell(
                            title: "Peak",
                            value: weekSummary.peak.map(store.formattedDewPoint) ?? "—",
                            symbolName: "arrow.up.right"
                        )
                        MetricTileCell(
                            title: "Lowest",
                            value: weekSummary.lowest.map(store.formattedDewPoint) ?? "—",
                            symbolName: "arrow.down.right"
                        )
                    }
                } else {
                    Text("Your weekly moisture widgets will fill in after the first few readings.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                if let preset = store.activePreset {
                    HStack(spacing: 10) {
                        Image(systemName: preset.symbolName)
                            .foregroundStyle(Color("AppAccent"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Active preset")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text(preset.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                        Spacer(minLength: 0)
                        StatusPillCell(title: "On", tone: .positive)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DepthChrome.tileFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DepthChrome.hairline, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Recent

    private var recentWidget: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabelCell(title: "Recent readings")

                if store.sortedHistory.isEmpty {
                    Text("No entries yet. Use Calculate to create your first dew point reading.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(store.sortedHistory.prefix(3)) { record in
                        Button {
                            FeedbackService.tap()
                            onOpenTrends?()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color("AppBackground"))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "drop.fill")
                                        .foregroundStyle(Color("AppAccent"))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.formattedDewPoint(record.dewPoint))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                                Spacer(minLength: 0)
                                StatusPillCell(
                                    title: ComfortRiskEngine.comfortZone(dewPointC: record.dewPoint).title,
                                    tone: .neutral
                                )
                            }
                            .padding(.vertical, 4)
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(.plain)

                        if record.id != store.sortedHistory.prefix(3).last?.id {
                            Divider().overlay(Color("AppTextSecondary").opacity(0.2))
                        }
                    }
                }
            }
        }
    }

    private var milestonesTeaser: some View {
        AppCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color("AppBackground"))
                        .frame(width: 44, height: 44)
                    Image(systemName: "flag.fill")
                        .foregroundStyle(Color("AppAccent"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Milestones")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("\(store.achievementsUnlocked.count)/\(MilestoneCatalog.all.count) reached")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                Spacer(minLength: 0)
                ProgressView(
                    value: Double(store.achievementsUnlocked.count),
                    total: Double(max(MilestoneCatalog.all.count, 1))
                )
                .tint(Color("AppAccent"))
                .frame(width: 56)
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning moisture check"
        case 12..<17: return "Afternoon overview"
        case 17..<22: return "Evening conditions"
        default: return "Overnight overview"
        }
    }
}

private struct HomeActionWidget: View {
    let title: String
    let symbol: String
    let imageName: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DepthChrome.cardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(DepthChrome.hairline, lineWidth: 1)
                        )
                        .frame(width: 54, height: 54)
                        .softShadow(.control)
                    if let imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 54, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else {
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color("AppAccent"))
                    }
                }
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
        }
        .buttonStyle(.plain)
    }
}

private struct HomeImageWidget: View {
    let imageName: String
    let title: String
    let value: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 92)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [Color.clear, Color("AppSurface").opacity(0.95)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppTextSecondary"))
                    Text(value)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(DepthChrome.cardFill)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(DepthChrome.hairline, lineWidth: 1)
            )
            .softShadow(.card)
        }
        .buttonStyle(.plain)
    }
}
