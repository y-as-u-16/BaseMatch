import Foundation
import SwiftData

@MainActor
struct MyTeamRepository {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// アーカイブ済みは除外し、表示順 → 作成順で返す。
    func myTeams() throws -> [MyTeam] {
        let descriptor = FetchDescriptor<MyTeam>(
            predicate: #Predicate { $0.archivedAt == nil },
            sortBy: [
                SortDescriptor(\.displayOrder),
                SortDescriptor(\.createdAt),
            ]
        )
        return try context.fetch(descriptor)
    }

    func defaultMyTeam() throws -> MyTeam? {
        try myTeams().first { $0.isDefault }
    }

    @discardableResult
    func createMyTeam(
        name: String,
        colorKey: String? = nil,
        isDefault: Bool = false
    ) throws -> MyTeam {
        guard !name.trimmed.isEmpty else {
            throw AppError.validation("チーム名を入力してください")
        }

        let activeTeams = try myTeams()
        let shouldBeDefault = isDefault || activeTeams.isEmpty
        let displayOrder = (activeTeams.map(\.displayOrder).max() ?? -1) + 1

        if shouldBeDefault {
            clearDefaultFlags(in: activeTeams)
        }

        let team = MyTeam(
            name: name.trimmed,
            colorKey: colorKey?.normalizedOptional,
            isDefault: shouldBeDefault,
            displayOrder: displayOrder
        )
        context.insert(team)
        try context.save()
        return team
    }

    func setDefaultMyTeam(id: String) throws {
        let activeTeams = try myTeams()
        guard let target = activeTeams.first(where: { $0.id == id }) else {
            throw AppError.validation("チームが見つかりません")
        }

        clearDefaultFlags(in: activeTeams)
        target.isDefault = true
        target.updatedAt = Date()
        try context.save()
    }

    func renameMyTeam(id: String, name: String) throws {
        let trimmed = name.trimmed
        guard !trimmed.isEmpty else {
            throw AppError.validation("チーム名を入力してください")
        }
        guard let team = try myTeams().first(where: { $0.id == id }) else {
            throw AppError.notFound("チームが見つかりません")
        }

        team.name = trimmed
        team.updatedAt = Date()
        try context.save()
    }

    /// チームを消すと所属選手と試合が宙に浮くため、まとめて削除する。
    /// 選手個別の削除と違い、残しても「不明なチーム」の試合になるだけで意味がない。
    func deleteMyTeam(
        id: String,
        gameRepository: GameRepository,
        playerRepository: PlayerRepository
    ) throws {
        guard let team = try myTeams().first(where: { $0.id == id }) else { return }

        for game in try gameRepository.games() where game.myTeamId == id {
            try gameRepository.deleteGame(id: game.id)
        }
        try context.delete(model: Player.self, where: #Predicate { $0.myTeamId == id })

        let wasDefault = team.isDefault
        context.delete(team)
        try context.save()

        // デフォルトが居ないと試合作成で自チームを選べない。
        if wasDefault, let next = try myTeams().first {
            next.isDefault = true
            try context.save()
        }
    }

    /// デフォルトは常に1件だけ。新たに立てる前に既存を落とす。
    private func clearDefaultFlags(in teams: [MyTeam]) {
        for team in teams where team.isDefault {
            team.isDefault = false
        }
    }
}
