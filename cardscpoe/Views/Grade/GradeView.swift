import SwiftUI

struct GradeView: View {
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
        ZStack {
            CardArtView(card: card, size: .large)

            LinearGradient(
                colors: [.clear, CSColor.signalPrimary.opacity(0.05)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .frame(width: 180, height: 252)

            ZStack {
                cornerMark(x: -72, y: -108)
                cornerMark(x: 72, y: -108, rotation: 90)
                cornerMark(x: -72, y: 108, rotation: -90)
                cornerMark(x: 72, y: 108, rotation: 180)
            }
            .frame(width: 180, height: 252)
        }
        .padding(.bottom, CSSpacing.md)
    }

    private func cornerMark(x: CGFloat, y: CGFloat, rotation: Double = 0) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 16))
            path.addLine(to: CGPoint(x: 0, y: 2))
            path.addQuadCurve(to: CGPoint(x: 2, y: 0), control: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 16, y: 0))
        }
        .stroke(CSColor.signalPrimary, lineWidth: 2)
        .frame(width: 18, height: 18)
        .rotationEffect(.degrees(rotation))
        .offset(x: x, y: y)
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
                Text("9.5")
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .foregroundStyle(CSColor.signalGold)
            }
            .padding(.bottom, CSSpacing.xs)

            Text("Gem Mint Condition · /10")
                .font(CSFont.caption())
                .foregroundStyle(CSColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, CSSpacing.md)

            gradeBarRow(label: "Centering", value: 0.95, score: "9.5", color: CSColor.signalPrimary)
            gradeBarRow(label: "Corners", value: 1.0, score: "10.0", color: CSColor.signalGold)
            gradeBarRow(label: "Edges", value: 0.9, score: "9.0", color: CSColor.signalTertiary)
            gradeBarRow(label: "Surface", value: 0.95, score: "9.5", color: CSColor.signalPrimary)
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
                Text("This card has a ")
                    .foregroundStyle(CSColor.textSecondary) +
                Text("high chance of receiving PSA 9 or 10")
                    .foregroundStyle(CSColor.signalPrimary)
                    .bold() +
                Text(". We recommend submitting for professional grading. Estimated value increase: ")
                    .foregroundStyle(CSColor.textSecondary) +
                Text("+65–120%")
                    .foregroundStyle(CSColor.signalPrimary)
                    .bold()
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
}
