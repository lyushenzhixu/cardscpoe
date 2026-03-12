//
//  CardImageHelper.swift
//  cardscpoe
//
//  根据 cardscope图片.md 规范，图片资源命名与占位符
//  生成图片后可放入 Assets 对应名称的 Image Set
//

import SwiftUI

/// 图片资源名称 - 与 cardscope图片.md 规格汇总对应
enum CardImageAsset: String, CaseIterable {
    // Onboarding
    case obScanCard = "ob_scan_card"
    case obValueCard = "ob_value_card"
    case obGradeCard = "ob_grade_card"
    case obPortfolio = "ob_portfolio"
    
    // 球员卡
    case cardBasketballLuka = "card_basketball_luka"
    case cardBaseballOhtani = "card_baseball_ohtani"
    case cardFootballMahomes = "card_football_mahomes"
    case cardBasketballWemby = "card_basketball_wemby"
    case cardSoccerBellingham = "card_soccer_bellingham"
    
    // 缩略图
    case thumbBasketball = "thumb_basketball"
    case thumbBaseball = "thumb_baseball"
    case thumbFootball = "thumb_football"
    case thumbBasketballWemby = "thumb_basketball_wemby"
    case thumbSoccer = "thumb_soccer"
    
    // 扫描/相机
    case cameraPlaceholder = "camera_placeholder"
    case scanSuccess = "scan_success"
    case aiGradeOverlay = "ai_grade_overlay"
    
    // Paywall
    case collectionShowcase = "collection_showcase"
    case rawVsGraded = "raw_vs_graded"
    
    // 空状态
    case emptyState = "empty_state"
    case notFoundState = "not_found_state"
    
    // 效果
    case holoTexture = "holo_texture"
    case scanLineGlow = "scan_line_glow"
}

/// 运动类型对应的占位 emoji
enum SportEmoji: String {
    case basketball = "🏀"
    case baseball = "⚾"
    case football = "🏈"
    case soccer = "⚽"
    
    static func forSport(_ sport: String) -> String {
        switch sport.lowercased() {
        case "nba", "basketball": return basketball.rawValue
        case "mlb", "baseball": return baseball.rawValue
        case "nfl", "football": return football.rawValue
        case "soccer", "ucl": return soccer.rawValue
        default: return "🃏"
        }
    }
}

/// 卡片图片视图 - 优先使用 Asset 图片，否则显示占位符（emoji + 渐变背景）
struct CardImageView: View {
    let sport: String
    let assetName: String?
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    
    init(sport: String = "basketball", assetName: String? = nil, aspectRatio: CGFloat = 360/504, cornerRadius: CGFloat = 14) {
        self.sport = sport
        self.assetName = assetName
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
    }
    
    private var emoji: String { SportEmoji.forSport(sport) }
    
    private var gradientColors: [Color] {
        switch sport.lowercased() {
        case "nba", "basketball": return [NyxTheme.surfaceElevated, Color(red: 0.05, green: 0.15, blue: 0.25)]
        case "mlb", "baseball": return [Color(red: 0.15, green: 0.05, blue: 0.05), Color(red: 0.1, green: 0.02, blue: 0.02)]
        case "nfl", "football": return [Color(red: 0.05, green: 0.15, blue: 0.1), Color(red: 0.02, green: 0.08, blue: 0.05)]
        case "soccer": return [Color(red: 0.12, green: 0.12, blue: 0.15), Color(red: 0.06, green: 0.06, blue: 0.1)]
        default: return [NyxTheme.surfaceElevated, NyxTheme.surfaceSecondary]
        }
    }
    
    var body: some View {
        Group {
            if let name = assetName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(emoji)
                        .font(.system(size: 48))
                }
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// 卡片主图视图 - 供 Result/Detail 等使用
struct CardImageViewForItem: View {
    let card: CardItem
    let size: CGSize
    
    private var sportKey: String { card.sport.rawValue.lowercased() }
    
    private var assetName: String? {
        switch card.imageName {
        case "card_basketball": return CardImageAsset.cardBasketballLuka.rawValue
        case "card_baseball": return CardImageAsset.cardBaseballOhtani.rawValue
        case "card_football": return CardImageAsset.cardFootballMahomes.rawValue
        case "card_basketball_rookie": return CardImageAsset.cardBasketballWemby.rawValue
        case "card_soccer": return CardImageAsset.cardSoccerBellingham.rawValue
        default: return card.imageName
        }
    }
    
    var body: some View {
        CardImageView(
            sport: sportKey,
            assetName: UIImage(named: assetName ?? "") != nil ? assetName : nil,
            aspectRatio: size.width / size.height,
            cornerRadius: 14
        )
        .frame(width: size.width, height: size.height)
    }
}

/// 命名空间 - 供 Result/Collection 等调用
enum CardImageHelper {
    static func cardView(for card: CardItem, size: CGSize) -> some View {
        CardImageViewForItem(card: card, size: size)
    }
}

/// Onboarding 步骤图片
struct OnboardingStepImage: View {
    let step: Int
    let size: CGSize
    
    init(step: Int, size: CGSize = CGSize(width: 170, height: 238)) {
        self.step = step
        self.size = size
    }
    
    private var assetName: String? {
        switch step {
        case 0: return CardImageAsset.obScanCard.rawValue
        case 1: return CardImageAsset.obValueCard.rawValue
        case 2: return CardImageAsset.obGradeCard.rawValue
        case 3: return CardImageAsset.obPortfolio.rawValue
        default: return nil
        }
    }
    
    private var emoji: String {
        switch step {
        case 0: return "🏀"
        case 1: return "⚾"
        case 2: return "🏈"
        case 3: return "🏀"
        default: return "🃏"
        }
    }
    
    var body: some View {
        Group {
            if let name = assetName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    NyxTheme.surfaceElevated
                    Text(emoji)
                        .font(.system(size: 60))
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
