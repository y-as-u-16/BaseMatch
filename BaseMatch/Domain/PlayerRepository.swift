import Foundation
import SwiftData

@MainActor
struct PlayerRepository {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// アーカイブ済みは除外し、表示順 → 作成順で返す。
    func players(myTeamId: String) throws -> [Player] {
        let descriptor = FetchDescriptor<Player>(
            predicate: #Predicate { $0.myTeamId == myTeamId && $0.archivedAt == nil },
            sortBy: [
                SortDescriptor(\.displayOrder),
                SortDescriptor(\.createdAt),
            ]
        )
        return try context.fetch(descriptor)
    }

    func allPlayers() throws -> [Player] {
        let descriptor = FetchDescriptor<Player>(
            predicate: #Predicate { $0.archivedAt == nil },
            sortBy: [
                SortDescriptor(\.displayOrder),
                SortDescriptor(\.createdAt),
            ]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func createPlayer(name: String, myTeamId: String) throws -> Player {
        let trimmed = name.trimmed
        guard !trimmed.isEmpty else {
            throw AppError.validation("選手名を入力してください")
        }

        let existing = try players(myTeamId: myTeamId)
        guard !existing.contains(where: { $0.name == trimmed }) else {
            throw AppError.validation("同じ名前の選手が登録されています")
        }

        let player = Player(
            name: trimmed,
            myTeamId: myTeamId,
            displayOrder: (existing.map(\.displayOrder).max() ?? -1) + 1
        )
        context.insert(player)
        try context.save()
        return player
    }

    /// 過去の記録は選手名を文字列で持っているため、選手を消しても成績は残る。
    func deletePlayer(id: String) throws {
        try context.delete(model: Player.self, where: #Predicate { $0.id == id })
        try context.save()
    }
}
