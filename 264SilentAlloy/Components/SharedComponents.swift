import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            DepthChrome.screenGradient

            // Static radial washes — cheaper than Canvas dot grids / blur.
            RadialGradient(
                colors: [
                    Color("AppPrimary").opacity(0.16),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 280
            )
            .allowsHitTesting(false)

            RadialGradient(
                colors: [
                    Color("AppAccent").opacity(0.10),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 320
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

struct SuccessCheckmarkOverlay: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color("AppAccent"))
                .shadow(color: Color("AppAccent").opacity(0.4), radius: 12)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

struct AchievementBannerView: View {
    let title: String
    let detail: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DepthChrome.iconBadgeFill)
                    .frame(width: 44, height: 44)
                    .softShadow(.control)
                Image(systemName: symbolName)
                    .font(.title3)
                    .foregroundStyle(Color("AppTextPrimary"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Milestone Reached")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .elevatedCardChrome(accentBorder: true, elevated: true)
        .padding(.horizontal, 16)
    }
}

struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(DepthChrome.tileFill)
                    .frame(width: 78, height: 78)
                    .softShadow(.control)
                Image(systemName: symbolName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color("AppAccent"))
            }
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .elevatedCardChrome(elevated: true)
    }
}

struct DewPointLineChart: View {
    let points: [(Date, Double)]
    let selectedIndex: Int?
    let onSelect: (Int?) -> Void

    var body: some View {
        GeometryReader { geo in
            let values = points.map(\.1)
            let minValue = (values.min() ?? 0) - 1
            let maxValue = (values.max() ?? 1) + 1
            let range = max(maxValue - minValue, 1)

            ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DepthChrome.tileFill)

                if points.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundStyle(Color("AppTextSecondary"))
                        Text("No trend data yet")
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                } else {
                    Canvas { context, size in
                        let inset: CGFloat = 16
                        let width = size.width - inset * 2
                        let height = size.height - inset * 2
                        let stepX = points.count > 1 ? width / CGFloat(points.count - 1) : 0

                        for guide in 0..<4 {
                            let y = inset + height * CGFloat(guide) / 3
                            var grid = Path()
                            grid.move(to: CGPoint(x: inset, y: y))
                            grid.addLine(to: CGPoint(x: inset + width, y: y))
                            context.stroke(grid, with: .color(Color("AppTextSecondary").opacity(0.12)), lineWidth: 1)
                        }

                        var fillPath = Path()
                        for (index, point) in points.enumerated() {
                            let x = inset + CGFloat(index) * stepX
                            let normalized = (point.1 - minValue) / range
                            let y = inset + height * (1 - normalized)
                            if index == 0 {
                                fillPath.move(to: CGPoint(x: x, y: inset + height))
                                fillPath.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                fillPath.addLine(to: CGPoint(x: x, y: y))
                            }
                            if index == points.count - 1 {
                                fillPath.addLine(to: CGPoint(x: x, y: inset + height))
                                fillPath.closeSubpath()
                            }
                        }
                        context.fill(fillPath, with: .color(Color("AppAccent").opacity(0.14)))

                        var path = Path()
                        for (index, point) in points.enumerated() {
                            let x = inset + CGFloat(index) * stepX
                            let normalized = (point.1 - minValue) / range
                            let y = inset + height * (1 - normalized)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }

                        context.stroke(
                            path,
                            with: .color(Color("AppAccent")),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )

                        for (index, point) in points.enumerated() {
                            let x = inset + CGFloat(index) * stepX
                            let normalized = (point.1 - minValue) / range
                            let y = inset + height * (1 - normalized)
                            let selected = selectedIndex == index
                            let sizeDot: CGFloat = selected ? 9 : 6
                            let dot = Path(ellipseIn: CGRect(x: x - sizeDot / 2, y: y - sizeDot / 2, width: sizeDot, height: sizeDot))
                            context.fill(dot, with: .color(selected ? Color("AppAccent") : Color("AppPrimary")))
                        }

                        if let selectedIndex, points.indices.contains(selectedIndex) {
                            let x = inset + CGFloat(selectedIndex) * stepX
                            var guide = Path()
                            guide.move(to: CGPoint(x: x, y: inset))
                            guide.addLine(to: CGPoint(x: x, y: inset + height))
                            context.stroke(guide, with: .color(Color("AppTextSecondary").opacity(0.45)), lineWidth: 1)
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !points.isEmpty else { return }
                                let inset: CGFloat = 16
                                let width = max(geo.size.width - inset * 2, 1)
                                let ratio = min(max((value.location.x - inset) / width, 0), 1)
                                let index = Int(round(ratio * CGFloat(max(points.count - 1, 0))))
                                onSelect(index)
                            }
                            .onEnded { _ in
                                onSelect(nil)
                            }
                    )
                }
            }
        }
        .frame(height: 180)
    }
}
