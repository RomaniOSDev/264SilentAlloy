import SwiftUI
import Combine

@MainActor
final class TrackerViewModel: ObservableObject {
    @Published var temperatureInput = ""
    @Published var humidityInput = ""
    @Published var calculatedDewPointC: Double?
    @Published var calculatorError: String?
    @Published var shakeTemperature = 0
    @Published var shakeHumidity = 0

    @Published var noteInput = ""
    @Published var selectedTags: Set<String> = []

    @Published var trendMode: TrendMode = .daily
    @Published var selectedPointIndex: Int?
    @Published var showAlertSheet = false
    @Published var thresholdBreachMessage: String?
    @Published var pulseAccent = false
    @Published var showSaveConfirmation = false

    enum TrendMode: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
    }

    var comfortZone: ComfortZone? {
        guard let calculatedDewPointC else { return nil }
        return ComfortRiskEngine.comfortZone(dewPointC: calculatedDewPointC)
    }

    var moldRisk: MoldRiskLevel? {
        guard let calculatedDewPointC else { return nil }
        return ComfortRiskEngine.moldRisk(dewPointC: calculatedDewPointC)
    }

    func chartPoints(from store: AppDataStore) -> [(Date, Double)] {
        let calendar = Calendar.current
        let now = Date()
        let cutoff: Date
        switch trendMode {
        case .daily:
            cutoff = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
        case .weekly:
            cutoff = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        }

        return store.dewPointHistory
            .filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp < $1.timestamp }
            .map { ($0.timestamp, store.displayValue($0.dewPoint)) }
    }

    @discardableResult
    func calculate(store: AppDataStore) -> Bool {
        calculatorError = nil

        guard let tempDisplay = Double(temperatureInput.replacingOccurrences(of: ",", with: ".")),
              tempDisplay >= -40, tempDisplay <= 140 else {
            calculatorError = "Enter a valid temperature between -40 and 140."
            FeedbackService.warning()
            withAnimation(.default) { shakeTemperature += 1 }
            return false
        }

        guard let humidity = Double(humidityInput.replacingOccurrences(of: ",", with: ".")),
              humidity > 0, humidity <= 100 else {
            calculatorError = "Enter relative humidity between 1 and 100%."
            FeedbackService.warning()
            withAnimation(.default) { shakeHumidity += 1 }
            return false
        }

        let tempC = store.storageValue(fromDisplay: tempDisplay)
        guard let dew = DewPointCalculator.dewPointCelsius(temperatureC: tempC, humidityPercent: humidity) else {
            calculatorError = "Could not calculate dew point from these values."
            FeedbackService.warning()
            return false
        }

        calculatedDewPointC = dew
        store.registerCalculation()
        FeedbackService.tap()
        evaluateThresholds(dewPoint: dew, store: store)
        return true
    }

    func saveReading(store: AppDataStore, successBus: SuccessFeedbackBus) {
        if calculatedDewPointC == nil {
            guard calculate(store: store) else { return }
        }
        guard let dew = calculatedDewPointC else { return }
        guard let tempDisplay = Double(temperatureInput.replacingOccurrences(of: ",", with: ".")),
              let humidity = Double(humidityInput.replacingOccurrences(of: ",", with: ".")) else {
            calculatorError = "Enter temperature and humidity before saving."
            FeedbackService.warning()
            return
        }

        let tempC = store.storageValue(fromDisplay: tempDisplay)
        store.addReading(
            dewPoint: dew,
            temperature: tempC,
            humidity: humidity,
            tags: Array(selectedTags).sorted(),
            note: noteInput.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        evaluateThresholds(dewPoint: dew, store: store)
        successBus.flashSuccess()
        showSaveConfirmation = true
        withAnimation(.easeInOut(duration: 0.4)) { pulseAccent = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.3)) { self.pulseAccent = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.showSaveConfirmation = false
        }
    }

    func toggleTag(_ tag: ReadingTag) {
        FeedbackService.tap()
        if selectedTags.contains(tag.rawValue) {
            selectedTags.remove(tag.rawValue)
        } else {
            selectedTags.insert(tag.rawValue)
        }
    }

    func evaluateThresholds(dewPoint: Double, store: AppDataStore) {
        if let high = store.alertThresholds["high"], dewPoint >= high {
            thresholdBreachMessage = "High dew point threshold reached."
        } else if let low = store.alertThresholds["low"], dewPoint <= low {
            thresholdBreachMessage = "Low dew point threshold reached."
        } else {
            thresholdBreachMessage = nil
        }
    }

    func syncFromLatest(_ store: AppDataStore) {
        guard calculatedDewPointC == nil, let latest = store.latestReading else { return }
        calculatedDewPointC = latest.dewPoint
        evaluateThresholds(dewPoint: latest.dewPoint, store: store)
    }
}
