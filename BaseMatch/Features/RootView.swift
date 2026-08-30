import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme

    @State private var store: AppStore?
    @State private var settings = AppSettings()
    @State private var isInitialized = false

    /// テーマ選択を反映した実効値。配色はこちらを基準に決める。
    private var effectiveColorScheme: ColorScheme {
        settings.theme.colorScheme ?? systemColorScheme
    }

    var body: some View {
        ZStack {
            if let store, isInitialized {
                MainTabView()
                    .environment(store)
                    .transition(.opacity)
            } else {
                SplashView()
                    .transition(.opacity)
            }
        }
        .environment(settings)
        .environment(\.locale, settings.language.locale ?? .autoupdatingCurrent)
        .preferredColorScheme(settings.theme.colorScheme)
        .provideAppColors(effectiveColorScheme)
        .task {
            if store == nil {
                if DemoDataSeeder.isRequested {
                    try? DemoDataSeeder.seed(context: modelContext)
                }
                let store = AppStore(context: modelContext)
                store.load()
                self.store = store
            }
            // 移行元と同じくスプラッシュを 1.5 秒見せる。
            try? await Task.sleep(for: .milliseconds(1500))
            withAnimation(.smooth(duration: 0.45)) { isInitialized = true }
        }
    }
}

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var isVisible = false

    var body: some View {
        ZStack {
            HeroBackground(colorScheme: colorScheme)
                .ignoresSafeArea()

            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.86)
                .blur(radius: isVisible ? 0 : 6)
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.9)) { isVisible = true }
        }
    }
}

enum AppTab: Hashable {
    case home, record, stats
}

struct MainTabView: View {
    @Environment(\.appColors) private var colors
    @State private var selection: AppTab = .home

    var body: some View {
        tabs
            .tint(colors.primary)
            .sensoryFeedback(.selection, trigger: selection)
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 18, *) {
            TabView(selection: $selection) {
                Tab(String(localized: L10n.navHome), systemImage: "house", value: AppTab.home) {
                    HomeView(selection: $selection)
                }
                Tab(String(localized: L10n.navRecord), systemImage: "baseball", value: AppTab.record) {
                    GamesView()
                }
                Tab(String(localized: L10n.navStats), systemImage: "chart.bar", value: AppTab.stats) {
                    StatsView(selection: $selection)
                }
            }
        } else {
            TabView(selection: $selection) {
                HomeView(selection: $selection)
                    .tabItem { Label(L10n.navHome, systemImage: "house") }
                    .tag(AppTab.home)
                GamesView()
                    .tabItem { Label(L10n.navRecord, systemImage: "baseball") }
                    .tag(AppTab.record)
                StatsView(selection: $selection)
                    .tabItem { Label(L10n.navStats, systemImage: "chart.bar") }
                    .tag(AppTab.stats)
            }
        }
    }
}
