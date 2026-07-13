import Foundation

struct DewPointRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var timestamp: Date
    var dewPoint: Double
    var temperature: Double
    var humidity: Double?
    var tags: [String]
    var note: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        dewPoint: Double,
        temperature: Double,
        humidity: Double? = nil,
        tags: [String] = [],
        note: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.dewPoint = dewPoint
        self.temperature = temperature
        self.humidity = humidity
        self.tags = tags
        self.note = note
    }

    enum CodingKeys: String, CodingKey {
        case id, timestamp, dewPoint, temperature, humidity, tags, note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        dewPoint = try container.decode(Double.self, forKey: .dewPoint)
        temperature = try container.decode(Double.self, forKey: .temperature)
        humidity = try container.decodeIfPresent(Double.self, forKey: .humidity)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
}

enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius
    case fahrenheit

    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

enum ReadingTag: String, CaseIterable, Identifiable, Codable {
    case indoors
    case outdoors
    case bedroom
    case bathroom
    case afterRain = "after rain"
    case workout
    case greenhouse

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .indoors: return "house.fill"
        case .outdoors: return "sun.max.fill"
        case .bedroom: return "bed.double.fill"
        case .bathroom: return "shower.fill"
        case .afterRain: return "cloud.rain.fill"
        case .workout: return "figure.run"
        case .greenhouse: return "leaf.fill"
        }
    }
}

enum ComfortZone: String, CaseIterable {
    case dry
    case ideal
    case sticky
    case oppressive

    var title: String {
        switch self {
        case .dry: return "Dry"
        case .ideal: return "Ideal"
        case .sticky: return "Sticky"
        case .oppressive: return "Oppressive"
        }
    }

    var detail: String {
        switch self {
        case .dry: return "Air feels dry. Moisture is low."
        case .ideal: return "Comfortable moisture for most indoor spaces."
        case .sticky: return "Noticeably humid. Comfort drops for sleep and workouts."
        case .oppressive: return "Very high moisture. Expect discomfort and condensation risk."
        }
    }
}

enum MoldRiskLevel: String {
    case low
    case moderate
    case high

    var title: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
}

enum DecisionVerdict: String {
    case yes
    case caution
    case no

    var title: String {
        switch self {
        case .yes: return "Yes"
        case .caution: return "Caution"
        case .no: return "No"
        }
    }
}

struct ScenarioPreset: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let lowThresholdC: Double
    let highThresholdC: Double
    let tips: [String]
}

enum ScenarioCatalog {
    static let all: [ScenarioPreset] = [
        ScenarioPreset(
            id: "sleep",
            title: "Sleep comfort",
            detail: "Keep bedroom moisture in a restful range.",
            symbolName: "moon.zzz.fill",
            lowThresholdC: 7,
            highThresholdC: 13,
            tips: [
                "Aim for a milder dew point before bedtime.",
                "If sticky, run a dehumidifier for 20–30 minutes.",
                "Avoid drying laundry in the bedroom overnight."
            ]
        ),
        ScenarioPreset(
            id: "gym",
            title: "Gym / workout",
            detail: "Reduce sticky air during exercise.",
            symbolName: "figure.run",
            lowThresholdC: 5,
            highThresholdC: 14,
            tips: [
                "High dew point makes workouts feel harder.",
                "Prefer cooler, drier rooms for intense sessions.",
                "Hydrate more when air feels oppressive."
            ]
        ),
        ScenarioPreset(
            id: "mold",
            title: "Home mold prevention",
            detail: "Lower indoor moisture that feeds mold growth.",
            symbolName: "house.fill",
            lowThresholdC: 0,
            highThresholdC: 10,
            tips: [
                "Keep dew point lower in bathrooms and basements.",
                "Vent after showers until humidity drops.",
                "Watch corners and window frames for condensation."
            ]
        ),
        ScenarioPreset(
            id: "photo",
            title: "Photography / outdoor gear",
            detail: "Protect lenses and gear from fog and moisture.",
            symbolName: "camera.fill",
            lowThresholdC: 2,
            highThresholdC: 12,
            tips: [
                "Condensation risk rises when gear is colder than dew point.",
                "Let equipment acclimate in a sealed bag.",
                "Avoid packing damp gear into closed cases."
            ]
        ),
        ScenarioPreset(
            id: "plants",
            title: "Greenhouse / plants",
            detail: "Balance plant humidity without stagnant moisture.",
            symbolName: "leaf.fill",
            lowThresholdC: 8,
            highThresholdC: 16,
            tips: [
                "Many plants like moderate moisture, not stagnant air.",
                "Airflow matters as much as dew point.",
                "Watch for mold on soil when dew point stays high."
            ]
        )
    ]

    static func preset(id: String) -> ScenarioPreset? {
        all.first { $0.id == id }
    }
}

struct MilestoneDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let isEarned: (AppDataStore) -> Bool
}

enum MilestoneCatalog {
    static let all: [MilestoneDefinition] = [
        MilestoneDefinition(
            id: "first_track",
            title: "First Reading",
            detail: "Saved your first dew point entry",
            symbolName: "thermometer.medium",
            isEarned: { $0.itemsCreated >= 1 }
        ),
        MilestoneDefinition(
            id: "calculator_use",
            title: "Moisture Analyst",
            detail: "Used the dew point calculator five times",
            symbolName: "function",
            isEarned: { $0.calculationsPerformed >= 5 }
        ),
        MilestoneDefinition(
            id: "preset_applied",
            title: "Scenario Ready",
            detail: "Applied a comfort scenario preset",
            symbolName: "slider.horizontal.3",
            isEarned: { $0.presetsApplied >= 1 }
        ),
        MilestoneDefinition(
            id: "decision_checks",
            title: "Decision Helper",
            detail: "Checked three Should I…? recommendations",
            symbolName: "questionmark.circle",
            isEarned: { $0.decisionsChecked >= 3 }
        ),
        MilestoneDefinition(
            id: "report_export",
            title: "Weekly Reporter",
            detail: "Exported a weekly moisture report",
            symbolName: "square.and.arrow.up",
            isEarned: { $0.reportsExported >= 1 }
        ),
        MilestoneDefinition(
            id: "tagged_entries",
            title: "Context Logger",
            detail: "Saved five tagged readings",
            symbolName: "tag.fill",
            isEarned: { $0.taggedReadingsCount >= 5 }
        ),
        MilestoneDefinition(
            id: "risk_streak",
            title: "Risk Watcher",
            detail: "Completed seven consecutive risk checks",
            symbolName: "eye.fill",
            isEarned: { $0.consecutiveRiskChecks >= 7 }
        ),
        MilestoneDefinition(
            id: "consistent_week",
            title: "Steady Tracker",
            detail: "Logged activity across seven consecutive days",
            symbolName: "calendar",
            isEarned: { $0.streakDays >= 7 }
        )
    ]
}

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}
