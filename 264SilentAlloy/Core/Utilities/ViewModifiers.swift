import SwiftUI

struct ShakeEffect: GeometryEffect {
    var travelDistance: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = travelDistance * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

/// Standard screen shell from swiftui-screens: background fills behind transparent scroll chrome.
struct AppScreenShell<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            AppBackgroundView()
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension View {
    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func transparentScreenChrome() -> some View {
        background(Color.clear)
    }

    func clearListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
            .listStyle(.plain)
    }

    func primaryButtonStyle() -> some View {
        self
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color("AppTextPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DepthChrome.controlRadius, style: .continuous)
                    .fill(DepthChrome.primaryButtonFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DepthChrome.controlRadius, style: .continuous)
                    .stroke(Color("AppTextPrimary").opacity(0.14), lineWidth: 1)
            )
            .softShadow(.control)
            .contentShape(RoundedRectangle(cornerRadius: DepthChrome.controlRadius, style: .continuous))
    }

    func surfaceCardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .elevatedCardChrome()
    }
}
