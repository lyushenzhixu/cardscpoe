import SwiftUI

struct GradeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let card: SportsCard

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBar
                gradeHero
                gradeResult
                gradeNote
                gradeCTA
                Spacer().frame(height: CSSpacing.xl)
            }
        }
        .background(CSColor.surfacePrimary)
        .preferredColorScheme(.dark)
        .task {
            await appState.analyzeGrade()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: CSSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(CSFont.body(.semibold))
                }
                .foregroundStyle(CSColor.signalPrimary)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundStyle(CSColor.textSecondary)
            }
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, CSSpacing.sm)
    }

    private var gradeHero: some View {
        Image("GradingView")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 320, maxHeight: 280)
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.lg))
            .padding(.bottom, CSSpacing.md)
    }

    private var gradeResult: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: CSSpacing.sm) {
                    Text("💎")
                    Text("AI Grade")
                        .font(CSFont.headline(.bold))
                }
                Spacer()
                Text(String(format: "%.1f", breakdown.overall))
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .foregroundStyle(CSColor.signalGold)
            }
            .padding(.bottom, CSSpacing.xs)

            Text("Gem Mint Condition · /10")
                .font(CSFont.caption())
                .foregroundStyle(CSColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, CSSpacing.md)

            gradeBarRow(label: "Centering", value: breakdown.centering / 10, score: String(format: "%.1f", breakdown.centering), color: CSColor.signalPrimary)
            gradeBarRow(label: "Corners", value: breakdown.corners / 10, score: String(format: "%.1f", breakdown.corners), color: CSColor.signalGold)
            gradeBarRow(label: "Edges", value: breakdown.edges / 10, score: String(format: "%.1f", breakdown.edges), color: CSColor.signalTertiary)
            gradeBarRow(label: "Surface", value: breakdown.surface / 10, score: String(format: "%.1f", breakdown.surface), color: CSColor.signalPrimary)
        }
        .padding(CSSpacing.lg)
        .background(CSColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.lg)
                .stroke(CSColor.border, lineWidth: 0.5)
        )
        .padding(.horizontal, CSSpacing.md)
    }

    private func gradeBarRow(label: String, value: Double, score: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(CSFont.caption())
                    .foregroundStyle(CSColor.textSecondary)
                Spacer()
                Text(score)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.04))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * value)
                }
            }
            .frame(height: 4)
        }
        .padding(.bottom, 12)
    }

    private var gradeNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("💡")
                .font(.system(size: 16))

            Group {
                Text(
                    "This card has a \(Text("high chance of receiving PSA 9 or 10").foregroundStyle(CSColor.signalPrimary).bold()). We recommend submitting for professional grading. Estimated value increase: \(Text("+65–120%").foregroundStyle(CSColor.signalPrimary).bold())"
                )
                .foregroundStyle(CSColor.textSecondary)
            }
            .font(CSFont.caption())
            .lineSpacing(4)
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, 12)
        .background(CSColor.signalPrimary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: CSRadius.sm)
                .stroke(CSColor.signalPrimary.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.horizontal, CSSpacing.md)
        .padding(.top, CSSpacing.md)
    }

    private var gradeCTA: some View {
        Button {} label: {
            HStack(spacing: CSSpacing.sm) {
                Text("🏆")
                Text("Submit to PSA for Grading")
                    .font(CSFont.body(.bold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(CSColor.signalGold)
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
        }
        .buttonStyle(NyxPressableStyle())
        .padding(.horizontal, CSSpacing.md)
        .padding(.top, CSSpacing.md)
    }

    private var breakdown: GradeBreakdown {
        appState.latestGradeBreakdown ?? GradeBreakdown(centering: 9.1, corners: 9.0, edges: 8.8, surface: 8.9)
    }
}
