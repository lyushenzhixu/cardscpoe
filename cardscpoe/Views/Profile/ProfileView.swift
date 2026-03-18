import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                profileCard
                menuSections
                Spacer().frame(height: 100)
            }
        }
        .background(CSColor.surfacePrimary)
    }

    private var header: some View {
        Text("Profile")
            .font(CSFont.title(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CSSpacing.md)
            .padding(.vertical, CSSpacing.sm)
    }

    private var profileCard: some View {
        HStack(spacing: CSSpacing.md) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [CSColor.signalPrimary.opacity(0.3), CSColor.signalPrimary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(CSColor.signalPrimary)
                )

            VStack(alignment: .leading, spacing: CSSpacing.xs) {
                Text("Card Collector")
                    .font(CSFont.headline(.bold))

                HStack(spacing: CSSpacing.sm) {
                    Text(appState.subscription.planDisplayName)
                        .font(CSFont.caption(.semibold))
                        .foregroundStyle(CSColor.textTertiary)
                    Text("·")
                        .foregroundStyle(CSColor.textTertiary)
                    Button {
                        appState.presentPaywall(source: .profile)
                    } label: {
                        Text("Upgrade to Pro")
                            .font(CSFont.caption(.bold))
                            .foregroundStyle(CSColor.signalPrimary)
                    }
                }
            }

            Spacer()
        }
        .nyxCard()
        .padding(.horizontal, CSSpacing.md)
        .padding(.bottom, CSSpacing.md)
    }

    private var menuSections: some View {
        VStack(spacing: CSSpacing.md) {
            menuSection(title: "ACCOUNT", items: [
                MenuItem(icon: "person.circle", title: "Account Settings"),
                MenuItem(icon: "crown.fill", title: "Subscription", subtitle: appState.subscription.planDisplayName, accentColor: CSColor.signalPrimary),
                MenuItem(icon: "bell.fill", title: "Notifications"),
            ])

            menuSection(title: "DATA", items: [
                MenuItem(icon: "clock.arrow.circlepath", title: "Scan History", subtitle: "\(appState.recentScans.count) scans"),
                MenuItem(icon: "square.and.arrow.up", title: "Export Collection"),
                MenuItem(icon: "icloud.and.arrow.down", title: "Backup & Sync"),
            ])

            menuSection(title: "SUPPORT", items: [
                MenuItem(icon: "questionmark.circle", title: "Help Center"),
                MenuItem(icon: "envelope", title: "Contact Us"),
                MenuItem(icon: "star.fill", title: "Rate CardScope", accentColor: CSColor.signalPrimary),
                MenuItem(icon: "info.circle", title: "About", subtitle: "v1.0.0"),
            ])

            Button {
                appState.hasSeenOnboarding = false
            } label: {
                Text("Reset Onboarding (Debug)")
                    .font(CSFont.caption(.semibold))
                    .foregroundStyle(CSColor.signalWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CSSpacing.md)
                    .background(CSColor.signalWarm.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: CSRadius.sm))
            }
            .padding(.horizontal, CSSpacing.md)
            .padding(.top, CSSpacing.md)
        }
    }

    private func menuSection(title: String, items: [MenuItem]) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CSColor.textTertiary)
                .tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CSSpacing.md)
                .padding(.bottom, CSSpacing.sm)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    menuRow(item)
                    if index < items.count - 1 {
                        Divider()
                            .background(CSColor.borderSubtle)
                            .padding(.leading, 52)
                    }
                }
            }
            .background(CSColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: CSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CSRadius.md)
                    .stroke(CSColor.borderSubtle, lineWidth: 0.5)
            )
            .padding(.horizontal, CSSpacing.md)
        }
    }

    private func menuRow(_ item: MenuItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 16))
                .foregroundStyle(item.accentColor ?? CSColor.textSecondary)
                .frame(width: 24)

            Text(item.title)
                .font(CSFont.body())
                .foregroundStyle(CSColor.textPrimary)

            Spacer()

            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(CSFont.caption())
                    .foregroundStyle(CSColor.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CSColor.textTertiary)
        }
        .padding(.horizontal, CSSpacing.md)
        .padding(.vertical, 12)
    }
}

#Preview("ProfileView") {
    PreviewContainer {
        NavigationStack {
            ProfileView()
        }
    }
}

private struct MenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    var subtitle: String? = nil
    var accentColor: Color? = nil
}
