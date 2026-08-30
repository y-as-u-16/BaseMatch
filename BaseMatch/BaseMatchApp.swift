import SwiftData
import SwiftUI

@main
struct BaseMatchApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: MyTeam.self, Player.self, Game.self, PlateAppearance.self, PitchingAppearance.self
            )
        } catch {
            fatalError("SwiftData の初期化に失敗しました: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
