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
        let trimmed = try validatedName(name, myTeamId: myTeamId, excluding: nil)
        let existing = try players(myTeamId: myTeamId)

        let player = Player(
            name: trimmed,
            myTeamId: myTeamId,
            // 1人目は自動でデフォルト。試合記録のたびに選ばせない。
            isDefault: existing.isEmpty,
            displayOrder: (existing.map(\.displayOrder).max() ?? -1) + 1
        )
        context.insert(player)
        try context.save()
        return player
    }

    /// 記録は選手名で紐づくため、改名したら記録側も揃えないと成績が分断される。
    func renamePlayer(id: String, name: String, myTeamId: String) throws {
        let trimmed = try validatedName(name, myTeamId: myTeamId, excluding: id)
        guard let player = try players(myTeamId: myTeamId).first(where: { $0.id == id }) else {
            throw AppError.notFound("選手が見つかりません")
        }

        let oldName = player.name
        player.name = trimmed

        if oldName != trimmed {
            try renameInRecords(from: oldName, to: trimmed, myTeamId: myTeamId)
        }
        try context.save()
    }

    /// 名簿からは消すが、チームの通算成績が変わらないよう記録は残す。
    func deletePlayer(id: String) throws {
        var descriptor = FetchDescriptor<Player>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let player = try context.fetch(descriptor).first else { return }

        let myTeamId = player.myTeamId
        let wasDefault = player.isDefault
        context.delete(player)
        try context.save()

        // デフォルトが居ないと入力のたびに選ばせることになる。
        if wasDefault, let next = try players(myTeamId: myTeamId).first {
            next.isDefault = true
            try context.save()
        }
    }

    func setDefaultPlayer(id: String, myTeamId: String) throws {
        let teamPlayers = try players(myTeamId: myTeamId)
        guard let target = teamPlayers.first(where: { $0.id == id }) else {
            throw AppError.notFound("選手が見つかりません")
        }

        for player in teamPlayers where player.isDefault {
            player.isDefault = false
        }
        target.isDefault = true
        try context.save()
    }

    func defaultPlayer(myTeamId: String) throws -> Player? {
        try players(myTeamId: myTeamId).first { $0.isDefault }
    }

    private func validatedName(
        _ name: String,
        myTeamId: String,
        excluding id: String?
    ) throws -> String {
        let trimmed = name.trimmed
        guard !trimmed.isEmpty else {
            throw AppError.validation("選手名を入力してください")
        }
        let duplicated = try players(myTeamId: myTeamId)
            .contains { $0.name == trimmed && $0.id != id }
        guard !duplicated else {
            throw AppError.validation("同じ名前の選手が登録されています")
        }
        return trimmed
    }

    /// 同じチームの試合に限って選手名を差し替える。
    /// 別チームの同名選手を巻き込まないため試合を経由して絞り込む。
    private func renameInRecords(from oldName: String, to newName: String, myTeamId: String) throws {
        let gameIds = Set(
            try context.fetch(
                FetchDescriptor<Game>(predicate: #Predicate { $0.myTeamId == myTeamId })
            ).map(\.id)
        )

        for record in try context.fetch(
            FetchDescriptor<PlateAppearance>(predicate: #Predicate { $0.batterName == oldName })
        ) where gameIds.contains(record.gameId) {
            record.batterName = newName
        }

        for record in try context.fetch(
            FetchDescriptor<PitchingAppearance>(predicate: #Predicate { $0.pitcherName == oldName })
        ) where gameIds.contains(record.gameId) {
            record.pitcherName = newName
        }
    }
}
