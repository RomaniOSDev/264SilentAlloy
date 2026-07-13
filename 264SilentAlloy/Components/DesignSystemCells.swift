import SwiftUI

// MARK: - Screen chrome

struct ScreenHeaderCell: View {
    let title: String
    var subtitle: String? = nil
    var symbolName: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            if let symbolName {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DepthChrome.iconBadgeFill)
                        .frame(width: 48, height: 48)
                        .softShadow(.control)
                    Image(systemName: symbolName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 48)
    }
}

struct SectionLabelCell: View {
    let title: String
    var accessory: String? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(Color("AppTextSecondary"))
            Spacer(minLength: 0)
            if let accessory {
                Text(accessory)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
            }
        }
    }
}

// MARK: - Cards & rows

struct AppCard<Content: View>: View {
    var padding: CGFloat = 16
    var accentBorder: Bool = false
    var elevated: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .elevatedCardChrome(accentBorder: accentBorder, elevated: elevated || accentBorder)
    }
}

struct MetricTileCell: View {
    let title: String
    let value: String
    var symbolName: String? = nil
    var emphasize: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                }
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            Text(value)
                .font(emphasize ? .title2.weight(.bold) : .headline.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DepthChrome.tileFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DepthChrome.hairline, lineWidth: 1)
        )
        .softShadow(.control)
    }
}

struct StatRowCell: View {
    let title: String
    let value: String
    var symbolName: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let symbolName {
                ZStack {
                    Circle()
                        .fill(Color("AppBackground"))
                        .frame(width: 36, height: 36)
                    Image(systemName: symbolName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(minHeight: 44)
    }
}

struct SettingsRowCell: View {
    let title: String
    let symbolName: String
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(destructive ? Color.red.opacity(0.18) : Color("AppBackground"))
                        .frame(width: 40, height: 40)
                    Image(systemName: symbolName)
                        .foregroundStyle(destructive ? Color.red : Color("AppAccent"))
                }
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(destructive ? Color.red : Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                if !destructive {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DepthChrome.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(DepthChrome.hairline, lineWidth: 1)
            )
            .softShadow(.control)
        }
        .buttonStyle(.plain)
    }
}

struct FilterChipCell: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(minHeight: 40)
                .background {
                    if isSelected {
                        Capsule().fill(DepthChrome.primaryButtonFill)
                    } else {
                        Capsule().fill(DepthChrome.cardFill)
                    }
                }
                .overlay(
                    Capsule()
                        .stroke(isSelected ? DepthChrome.accentHairline : DepthChrome.hairline, lineWidth: 1)
                )
                .softShadow(.control)
        }
        .buttonStyle(.plain)
    }
}

struct TagChipCell: View {
    let title: String
    let symbolName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DepthChrome.primaryButtonFill)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DepthChrome.tileFill)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? DepthChrome.accentHairline : DepthChrome.hairline, lineWidth: 1)
            )
            .softShadow(.control)
        }
        .buttonStyle(.plain)
    }
}

struct InputFieldCell: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var shakeToken: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
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
                .modifier(ShakeEffect(animatableData: CGFloat(shakeToken)))
        }
    }
}

struct HeroValueCell: View {
    let value: String
    let caption: String
    var badge: String? = nil
    var pulse: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            if let badge {
                Text(badge)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(DepthChrome.primaryButtonFill)
                    )
                    .softShadow(.control)
            }
            Text(value)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(pulse ? Color("AppAccent") : Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .animation(.easeInOut(duration: 0.35), value: pulse)
            Text(caption)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct StatusPillCell: View {
    let title: String
    var tone: Tone = .neutral

    enum Tone {
        case positive, caution, negative, neutral
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(pillBackground)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(DepthChrome.hairline, lineWidth: 1))
            .softShadow(.control)
    }

    @ViewBuilder
    private var pillBackground: some View {
        switch tone {
        case .positive:
            Capsule().fill(DepthChrome.primaryButtonFill)
        case .caution:
            Capsule().fill(DepthChrome.cardFill)
        case .negative:
            Capsule().fill(Color.red.opacity(0.75))
        case .neutral:
            Capsule().fill(DepthChrome.tileFill)
        }
    }
}

struct ComfortGaugeCell: View {
    let zone: ComfortZone
    let moldRisk: MoldRiskLevel
    let tip: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                comfortDot
                VStack(alignment: .leading, spacing: 2) {
                    Text("Comfort · \(zone.title)")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(zone.detail)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                ForEach(ComfortZone.allCases, id: \.self) { item in
                    Capsule()
                        .fill(item == zone ? Color("AppAccent") : Color("AppBackground"))
                        .frame(height: 8)
                        .overlay(
                            Capsule()
                                .stroke(Color("AppTextSecondary").opacity(0.12), lineWidth: 1)
                        )
                }
            }

            HStack {
                Text("Mold risk")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                Spacer(minLength: 0)
                StatusPillCell(
                    title: moldRisk.title,
                    tone: moldRisk == .low ? .positive : (moldRisk == .moderate ? .caution : .negative)
                )
            }

            Text(tip)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextPrimary"))
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private var comfortDot: some View {
        ZStack {
            Circle()
                .fill(Color("AppPrimary").opacity(0.25))
                .frame(width: 42, height: 42)
            Circle()
                .fill(Color("AppAccent"))
                .frame(width: 14, height: 14)
        }
    }
}

struct HistoryReadingCell: View {
    let record: DewPointRecord
    let dewPointText: String
    let temperatureText: String
    let expanded: Bool
    let bounce: Bool
    let onToggle: () -> Void

    private var zone: ComfortZone {
        ComfortRiskEngine.comfortZone(dewPointC: record.dewPoint)
    }

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color("AppBackground"))
                            .frame(width: 46, height: 46)
                        Image(systemName: "drop.fill")
                            .foregroundStyle(Color("AppAccent"))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextSecondary"))
                        Text(dewPointText)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        HStack(spacing: 8) {
                            StatusPillCell(title: zone.title, tone: .positive)
                            if !record.tags.isEmpty {
                                Text(record.tags.prefix(2).joined(separator: " · "))
                                    .font(.caption2)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color("AppAccent"))
                        .frame(width: 44, height: 44)
                }

                if expanded {
                    VStack(alignment: .leading, spacing: 8) {
                        detailLine(symbol: "thermometer", text: "Air \(temperatureText)")
                        if let humidity = record.humidity {
                            detailLine(symbol: "drop.fill", text: "Humidity \(String(format: "%.0f", humidity))%")
                        }
                        detailLine(
                            symbol: "exclamationmark.shield",
                            text: "Mold risk \(ComfortRiskEngine.moldRisk(dewPointC: record.dewPoint).title)"
                        )
                        if !record.note.isEmpty {
                            detailLine(symbol: "note.text", text: record.note)
                        }
                        if !record.tags.isEmpty {
                            detailLine(symbol: "tag", text: record.tags.joined(separator: ", "))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .elevatedCardChrome(elevated: expanded)
            .scaleEffect(bounce ? 1.015 : 1)
        }
        .buttonStyle(.plain)
    }

    private func detailLine(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(Color("AppAccent"))
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct DecisionOptionCell: View {
    let title: String
    let symbolName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? DepthChrome.primaryButtonFill : DepthChrome.tileFill)
                        .frame(width: 44, height: 44)
                        .softShadow(.control)
                    Image(systemName: symbolName)
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color("AppAccent") : Color("AppTextSecondary"))
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 64)
            .elevatedCardChrome(accentBorder: isSelected)
        }
        .buttonStyle(.plain)
    }
}

struct VerdictResultCell: View {
    let verdict: DecisionVerdict
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusPillCell(title: verdict.title, tone: tone)
                Spacer(minLength: 0)
            }
            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tone: StatusPillCell.Tone {
        switch verdict {
        case .yes: return .positive
        case .caution: return .caution
        case .no: return .negative
        }
    }
}

struct PresetCardCell: View {
    let preset: ScenarioPreset
    let rangeText: String
    let isApplied: Bool
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DepthChrome.tileFill)
                        .frame(width: 46, height: 46)
                        .softShadow(.control)
                    Image(systemName: preset.symbolName)
                        .foregroundStyle(Color("AppAccent"))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.title)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(preset.detail)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if isApplied {
                    StatusPillCell(title: "Active", tone: .positive)
                }
            }

            Text(rangeText)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppAccent"))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(preset.tips.prefix(3), id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color("AppAccent"))
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                        Text(tip)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Button(action: onApply) {
                Text(isApplied ? "Applied" : "Apply Preset")
                    .primaryButtonStyle()
            }
            .frame(minHeight: 44)
        }
        .padding(16)
        .elevatedCardChrome(accentBorder: isApplied, elevated: isApplied)
    }
}

struct MilestoneCardCell: View {
    let milestone: MilestoneDefinition
    let isReached: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(DepthChrome.tileFill)
                    .frame(width: 64, height: 64)
                    .softShadow(.control)
                Circle()
                    .stroke(Color("AppTextSecondary").opacity(0.2), lineWidth: 4)
                    .frame(width: 58, height: 58)
                Circle()
                    .trim(from: 0, to: isReached ? 1 : 0.28)
                    .stroke(
                        DepthChrome.accentHairline,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 58, height: 58)
                    .rotationEffect(.degrees(-90))
                Image(systemName: milestone.symbolName)
                    .font(.title3)
                    .foregroundStyle(isReached ? Color("AppAccent") : Color("AppTextSecondary"))
            }

            Text(milestone.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(milestone.detail)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            StatusPillCell(
                title: isReached ? "Reached" : "In progress",
                tone: isReached ? .positive : .neutral
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 196)
        .elevatedCardChrome(accentBorder: isReached, elevated: isReached)
    }
}

struct SecondaryButtonLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color("AppTextPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DepthChrome.controlRadius, style: .continuous)
                    .fill(DepthChrome.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DepthChrome.controlRadius, style: .continuous)
                    .stroke(DepthChrome.accentHairline, lineWidth: 1.5)
            )
            .softShadow(.control)
    }
}

struct ChartCardCell<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabelCell(title: title)
            content()
        }
        .padding(16)
        .elevatedCardChrome(elevated: true)
    }
}
