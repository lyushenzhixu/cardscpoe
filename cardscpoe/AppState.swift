//
//  AppState.swift
//  cardscpoe
//
//  全局应用状态管理
//

import SwiftUI

@Observable
final class AppState {
    static let shared = AppState()
    
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    var selectedTab: MainTab = .home
    var showScanner: Bool = false
    var navigateToCard: CardItem?  // 点击卡片后显示识别结果
    var showDetailCard: CardItem?  // 显示卡片详情
    var lastScannedCard: CardItem?
    var navigationPath: [AppRoute] = []
    
    var collectionCards: [CardItem] = DemoData.collectionCards
    var recentScanned: [CardItem] = DemoData.recentScanned
    
    var recentCards: [CardItem] { recentScanned }
    var trendingCards: [CardItem] { [.mockWembanyama, .mockSoccer] }
}

enum MainTab: Int, CaseIterable {
    case home = 0
    case explore = 1
    case scan = 2  // 中间扫描按钮
    case collection = 3
    case profile = 4
    
    var title: String {
        switch self {
        case .home: return "首页"
        case .explore: return "发现"
        case .scan: return "扫描"
        case .collection: return "收藏"
        case .profile: return "我的"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "magnifyingglass"
        case .scan: return "camera.fill"
        case .collection: return "folder.fill"
        case .profile: return "person.fill"
        }
    }
}

enum AppRoute: Hashable {
    case result(CardItem)
    case detail(CardItem)
    case paywall
}
