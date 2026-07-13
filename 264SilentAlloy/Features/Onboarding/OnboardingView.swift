import SwiftUI

struct OnboardingView: View {
    let onFinished: () -> Void

    @State private var page = 0
    @State private var illustrationVisible = false

    private struct OnboardingPage {
        let symbol: String
        let imageName: String
        let headline: String
        let detail: String
        let tip: String
    }

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "thermometer.medium",
            imageName: "home_widget_gauge",
            headline: "Monitor Dew Point",
            detail: "Get detailed information about current dew point levels to plan your activities.",
            tip: "Calculate from temperature + humidity"
        ),
        OnboardingPage(
            symbol: "bell.badge.fill",
            imageName: "home_widget_comfort",
            headline: "Set Alerts",
            detail: "Customize alerts to notify you when dew points reach critical levels.",
            tip: "Use presets for sleep, gym, and mold risk"
        ),
        OnboardingPage(
            symbol: "chart.xyaxis.line",
            imageName: "home_hero_moisture",
            headline: "Start Tracking",
            detail: "Begin monitoring dew points today and optimize your environment for better comfort.",
            tip: "Track trends, decisions, and weekly reports"
        )
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageContent(pages[index], index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: page)

                bottomControls
            }
        }
        .onChange(of: page) { _ in
            animateIllustration()
        }
        .onAppear {
            animateIllustration()
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? DepthChrome.primaryButtonFill : DepthChrome.tileFill)
                        .frame(width: index == page ? 26 : 8, height: 8)
                        .overlay(
                            Capsule()
                                .stroke(
                                    index == page ? DepthChrome.accentHairline : DepthChrome.hairline,
                                    lineWidth: 1
                                )
                        )
                        .softShadow(.control)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                }
            }

            Button {
                FeedbackService.tap()
                if page < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        page += 1
                    }
                } else {
                    onFinished()
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Get Started")
                    .primaryButtonStyle()
            }
            .frame(minHeight: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DepthChrome.elevatedFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(DepthChrome.hairline, lineWidth: 1)
                )
                .softShadow(.floating)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func pageContent(_ item: OnboardingPage, index: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 24)

                illustrationCard(item)
                    .scaleEffect(illustrationVisible ? 1 : 0.88)
                    .opacity(illustrationVisible ? 1 : 0)

                AppCard(accentBorder: true, elevated: true) {
                    VStack(spacing: 14) {
                        StatusPillCell(title: "Step \(index + 1) of \(pages.count)", tone: .positive)

                        Text(item.headline)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.75)
                            .lineLimit(2)

                        Text(item.detail)
                            .font(.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            Image(systemName: item.symbol)
                                .foregroundStyle(Color("AppAccent"))
                            Text(item.tip)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
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
                    .frame(maxWidth: .infinity)
                }

                featureRow(for: index)

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .clearScrollBackground()
    }

    private func illustrationCard(_ item: OnboardingPage) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(item.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color("AppBackground").opacity(0.05),
                            Color("AppBackground").opacity(0.82)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DepthChrome.iconBadgeFill)
                        .frame(width: 48, height: 48)
                        .softShadow(.control)
                    Image(systemName: item.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.headline)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(item.tip)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(DepthChrome.accentHairline, lineWidth: 1.2)
        )
        .softShadow(.floating)
    }

    @ViewBuilder
    private func featureRow(for index: Int) -> some View {
        let items: [(String, String)] = {
            switch index {
            case 0:
                return [("function", "Calculator"), ("drop.fill", "Comfort"), ("leaf.fill", "Mold risk")]
            case 1:
                return [("bell.badge", "Alerts"), ("slider.horizontal.3", "Presets"), ("moon.zzz.fill", "Sleep")]
            default:
                return [("chart.xyaxis.line", "Trends"), ("doc.richtext", "Reports"), ("flag.fill", "Milestones")]
            }
        }()

        HStack(spacing: 10) {
            ForEach(items, id: \.1) { symbol, title in
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(DepthChrome.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(DepthChrome.hairline, lineWidth: 1)
                            )
                            .frame(width: 52, height: 52)
                            .softShadow(.control)
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color("AppAccent"))
                    }
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .elevatedCardChrome()
    }

    private func animateIllustration() {
        illustrationVisible = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            illustrationVisible = true
        }
    }
}
