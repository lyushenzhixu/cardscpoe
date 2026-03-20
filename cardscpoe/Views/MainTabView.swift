import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .home:
                    NavigationStack { HomeView() }
                case .explore:
                    NavigationStack { ExploreView() }
                case .scan:
                    Color.clear
                case .collection:
                    NavigationStack { CollectionView() }
                case .profile:
                    NavigationStack { ProfileView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
        .fullScreenCover(isPresented: $state.showingScan) {
            ScanView()
        }
        .sheet(isPresented: $state.showingResult) {
            if let card = appState.scannedCard {
                NavigationStack {
                    ScanResultView(card: card)
                }
            } else {
                NavigationStack {
                    CardNotFoundView()
                }
            }
        }
        .sheet(isPresented: $state.showingDetail) {
            if let card = appState.selectedDetailCard {
                NavigationStack {
                    CardDetailView(card: card)
                }
            }
        }
        .sheet(isPresented: $state.showingPaywall) {
            PaywallView(
                source: appState.activePaywallSource,
                variant: appState.subscription.paywallVariant
            )
        }
        .preferredColorScheme(.dark)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(.home)
            tabItem(.explore)
            scanButton
            tabItem(.collection)
            tabItem(.profile)
        }
        .frame(height: 62)
        .padding(.horizontal, CSSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(CSColor.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.xl)
    }

    private func tabItem(_ tab: TabItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18))
                Text(tab.title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(appState.selectedTab == tab ? CSColor.textOnPrimary : Color.white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(
                Group {
                    if appState.selectedTab == tab {
                        RoundedRectangle(cornerRadius: CSRadius.pill)
                            .fill(CSColor.signalPrimary)
                            .padding(.horizontal, CSSpacing.xs)
                            .padding(.vertical, CSSpacing.xs)
                    }
                }
            )
        }
    }

    private var scanButton: some View {
        Button {
            if appState.canStartScanFlow() {
                appState.showingScan = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(CSColor.signalPrimary)
                    .frame(width: 52, height: 52)
                    .shadow(color: Color(red: 0x3E/255, green: 0xCF/255, blue: 0xA0/255).opacity(0.25), radius: 16)

                Image(systemName: "viewfinder")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(CSColor.textOnPrimary)
            }
            .offset(y: -6)
        }
        .buttonStyle(NyxPressableStyle())
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PreviewContainer {
        MainTabView()
    }
}
