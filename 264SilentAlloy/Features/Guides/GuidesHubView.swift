import SwiftUI

struct GuidesHubView: View {
    let bottomInset: CGFloat

    @State private var segment = 0

    var body: some View {
        NavigationStack {
            AppScreenShell {
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        ScreenHeaderCell(
                            title: "Guides",
                            subtitle: "Decisions and scenario presets for real moisture choices",
                            symbolName: "lightbulb.fill"
                        )

                        Picker("Section", selection: $segment) {
                            Text("Should I…?").tag(0)
                            Text("Presets").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: segment) { _ in
                            FeedbackService.tap()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    ScrollView {
                        Group {
                            if segment == 0 {
                                DecisionHelperView()
                            } else {
                                PresetsView()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, bottomInset)
                    }
                    .clearScrollBackground()
                }
            }
            .navigationBarHidden(true)
        }
        .transparentScreenChrome()
    }
}

struct DecisionHelperView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedQuestionId = DecisionHelper.questions[0].id
    @State private var verdict: DecisionVerdict?
    @State private var explanation = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if store.latestReading == nil {
                EmptyStateView(
                    symbolName: "questionmark.circle",
                    title: "No reading yet",
                    message: "Calculate and save a dew point reading first to get recommendations."
                )
            } else {
                if let latest = store.latestReading {
                    AppCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Using latest reading")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Text(store.formattedDewPoint(latest.dewPoint))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                            Spacer(minLength: 0)
                            StatusPillCell(
                                title: ComfortRiskEngine.comfortZone(dewPointC: latest.dewPoint).title,
                                tone: .positive
                            )
                        }
                    }
                }

                SectionLabelCell(title: "Questions")

                ForEach(DecisionHelper.questions) { question in
                    DecisionOptionCell(
                        title: question.title,
                        symbolName: question.symbolName,
                        isSelected: selectedQuestionId == question.id
                    ) {
                        FeedbackService.tap()
                        selectedQuestionId = question.id
                        evaluate()
                    }
                }

                if let verdict {
                    AppCard(accentBorder: true) {
                        VerdictResultCell(verdict: verdict, explanation: explanation)
                    }
                }

                Button {
                    evaluate(register: true)
                } label: {
                    Text("Refresh Recommendation")
                        .primaryButtonStyle()
                }
                .frame(minHeight: 44)
            }
        }
        .onAppear {
            if store.latestReading != nil {
                evaluate(register: false)
            }
        }
    }

    private func evaluate(register: Bool = true) {
        guard let latest = store.latestReading else { return }
        let result = DecisionHelper.evaluate(
            questionId: selectedQuestionId,
            dewPointC: latest.dewPoint,
            highThreshold: store.alertThresholds["high"],
            lowThreshold: store.alertThresholds["low"]
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            verdict = result.0
            explanation = result.1
        }
        if register {
            store.registerDecisionCheck()
            FeedbackService.insightsUpdated()
        }
    }
}

struct PresetsView: View {
    @EnvironmentObject private var store: AppDataStore
    @EnvironmentObject private var successBus: SuccessFeedbackBus

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apply a profile to set alert thresholds and get focused tips.")
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))

            ForEach(ScenarioCatalog.all) { preset in
                PresetCardCell(
                    preset: preset,
                    rangeText: "Alerts \(store.formattedDewPoint(preset.lowThresholdC)) – \(store.formattedDewPoint(preset.highThresholdC))",
                    isApplied: store.activePresetId == preset.id
                ) {
                    store.applyPreset(preset)
                    FeedbackService.save()
                    successBus.flashSuccess()
                }
            }
        }
    }
}
