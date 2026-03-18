import SwiftUI

struct CardArtView: View {
    let card: SportsCard
    var size: CardSize = .medium

    enum CardSize {
        case thumbnail
        case medium
        case large

        var width: CGFloat {
            switch self {
            case .thumbnail: return 48
            case .medium: return 120
            case .large: return 180
            }
        }

        var height: CGFloat {
            switch self {
            case .thumbnail: return 66
            case .medium: return 168
            case .large: return 252
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .thumbnail: return 20
            case .medium: return 40
            case .large: return 56
            }
        }

        var playerSize: CGFloat {
            switch self {
            case .thumbnail: return 28
            case .medium: return 64
            case .large: return 90
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .thumbnail: return 8
            case .medium: return 12
            case .large: return 14
            }
        }

        var showDetails: Bool {
            self != .thumbnail
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: card.sport.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            holoOverlay

            playerSilhouette

            if size.showDetails {
                cardDecorations
            }

            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            CSColor.signalPrimary.opacity(0.15),
                            Color.white.opacity(0.2),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size == .thumbnail ? 0.5 : 1.5
                )
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: card.sport.accentColor.opacity(0.3), radius: size == .large ? 20 : 8, y: size == .large ? 12 : 4)
    }

    private var holoOverlay: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.03),
                        card.sport.accentColor.opacity(0.08),
                        Color.white.opacity(0.02),
                        card.sport.accentColor.opacity(0.05),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var playerSilhouette: some View {
        Image(systemName: card.sport.icon)
            .font(.system(size: size.playerSize, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.7),
                        card.sport.accentColor.opacity(0.5),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: card.sport.accentColor.opacity(0.4), radius: 8)
    }

    @ViewBuilder
    private var cardDecorations: some View {
        VStack {
            HStack {
                if size == .large {
                    Text(card.brand.uppercased())
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .tracking(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
                if let grade = card.grade {
                    Text(grade)
                        .font(.system(size: size == .large ? 11 : 9, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, size == .large ? 8 : 6)
                        .padding(.vertical, size == .large ? 4 : 2)
                        .background(
                            LinearGradient(
                                colors: [CSColor.signalPrimary, CSColor.signalPrimary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(size == .large ? 10 : 8)

            Spacer()

            HStack {
                Spacer()
                Text("#\(card.cardNumber)")
                    .font(.system(size: size == .large ? 11 : 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .padding(size == .large ? 10 : 8)
        }

        VStack {
            Spacer()
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, card.sport.gradientColors.first!.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: size.height * 0.25)
        }
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
    }
}

#Preview("CardArtView - Sizes") {
    HStack(spacing: 20) {
        CardArtView(card: MockData.lukaDoncic, size: .thumbnail)
        CardArtView(card: MockData.lukaDoncic, size: .medium)
        CardArtView(card: MockData.lukaDoncic, size: .large)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("CardArtView - Sports") {
    HStack(spacing: 16) {
        CardArtView(card: MockData.lukaDoncic, size: .medium)
        CardArtView(card: MockData.ohtani, size: .medium)
        CardArtView(card: MockData.mahomes, size: .medium)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

struct CardArtGridView: View {
    let card: SportsCard

    var body: some View {
        ZStack {
            LinearGradient(
                colors: card.sport.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: card.sport.icon)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            card.sport.accentColor.opacity(0.4),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: card.sport.accentColor.opacity(0.3), radius: 6)

            if let grade = card.grade {
                VStack {
                    HStack {
                        Spacer()
                        Text(grade)
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CSColor.signalPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
    }
}

struct ScanBeamView: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, CSColor.signalPrimary, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .shadow(color: CSColor.signalPrimary.opacity(0.5), radius: 8)
                .offset(y: offset)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        offset = geo.size.height - 4
                    }
                }
        }
    }
}

struct CornerBracket: Shape {
    let corner: Corner
    let bracketSize: CGFloat

    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let s = bracketSize

        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: 0, y: s))
            path.addLine(to: CGPoint(x: 0, y: 4))
            path.addQuadCurve(to: CGPoint(x: 4, y: 0), control: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: s, y: 0))
        case .topRight:
            path.move(to: CGPoint(x: rect.maxX - s, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX - 4, y: 0))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: 4), control: CGPoint(x: rect.maxX, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: s))
        case .bottomLeft:
            path.move(to: CGPoint(x: 0, y: rect.maxY - s))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY - 4))
            path.addQuadCurve(to: CGPoint(x: 4, y: rect.maxY), control: CGPoint(x: 0, y: rect.maxY))
            path.addLine(to: CGPoint(x: s, y: rect.maxY))
        case .bottomRight:
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - s))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - 4, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - s, y: rect.maxY))
        }

        return path
    }
}

struct ViewfinderFrame: View {
    var color: Color = CSColor.signalPrimary

    var body: some View {
        GeometryReader { geo in
            let s: CGFloat = 32
            ZStack {
                CornerBracket(corner: .topLeft, bracketSize: s)
                    .stroke(color, lineWidth: 2.5)
                CornerBracket(corner: .topRight, bracketSize: s)
                    .stroke(color, lineWidth: 2.5)
                CornerBracket(corner: .bottomLeft, bracketSize: s)
                    .stroke(color, lineWidth: 2.5)
                CornerBracket(corner: .bottomRight, bracketSize: s)
                    .stroke(color, lineWidth: 2.5)
            }
        }
    }
}
