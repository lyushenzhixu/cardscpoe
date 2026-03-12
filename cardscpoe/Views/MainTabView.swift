//
//  MainTabView.swift
//  cardscpoe
//
//  CardScope 主 Tab 导航
//

import SwiftUI

enum AppTab: Int, CaseIterable {
    case home = 0
    case explore = 1
    case scan = 2
    case collection = 3
    case profile = 4
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: AppTab = .home
    @State private var showScanner = false
    @State private var showPaywall = false
    
    var body: some View {
        MainTabContent(
            appState: appState,
            selectedTab: $selectedTab,
            showScanner: $showScanner,
            showPaywall: $showPaywall
        )
    }
}

private struct MainTabContent: View {
    @Bindable var appState: AppState
    @Binding var selectedTab: AppTab
    @Binding var showScanner: Bool
    @Binding var showPaywall: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .explore:
                    ExplorePlaceholderView()
                case .scan:
                    Color(NyxTheme.surfacePrimary)
                case .collection:
                    CollectionView(
                        collection: Binding(
                            get: { appState.collectionCards },
                            set: { appState.collectionCards = $0 }
                        ),
                        onCardTapped: { appState.showDetailCard = $0 },
                        onShowPaywall: { showPaywall = true }
                    )
                case .profile:
                    ProfilePlaceholderView(onShowPaywall: { showPaywall = true })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            customTabBar
        }
        .environment(appState)
        .fullScreenCover(isPresented: $showScanner) {
            ScannerView(
                onDismiss: { showScanner = false },
                onScanComplete: { card in
                    showScanner = false
                    appState.navigateToCard = card
                }
            )
            .environment(appState)
        }
        .fullScreenCover(item: $appState.navigateToCard) { card in
            ResultView(
                card: card,
                onRescan: {
                    appState.navigateToCard = nil
                    showScanner = true
                },
                onAddToCollection: {
                    if !appState.collectionCards.contains(where: { $0.id == card.id }) {
                        appState.collectionCards.append(card)
                    }
                    appState.navigateToCard = nil
                },
                onViewDetail: {
                    appState.navigateToCard = nil
                    appState.showDetailCard = card
                }
            )
        }
        .fullScreenCover(item: $appState.showDetailCard) { card in
            CardDetailView(card: card) {
                appState.showDetailCard = nil
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .scan {
                showScanner = true
                selectedTab = .home
            }
        }
        .onChange(of: appState.selectedTab) { _, newValue in
            if newValue == .scan {
                showScanner = true
                selectedTab = .home
            } else if let tab = AppTab(rawValue: newValue.rawValue) {
                selectedTab = tab
            }
        }
    }
    
    private var customTabBar: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                if tab == .scan {
                    scanButton
                } else {
                    tabButton(tab)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 28)
        .background(
            Color(NyxTheme.surfaceSecondary)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(NyxTheme.borderSubtle),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selectedTab = tab
            appState.selectedTab = MainTab(rawValue: tab.rawValue) ?? .home
        } label: {
            VStack(spacing: 3) {
                Image(systemName: iconForTab(tab))
                    .font(.system(size: 20))
                    .scaleEffect(selectedTab == tab ? 1.1 : 1)
                Text(labelForTab(tab))
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? NyxTheme.textPrimary : NyxTheme.textTertiary)
            .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
    
    private var scanButton: some View {
        Button {
            showScanner = true
        } label: {
            ZStack {
                Circle()
                    .fill(NyxTheme.signalPrimary)
                    .frame(width: 52, height: 52)
                    .shadow(color: NyxTheme.signalPrimary.opacity(0.5), radius: 12, x: 0, y: 4)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.black)
            }
        }
        .buttonStyle(NyxPressableStyle())
        .offset(y: -8)
    }
    
    private func iconForTab(_ tab: AppTab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .explore: return "magnifyingglass"
        case .scan: return "camera.fill"
        case .collection: return "folder.fill"
        case .profile: return "person.fill"
        }
    }
    
    private func labelForTab(_ tab: AppTab) -> String {
        switch tab {
        case .home: return "首页"
        case .explore: return "发现"
        case .scan: return "扫描"
        case .collection: return "收藏"
        case .profile: return "我的"
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState.shared)
        .preferredColorScheme(.dark)
}
