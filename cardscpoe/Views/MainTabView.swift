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
            PaywallView()
        }
        .sheet(isPresented: $state.showingGrade) {
            if let card = appState.gradeCard {
                NavigationStack {
                    GradeView(card: card)
                }
            }
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
        .padding(.top, CSSpacing.sm)
        .padding(.bottom, 28)
        .padding(.horizontal, 10)
        .background(
            CSColor.surfaceSecondary
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(CSColor.border)
                        .frame(height: 0.5)
                }
        )
    }

    private func tabItem(_ tab: TabItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                    .scaleEffect(appState.selectedTab == tab ? 1.1 : 1.0)
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(appState.selectedTab == tab ? CSColor.textPrimary : CSColor.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
        }
    }

    private var scanButton: some View {
        Button {
            appState.showingScan = true
        } label: {
            ZStack {
                Circle()
                    .fill(CSColor.signalPrimary)
                    .frame(width: 52, height: 52)
                    .shadow(color: CSColor.signalPrimary.opacity(0.3), radius: 10)

                Circle()
                    .stroke(CSColor.signalPrimary.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)

                Image(systemName: "camera.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.black)
            }
            .offset(y: -6)
        }
        .buttonStyle(NyxPressableStyle())
        .frame(maxWidth: .infinity)
    }
}
