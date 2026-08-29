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
            for team in activeTeams where team.isDefault {
                team.isDefault = false
            }
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
}
