import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan = 1

    var body: some View {
        ZStack {
            CSColor.surfacePrimary.ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [CSColor.signalPrimary.opacity(0.04), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(y: -200)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(CSColor.textTertiary)
                                .frame(width: 28, height: 28)
                        }
                    }
                    .padding(.horizontal, CSSpacing.lg)
                    .padding(.top, CSSpacing.sm)

                    Text("👑")
                        .font(.system(size: 48))

                    Text("Unlock ")
                        .font(CSFont.title(.bold)) +
                    Text("CardScope Pro")
                        .font(CSFont.title(.bold))
                        .foregroundColor(CSColor.signalPrimary)

                    Text("Unlimited scans, full market data,\nand AI-powered grading insights")
                        .font(CSFont.body())
                        .foregroundStyle(CSColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, CSSpacing.xs)

                    VStack(alignment: .leading, spacing: CSSpacing.sm) {
                        featureItem("Unlimited AI card identification")
                        featureItem("Full market prices (Raw / PSA 9 / 10)")
                        featureItem("Price history charts & trends")
                        featureItem("AI condition pre-grading")
                        featureItem("Unlimited collection & portfolio")
                        featureItem("Fake card detection")
                    }
                    .padding(.top, CSSpacing.lg)

                    VStack(spacing: CSSpacing.sm) {
                        planButton(
                            index: 0,
                            name: "Monthly",
                            desc: "Cancel anytime",
                            price: "$7.99",
                            period: "/month"
                        )
                        planButton(
                            index: 1,
                            name: "Annual",
                            desc: "3-day free trial",
                            price: "$3.33",
                            period: "/month",
                            badge: "BEST VALUE · SAVE 58%"
                        )
                    }
                    .padding(.top, CSSpacing.md)

                    Button("Start 3-Day Free Trial") {
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, CSSpacing.md)

                    Text("After trial, auto-renews at $39.99/year. Cancel anytime.")
                        .font(.system(size: 10))
                        .foregroundStyle(CSColor.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, CSSpacing.sm)

                    Button("Restore Purchase") {}
                        .font(.system(size: 11))
                        .foregroundStyle(CSColor.textTertiary)
                        .underline()
                        .padding(.top, CSSpacing.sm)
                        .padding(.bottom, CSSpacing.lg)
                }
                .padding(.horizontal, CSSpacing.lg)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func featureItem(_ text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(CSColor.signalPrimary.opacity(0.1))
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CSColor.signalPrimary)
            }
            Text(text)
                .font(CSFont.body())
                .foregroundStyle(CSColor.textSecondary)
        }
    }

    private func planButton(index: Int, name: String, desc: String, price: String, period: String, badge: String? = nil) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { selectedPlan = index }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .stroke(selectedPlan == index ? CSColor.signalPrimary : CSColor.textTertiary, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Group {
                            if selectedPlan == index {
                                Circle()
                                    .fill(CSColor.signalPrimary)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(CSFont.body(.bold))
                        .foregroundStyle(CSColor.textPrimary)
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundStyle(CSColor.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(price)
                        .font(CSFont.mono(22, weight: .heavy))
                        .foregroundStyle(selectedPlan == index ? CSColor.signalPrimary : CSColor.textPrimary)
                    Text(period)
                        .font(.system(size: 11))
                        .foregroundStyle(CSColor.textTertiary)
                }
            }
            .padding(CSSpacing.md)
            .background(
                selectedPlan == index ? CSColor.signalPrimary.opacity(0.03) : CSColor.surfaceElevated
            )
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CSRadius.md)
                    .stroke(
                        selectedPlan == index ? CSColor.signalPrimary : CSColor.border,
                        lineWidth: selectedPlan == index ? 1.5 : 0.5
                    )
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, CSSpacing.sm)
                        .padding(.vertical, 3)
                        .background(CSColor.signalPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .offset(x: -12, y: -9)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
