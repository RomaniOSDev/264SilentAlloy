import SwiftUI

/// Lightweight depth tokens — static shapes only, no blur / no animated backgrounds.
enum DepthChrome {
    static let cardRadius: CGFloat = 18
    static let controlRadius: CGFloat = 14

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppBackground"),
                Color("AppSurface").opacity(0.42),
                Color("AppBackground")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface"),
                Color("AppBackground").opacity(0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var elevatedFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface").opacity(0.95),
                Color("AppPrimary").opacity(0.12),
                Color("AppBackground").opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var tileFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppBackground").opacity(0.35),
                Color("AppSurface").opacity(0.85)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var primaryButtonFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppPrimary"),
                Color("AppAccent").opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var iconBadgeFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppPrimary"),
                Color("AppAccent").opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var hairline: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppTextPrimary").opacity(0.18),
                Color("AppTextSecondary").opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentHairline: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppAccent").opacity(0.65),
                Color("AppPrimary").opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct SoftShadowModifier: ViewModifier {
    var intensity: SoftShadowIntensity = .card

    enum SoftShadowIntensity {
        case card
        case floating
        case control

        var radius: CGFloat {
            switch self {
            case .card: return 10
            case .floating: return 14
            case .control: return 6
            }
        }

        var y: CGFloat {
            switch self {
            case .card: return 6
            case .floating: return 8
            case .control: return 3
            }
        }

        var opacity: Double {
            switch self {
            case .card: return 0.28
            case .floating: return 0.34
            case .control: return 0.22
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(intensity.opacity),
                radius: intensity.radius,
                x: 0,
                y: intensity.y
            )
    }
}

struct ElevatedCardBackground: View {
    var accentBorder: Bool = false
    var elevated: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: DepthChrome.cardRadius, style: .continuous)
            .fill(elevated ? DepthChrome.elevatedFill : DepthChrome.cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: DepthChrome.cardRadius, style: .continuous)
                    .stroke(
                        accentBorder ? DepthChrome.accentHairline : DepthChrome.hairline,
                        lineWidth: accentBorder ? 1.4 : 1
                    )
            )
    }
}

extension View {
    func softShadow(_ intensity: SoftShadowModifier.SoftShadowIntensity = .card) -> some View {
        modifier(SoftShadowModifier(intensity: intensity))
    }

    func elevatedCardChrome(accentBorder: Bool = false, elevated: Bool = false) -> some View {
        self
            .background(ElevatedCardBackground(accentBorder: accentBorder, elevated: elevated))
            .softShadow(elevated || accentBorder ? .floating : .card)
    }
}
