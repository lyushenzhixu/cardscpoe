//
//  NyxTheme.swift
//  cardscpoe
//
//  CardScope 设计系统 — Nyx Design Tokens
//

import SwiftUI

// MARK: - Design Tokens

enum NyxTheme {
    // Surface hierarchy (OLED optimized)
    static let surfacePrimary = Color(hex: 0x000000)
    static let surfaceSecondary = Color(hex: 0x121217)
    static let surfaceElevated = Color(hex: 0x1A1A21)
    
    // Signal colors
    static let signalPrimary = Color(hex: 0x00FF88)   // AI green — scan/identify
    static let signalWarm = Color(hex: 0xFF6B35)      // Warnings, price drops
    static let signalTertiary = Color(hex: 0x8B5CF6)   // Premium/pro
    static let signalGold = Color(hex: 0xF5C842)       // Value, PSA grades
    static let signalGoldDim = Color(hex: 0xF5C842).opacity(0.15)
    
    // Text hierarchy
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.4)
    
    // Semantic
    static let border = Color(hex: 0x1A1A24)
    static let borderSubtle = Color(hex: 0x1A1A24).opacity(0.5)
    
    /// Alias for views using NyxTheme.Color.*
    enum Color {
        static let surfacePrimary = NyxTheme.surfacePrimary
        static let surfaceSecondary = NyxTheme.surfaceSecondary
        static let surfaceElevated = NyxTheme.surfaceElevated
        static let signalPrimary = NyxTheme.signalPrimary
        static let signalWarm = NyxTheme.signalWarm
        static let signalTertiary = NyxTheme.signalTertiary
        static let signalGold = NyxTheme.signalGold
        static let textPrimary = NyxTheme.textPrimary
        static let textSecondary = NyxTheme.textSecondary
        static let textTertiary = NyxTheme.textTertiary
        static let border = NyxTheme.border
        static let borderSubtle = NyxTheme.borderSubtle
    }
    
    /// Layout tokens (Spacing + Radius)
    enum Layout {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let radiusSm: CGFloat = 8
        static let radiusMd: CGFloat = 14
        static let radiusLg: CGFloat = 20
        static let pill: CGFloat = 999
    }
    
    // Typography
    enum FontSize {
        static let display: CGFloat = 34
        static let title: CGFloat = 22
        static let headline: CGFloat = 17
        static let body: CGFloat = 15
        static let caption: CGFloat = 12
        static let data: CGFloat = 14
    }
    
    // Spacing (4pt grid)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // Corner radii
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let pill: CGFloat = 999
    }
}

// MARK: - Button Style

struct NyxPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Button Style

struct NyxPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, opacity: alpha)
    }
}
