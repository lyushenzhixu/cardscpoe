import SwiftUI

enum CSColor {
    static let surfacePrimary = Color.black
    static let surfaceSecondary = Color(red: 18/255, green: 18/255, blue: 23/255)
    static let surfaceElevated = Color(red: 0x1A/255, green: 0x1A/255, blue: 0x22/255)

    static let signalPrimary = Color(red: 0x3E/255, green: 0xCF/255, blue: 0xA0/255)
    static let signalWarm = Color(red: 0xE8/255, green: 0x5D/255, blue: 0x5D/255)
    static let signalTertiary = Color(red: 139/255, green: 92/255, blue: 246/255)
    static let signalGold = Color(red: 245/255, green: 200/255, blue: 66/255)
    static let signalGoldDim = Color(red: 245/255, green: 200/255, blue: 66/255).opacity(0.15)

    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.4)
    static let textOnPrimary = Color.black

    static let border = Color.white.opacity(0.06)
    static let borderSubtle = Color.white.opacity(0.04)
}

enum CSFont {
    static func display(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 34, weight: weight, design: .default)
    }
    static func title(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 22, weight: weight, design: .default)
    }
    static func headline(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 17, weight: weight, design: .default)
    }
    static func body(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 15, weight: weight, design: .default)
    }
    static func caption(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 12, weight: weight, design: .default)
    }
    static func heroValue(_ weight: Font.Weight = .heavy) -> Font {
        .system(size: 42, weight: weight, design: .default)
    }
    static func data(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 14, weight: weight, design: .monospaced)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

enum CSSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum CSRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let pill: CGFloat = 999
}

struct NyxCardModifier: ViewModifier {
    var padding: CGFloat = CSSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(CSColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CSRadius.md)
                    .stroke(CSColor.borderSubtle, lineWidth: 0.5)
            )
    }
}

extension View {
    func nyxCard(padding: CGFloat = CSSpacing.md) -> some View {
        modifier(NyxCardModifier(padding: padding))
    }
}

struct NyxPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CSFont.headline(.bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, CSSpacing.md)
            .background(CSColor.signalPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CSFont.body(.semibold))
            .foregroundStyle(CSColor.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, CSSpacing.md)
            .background(CSColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CSRadius.md)
                    .stroke(CSColor.border, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
