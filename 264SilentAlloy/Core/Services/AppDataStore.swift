import Foundation
import Combine

@MainActor
final class AppDataStore: ObservableObject {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let totalSessionsCompleted = "totalSessionsCompleted"
        static let totalMinutesUsed = "totalMinutesUsed"
        static let streakDays = "streakDays"
        static let lastActivityDate = "lastActivityDate"
        static let achievementsUnlocked = "achievementsUnlocked"
        static let itemsCreated = "itemsCreated"
        static let dewPointHistory = "dewPointHistory"
        static let alertThresholds = "alertThresholds"
        static let selectedTimeFrame = "selectedTimeFrame"
        static let lastRefreshed = "lastRefreshed"
        static let temperatureUnit = "temperatureUnit"
        static let sessionStartDate = "sessionStartDate"
        static let activePresetId = "activePresetId"
        static let calculationsPerformed = "calculationsPerformed"
        static let presetsApplied = "presetsApplied"
        static let decisionsChecked = "decisionsChecked"
        static let reportsExported = "reportsExported"
        static let consecutiveRiskChecks = "consecutiveRiskChecks"
        static let historyTagFilter = "historyTagFilter"
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published var totalSessionsCompleted: Int {
        didSet { defaults.set(totalSessionsCompleted, forKey: Keys.totalSessionsCompleted) }
    }

    @Published var totalMinutesUsed: Int {
        didSet { defaults.set(totalMinutesUsed, forKey: Keys.totalMinutesUsed) }
    }

    @Published var streakDays: Int {
        didSet { defaults.set(streakDays, forKey: Keys.streakDays) }
    }

    @Published var lastActivityDate: Date? {
        didSet {
            if let lastActivityDate {
                defaults.set(lastActivityDate.timeIntervalSince1970, forKey: Keys.lastActivityDate)
            } else {
                defaults.removeObject(forKey: Keys.lastActivityDate)
            }
        }
    }

    @Published var achievementsUnlocked: [String: Date] {
        didSet { saveCodable(achievementsUnlocked, key: Keys.achievementsUnlocked) }
    }

    @Published var itemsCreated: Int {
        didSet { defaults.set(itemsCreated, forKey: Keys.itemsCreated) }
    }

    @Published var dewPointHistory: [DewPointRecord] {
        didSet { saveCodable(dewPointHistory, key: Keys.dewPointHistory) }
    }

    @Published var alertThresholds: [String: Double] {
        didSet { saveCodable(alertThresholds, key: Keys.alertThresholds) }
    }

    @Published var selectedTimeFrame: String {
        didSet { defaults.set(selectedTimeFrame, forKey: Keys.selectedTimeFrame) }
    }

    @Published var lastRefreshed: Date? {
        didSet {
            if let lastRefreshed {
                defaults.set(lastRefreshed.timeIntervalSince1970, forKey: Keys.lastRefreshed)
            } else {
                defaults.removeObject(forKey: Keys.lastRefreshed)
            }
        }
    }

    @Published var temperatureUnit: TemperatureUnit {
        didSet { defaults.set(temperatureUnit.rawValue, forKey: Keys.temperatureUnit) }
    }

    @Published var activePresetId: String? {
        didSet {
            if let activePresetId {
                defaults.set(activePresetId, forKey: Keys.activePresetId)
            } else {
                defaults.removeObject(forKey: Keys.activePresetId)
            }
        }
    }

    @Published var calculationsPerformed: Int {
        didSet { defaults.set(calculationsPerformed, forKey: Keys.calculationsPerformed) }
    }

    @Published var presetsApplied: Int {
        didSet { defaults.set(presetsApplied, forKey: Keys.presetsApplied) }
    }

    @Published var decisionsChecked: Int {
        didSet { defaults.set(decisionsChecked, forKey: Keys.decisionsChecked) }
    }

    @Published var reportsExported: Int {
        didSet { defaults.set(reportsExported, forKey: Keys.reportsExported) }
    }

    @Published var consecutiveRiskChecks: Int {
        didSet { defaults.set(consecutiveRiskChecks, forKey: Keys.consecutiveRiskChecks) }
    }

    @Published var historyTagFilter: String {
        didSet { defaults.set(historyTagFilter, forKey: Keys.historyTagFilter) }
    }

    @Published var pendingAchievementIds: [String] = []

    private var sessionStartDate: Date?

    init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        itemsCreated = defaults.integer(forKey: Keys.itemsCreated)
        selectedTimeFrame = defaults.string(forKey: Keys.selectedTimeFrame) ?? "Week"
        calculationsPerformed = defaults.integer(forKey: Keys.calculationsPerformed)
        presetsApplied = defaults.integer(forKey: Keys.presetsApplied)
        decisionsChecked = defaults.integer(forKey: Keys.decisionsChecked)
        reportsExported = defaults.integer(forKey: Keys.reportsExported)
        consecutiveRiskChecks = defaults.integer(forKey: Keys.consecutiveRiskChecks)
        historyTagFilter = defaults.string(forKey: Keys.historyTagFilter) ?? "all"
        activePresetId = defaults.string(forKey: Keys.activePresetId)

        if let interval = defaults.object(forKey: Keys.lastActivityDate) as? Double {
            lastActivityDate = Date(timeIntervalSince1970: interval)
        } else {
            lastActivityDate = nil
        }

        if let interval = defaults.object(forKey: Keys.lastRefreshed) as? Double {
            lastRefreshed = Date(timeIntervalSince1970: interval)
        } else {
            lastRefreshed = nil
        }

        achievementsUnlocked = Self.loadCodable([String: Date].self, key: Keys.achievementsUnlocked, defaults: defaults, decoder: decoder) ?? [:]
        dewPointHistory = Self.loadCodable([DewPointRecord].self, key: Keys.dewPointHistory, defaults: defaults, decoder: decoder) ?? []
        alertThresholds = Self.loadCodable([String: Double].self, key: Keys.alertThresholds, defaults: defaults, decoder: decoder) ?? [:]

        if let raw = defaults.string(forKey: Keys.temperatureUnit),
           let unit = TemperatureUnit(rawValue: raw) {
            temperatureUnit = unit
        } else {
            temperatureUnit = .celsius
        }

        if let interval = defaults.object(forKey: Keys.sessionStartDate) as? Double {
            sessionStartDate = Date(timeIntervalSince1970: interval)
        }
    }

    var dewPointData: [Date: Double] {
        Dictionary(uniqueKeysWithValues: dewPointHistory.map { ($0.timestamp, $0.dewPoint) })
    }

    var latestReading: DewPointRecord? {
        dewPointHistory.sorted { $0.timestamp > $1.timestamp }.first
    }

    var sortedHistory: [DewPointRecord] {
        dewPointHistory.sorted { $0.timestamp > $1.timestamp }
    }

    var filteredHistory: [DewPointRecord] {
        guard historyTagFilter != "all" else { return sortedHistory }
        return sortedHistory.filter { $0.tags.contains(historyTagFilter) }
    }

    var taggedReadingsCount: Int {
        dewPointHistory.filter { !$0.tags.isEmpty }.count
    }

    var activePreset: ScenarioPreset? {
        guard let activePresetId else { return nil }
        return ScenarioCatalog.preset(id: activePresetId)
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
    }

    func startSessionTracking() {
        if sessionStartDate == nil {
            let now = Date()
            sessionStartDate = now
            defaults.set(now.timeIntervalSince1970, forKey: Keys.sessionStartDate)
        }
    }

    func flushSessionMinutes() {
        guard let start = sessionStartDate else { return }
        let minutes = max(0, Int(Date().timeIntervalSince(start) / 60))
        if minutes > 0 {
            totalMinutesUsed += minutes
        }
        sessionStartDate = Date()
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.sessionStartDate)
    }

    func recordActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = lastActivityDate {
            let lastDay = calendar.startOfDay(for: last)
            if lastDay == today {
                evaluateMilestones()
                return
            }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), lastDay == yesterday {
                streakDays += 1
            } else {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }

        lastActivityDate = Date()
        evaluateMilestones()
    }

    @discardableResult
    func addReading(
        dewPoint: Double,
        temperature: Double,
        humidity: Double? = nil,
        tags: [String] = [],
        note: String = ""
    ) -> DewPointRecord {
        let record = DewPointRecord(
            dewPoint: dewPoint,
            temperature: temperature,
            humidity: humidity,
            tags: tags,
            note: note
        )
        dewPointHistory.append(record)
        itemsCreated += 1
        totalSessionsCompleted += 1
        recordActivity()
        evaluateMilestones()
        return record
    }

    func deleteReading(id: UUID) {
        dewPointHistory.removeAll { $0.id == id }
    }

    func registerCalculation() {
        calculationsPerformed += 1
        recordActivity()
        evaluateMilestones()
    }

    func applyPreset(_ preset: ScenarioPreset) {
        alertThresholds = [
            "low": preset.lowThresholdC,
            "high": preset.highThresholdC
        ]
        activePresetId = preset.id
        presetsApplied += 1
        itemsCreated += 1
        recordActivity()
        evaluateMilestones()
    }

    func registerDecisionCheck() {
        decisionsChecked += 1
        consecutiveRiskChecks += 1
        recordActivity()
        evaluateMilestones()
    }

    func registerReportExport() {
        reportsExported += 1
        recordActivity()
        evaluateMilestones()
    }

    func setAlertThresholds(high: Double?, low: Double?) {
        var next = alertThresholds
        if let high {
            next["high"] = high
        } else {
            next.removeValue(forKey: "high")
        }
        if let low {
            next["low"] = low
        } else {
            next.removeValue(forKey: "low")
        }
        alertThresholds = next
        itemsCreated += 1
        recordActivity()
        evaluateMilestones()
    }

    func markRefreshed() {
        lastRefreshed = Date()
        recordActivity()
        evaluateMilestones()
    }

    func markInsightsReviewed() {
        recordActivity()
        evaluateMilestones()
    }

    func evaluateMilestones() {
        for definition in MilestoneCatalog.all {
            guard definition.isEarned(self) else { continue }
            guard achievementsUnlocked[definition.id] == nil else { continue }
            achievementsUnlocked[definition.id] = Date()
            pendingAchievementIds.append(definition.id)
            NotificationCenter.default.post(
                name: .achievementUnlocked,
                object: nil,
                userInfo: ["id": definition.id]
            )
        }
    }

    func consumeNextPendingAchievement() -> MilestoneDefinition? {
        guard !pendingAchievementIds.isEmpty else { return nil }
        let id = pendingAchievementIds.removeFirst()
        return MilestoneCatalog.all.first { $0.id == id }
    }

    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier
        if let domain {
            defaults.removePersistentDomain(forName: domain)
        }
        defaults.synchronize()

        hasSeenOnboarding = false
        totalSessionsCompleted = 0
        totalMinutesUsed = 0
        streakDays = 0
        lastActivityDate = nil
        achievementsUnlocked = [:]
        itemsCreated = 0
        dewPointHistory = []
        alertThresholds = [:]
        selectedTimeFrame = "Week"
        lastRefreshed = nil
        temperatureUnit = .celsius
        pendingAchievementIds = []
        sessionStartDate = nil
        activePresetId = nil
        calculationsPerformed = 0
        presetsApplied = 0
        decisionsChecked = 0
        reportsExported = 0
        consecutiveRiskChecks = 0
        historyTagFilter = "all"

        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    func displayValue(_ celsiusValue: Double) -> Double {
        switch temperatureUnit {
        case .celsius:
            return celsiusValue
        case .fahrenheit:
            return celsiusValue * 9.0 / 5.0 + 32.0
        }
    }

    func storageValue(fromDisplay value: Double) -> Double {
        switch temperatureUnit {
        case .celsius:
            return value
        case .fahrenheit:
            return (value - 32.0) * 5.0 / 9.0
        }
    }

    func formattedDewPoint(_ celsiusValue: Double) -> String {
        String(format: "%.1f%@", displayValue(celsiusValue), temperatureUnit.symbol)
    }

    private func saveCodable<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadCodable<T: Decodable>(
        _ type: T.Type,
        key: String,
        defaults: UserDefaults,
        decoder: JSONDecoder
    ) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
