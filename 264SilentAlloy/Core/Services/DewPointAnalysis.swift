import Foundation

enum DewPointCalculator {
    /// Magnus-Tetens approximation. Temperature in °C, humidity in % (0...100).
    static func dewPointCelsius(temperatureC: Double, humidityPercent: Double) -> Double? {
        guard humidityPercent > 0, humidityPercent <= 100 else { return nil }
        guard temperatureC > -80, temperatureC < 60 else { return nil }

        let a = 17.625
        let b = 243.04
        let rh = humidityPercent / 100.0
        let alpha = log(rh) + (a * temperatureC) / (b + temperatureC)
        return (b * alpha) / (a - alpha)
    }

    static func comfortAdvice(for zone: ComfortZone) -> String {
        switch zone {
        case .dry:
            return "Moisture is low. A humidifier may improve comfort if air feels harsh."
        case .ideal:
            return "Conditions look comfortable for most indoor activities."
        case .sticky:
            return "Air feels humid. Improve ventilation or run a dehumidifier."
        case .oppressive:
            return "Moisture is very high. Prioritize dehumidification and watch for condensation."
        }
    }
}

enum ComfortRiskEngine {
    static func comfortZone(dewPointC: Double) -> ComfortZone {
        switch dewPointC {
        case ..<10: return .dry
        case 10..<16: return .ideal
        case 16..<21: return .sticky
        default: return .oppressive
        }
    }

    static func moldRisk(dewPointC: Double) -> MoldRiskLevel {
        switch dewPointC {
        case ..<12: return .low
        case 12..<16: return .moderate
        default: return .high
        }
    }

    static func hvacTip(dewPointC: Double) -> String {
        switch comfortZone(dewPointC: dewPointC) {
        case .dry:
            return "Open windows OK if outdoor air is not damp. Light humidification may help."
        case .ideal:
            return "Open windows OK. HVAC can stay on comfort mode."
        case .sticky:
            return "Run dehumidifier. Limit outdoor air if it feels muggy."
        case .oppressive:
            return "Run dehumidifier now. High risk of condensation on windows and cool surfaces."
        }
    }

    static func isRiskDay(dewPointC: Double) -> Bool {
        moldRisk(dewPointC: dewPointC) != .low || comfortZone(dewPointC: dewPointC) == .oppressive
    }
}

struct DecisionQuestion: Identifiable {
    let id: String
    let title: String
    let symbolName: String
}

enum DecisionHelper {
    static let questions: [DecisionQuestion] = [
        DecisionQuestion(id: "windows", title: "Open windows now?", symbolName: "wind"),
        DecisionQuestion(id: "dehumidifier", title: "Run dehumidifier?", symbolName: "drop.triangle.fill"),
        DecisionQuestion(id: "outdoor_run", title: "Outdoor run comfortable?", symbolName: "figure.run")
    ]

    static func evaluate(questionId: String, dewPointC: Double, highThreshold: Double?, lowThreshold: Double?) -> (DecisionVerdict, String) {
        let zone = ComfortRiskEngine.comfortZone(dewPointC: dewPointC)
        let mold = ComfortRiskEngine.moldRisk(dewPointC: dewPointC)
        let high = highThreshold ?? 15
        let low = lowThreshold ?? 5

        switch questionId {
        case "windows":
            if dewPointC >= high || zone == .oppressive || mold == .high {
                return (.no, "Moisture is elevated. Opening windows may pull in more humidity.")
            }
            if zone == .sticky || dewPointC >= (high - 2) {
                return (.caution, "Only open briefly if outdoor air feels drier than indoors.")
            }
            return (.yes, "Dew point looks manageable. Fresh air exchange should be fine.")

        case "dehumidifier":
            if zone == .oppressive || mold == .high || dewPointC >= high {
                return (.yes, "Moisture is high enough that a dehumidifier will help comfort and mold risk.")
            }
            if zone == .sticky || mold == .moderate {
                return (.caution, "A short dehumidifier cycle can help, especially in bathrooms or basements.")
            }
            return (.no, "Moisture is already in a comfortable range. No dehumidifier needed right now.")

        case "outdoor_run":
            if zone == .oppressive || dewPointC >= 21 {
                return (.no, "High dew point makes outdoor exercise feel heavier and less recoverable.")
            }
            if zone == .sticky || dewPointC >= high {
                return (.caution, "Possible, but expect sticky air. Shorten intensity and hydrate more.")
            }
            if dewPointC < low {
                return (.yes, "Dry air is usually comfortable for outdoor runs.")
            }
            return (.yes, "Dew point is in a workable range for most outdoor workouts.")

        default:
            return (.caution, "Not enough context for this decision.")
        }
    }
}
