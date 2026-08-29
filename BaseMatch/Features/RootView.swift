import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var store: AppStore?
    @State private var isInitialized = false

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
        .provideAppColors(colorScheme)
        .environment(\.locale, Locale(identifier: "ja_JP"))
        .task {
            if store == nil {
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
            AppTheme.heroMesh(for: colorScheme)
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
        TabView(selection: $selection) {
            Tab(L10n.navHome, systemImage: "house", value: AppTab.home) {
                HomeView(selection: $selection)
            }
            Tab(L10n.navRecord, systemImage: "baseball", value: AppTab.record) {
                GamesView()
            }
            Tab(L10n.navStats, systemImage: "chart.bar", value: AppTab.stats) {
                StatsView(selection: $selection)
            }
        }
        .tint(colors.primary)
        .sensoryFeedback(.selection, trigger: selection)
    }
}
