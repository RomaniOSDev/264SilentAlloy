import SwiftUI

struct TrackerView: View {
    let bottomInset: CGFloat

    @EnvironmentObject private var store: AppDataStore
    @EnvironmentObject private var successBus: SuccessFeedbackBus
    @StateObject private var viewModel = TrackerViewModel()

    var body: some View {
        NavigationStack {
            AppScreenShell {
                ScrollView {
                    VStack(spacing: 18) {
                        ScreenHeaderCell(
                            title: "Dew Point Calculator",
                            subtitle: store.activePreset.map { "Active preset: \($0.title)" } ?? "Temperature + humidity → actionable moisture insight",
                            symbolName: "function"
                        )

                        calculatorSection
                        resultSection
                        contextSection
                        actionsSection
                        trendSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, bottomInset)
                }
                .clearScrollBackground()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showAlertSheet) {
                AlertConfigSheet()
                    .environmentObject(store)
                    .environmentObject(successBus)
            }
            .onAppear {
                viewModel.syncFromLatest(store)
            }
        }
        .transparentScreenChrome()
    }

    private var calculatorSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabelCell(title: "Inputs", accessory: "Magnus")

                InputFieldCell(
                    title: "Air temperature (\(store.temperatureUnit.symbol))",
                    placeholder: "e.g. 22",
                    text: $viewModel.temperatureInput,
                    keyboard: .decimalPad,
                    shakeToken: viewModel.shakeTemperature
                )

                InputFieldCell(
                    title: "Relative humidity (%)",
                    placeholder: "e.g. 55",
                    text: $viewModel.humidityInput,
                    keyboard: .decimalPad,
                    shakeToken: viewModel.shakeHumidity
                )

                if let calculatorError = viewModel.calculatorError {
                    Text(calculatorError)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }

                Button {
                    _ = viewModel.calculate(store: store)
                } label: {
                    Text("Calculate")
                        .primaryButtonStyle()
                }
                .frame(minHeight: 44)
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let dew = viewModel.calculatedDewPointC {
            AppCard(accentBorder: true) {
                VStack(spacing: 16) {
                    HeroValueCell(
                        value: store.formattedDewPoint(dew),
                        caption: "Calculated dew point",
                        badge: viewModel.comfortZone?.title,
                        pulse: viewModel.pulseAccent
                    )

                    if let zone = viewModel.comfortZone, let mold = viewModel.moldRisk {
                        ComfortGaugeCell(
                            zone: zone,
                            moldRisk: mold,
                            tip: ComfortRiskEngine.hvacTip(dewPointC: dew)
                        )
                    }

                    if let advice = viewModel.comfortZone.map(DewPointCalculator.comfortAdvice) {
                        Text(advice)
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            if let message = viewModel.thresholdBreachMessage {
                AppCard {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(Color("AppAccent"))
                        Text(message)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                }
            }
        } else if let latest = store.latestReading {
            AppCard {
                VStack(spacing: 14) {
                    HeroValueCell(
                        value: store.formattedDewPoint(latest.dewPoint),
                        caption: "Latest saved reading",
                        badge: ComfortRiskEngine.comfortZone(dewPointC: latest.dewPoint).title
                    )
                    Text(ComfortRiskEngine.hvacTip(dewPointC: latest.dewPoint))
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                }
            }
        } else {
            EmptyStateView(
                symbolName: "thermometer.medium",
                title: "Awaiting data...",
                message: "Enter temperature and humidity to calculate dew point with the Magnus formula."
            )
        }
    }

    private var contextSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabelCell(title: "Notes & Context")

                    TextField("Optional note for this reading", text: $viewModel.noteInput)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DepthChrome.tileFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DepthChrome.hairline, lineWidth: 1)
                    )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                    ForEach(ReadingTag.allCases) { tag in
                        TagChipCell(
                            title: tag.rawValue.capitalized,
                            symbolName: tag.symbol,
                            isSelected: viewModel.selectedTags.contains(tag.rawValue)
                        ) {
                            viewModel.toggleTag(tag)
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.saveReading(store: store, successBus: successBus)
            } label: {
                Text(viewModel.showSaveConfirmation ? "Saved" : "Save Reading")
                    .primaryButtonStyle()
            }
            .frame(minHeight: 44)

            Button {
                FeedbackService.tap()
                viewModel.showAlertSheet = true
            } label: {
                SecondaryButtonLabel(title: "Set Alerts")
            }
            .frame(minHeight: 44)
        }
    }

    private var trendSection: some View {
        ChartCardCell(title: "Recent Trend") {
            Picker("Trend", selection: $viewModel.trendMode) {
                ForEach(TrackerViewModel.TrendMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.trendMode) { _ in
                FeedbackService.tap()
                viewModel.selectedPointIndex = nil
            }

            DewPointLineChart(
                points: viewModel.chartPoints(from: store),
                selectedIndex: viewModel.selectedPointIndex
            ) { index in
                viewModel.selectedPointIndex = index
            }
            .frame(height: 180)

            if let index = viewModel.selectedPointIndex {
                let points = viewModel.chartPoints(from: store)
                if points.indices.contains(index) {
                    let point = points[index]
                    Text("Selected \(String(format: "%.1f", point.1))\(store.temperatureUnit.symbol) · \(point.0.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }
}

struct AlertConfigSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @EnvironmentObject private var successBus: SuccessFeedbackBus
    @Environment(\.dismiss) private var dismiss

    @State private var highInput = ""
    @State private var lowInput = ""
    @State private var highError: String?
    @State private var lowError: String?
    @State private var shakeHigh = 0
    @State private var shakeLow = 0

    var body: some View {
        NavigationStack {
            AppScreenShell {
                ScrollView {
                    VStack(spacing: 18) {
                        ScreenHeaderCell(
                            title: "Set Alerts",
                            subtitle: "Custom thresholds for high and low dew point",
                            symbolName: "bell.badge.fill"
                        )

                        AppCard {
                            VStack(spacing: 14) {
                                InputFieldCell(
                                    title: "High alert (\(store.temperatureUnit.symbol))",
                                    placeholder: "e.g. 16",
                                    text: $highInput,
                                    keyboard: .decimalPad,
                                    shakeToken: shakeHigh
                                )
                                if let highError {
                                    Text(highError)
                                        .font(.caption)
                                        .foregroundStyle(Color.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                InputFieldCell(
                                    title: "Low alert (\(store.temperatureUnit.symbol))",
                                    placeholder: "e.g. 5",
                                    text: $lowInput,
                                    keyboard: .decimalPad,
                                    shakeToken: shakeLow
                                )
                                if let lowError {
                                    Text(lowError)
                                        .font(.caption)
                                        .foregroundStyle(Color.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        Button(action: save) {
                            Text("Save Alerts")
                                .primaryButtonStyle()
                        }
                        .frame(minHeight: 44)
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Set Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackService.tap()
                        dismiss()
                    }
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if let high = store.alertThresholds["high"] {
                    highInput = String(format: "%.1f", store.displayValue(high))
                }
                if let low = store.alertThresholds["low"] {
                    lowInput = String(format: "%.1f", store.displayValue(low))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        highError = nil
        lowError = nil

        var highValue: Double?
        var lowValue: Double?

        let trimmedHigh = highInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLow = lowInput.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedHigh.isEmpty {
            guard let value = Double(trimmedHigh.replacingOccurrences(of: ",", with: ".")) else {
                highError = "Enter a valid high threshold."
                FeedbackService.warning()
                withAnimation(.default) { shakeHigh += 1 }
                return
            }
            highValue = store.storageValue(fromDisplay: value)
        }

        if !trimmedLow.isEmpty {
            guard let value = Double(trimmedLow.replacingOccurrences(of: ",", with: ".")) else {
                lowError = "Enter a valid low threshold."
                FeedbackService.warning()
                withAnimation(.default) { shakeLow += 1 }
                return
            }
            lowValue = store.storageValue(fromDisplay: value)
        }

        if highValue == nil && lowValue == nil {
            highError = "Set at least one threshold."
            FeedbackService.warning()
            withAnimation(.default) { shakeHigh += 1 }
            return
        }

        if let highValue, let lowValue, lowValue > highValue {
            lowError = "Low threshold must be below high threshold."
            FeedbackService.warning()
            withAnimation(.default) { shakeLow += 1 }
            return
        }

        store.setAlertThresholds(high: highValue, low: lowValue)
        FeedbackService.alertSet()
        successBus.flashSuccess()
        dismiss()
    }
}
