import Foundation

enum GameStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case final_ = "final"
}

enum PlateAppearanceResultType: String, Codable, CaseIterable, Sendable {
    case hit
    case out
    case walk
    case error

    var label: String {
        switch self {
        case .hit: "ヒット"
        case .out: "アウト"
        case .walk: "四死球"
        case .error: "エラー"
        }
    }
}

enum PlateAppearanceResultDetail: String, Codable, CaseIterable, Sendable {
    case single
    case double
    case triple
    case hr
    case k
    case ground
    case fly
    case line
    case dp
    case sacBunt = "sac_bunt"
    case sacFly = "sac_fly"
    case other
    case bb
    case hbp
    case e

    var label: String {
        switch self {
        case .single: "単打"
        case .double: "二塁打"
        case .triple: "三塁打"
        case .hr: "本塁打"
        case .k: "三振"
        case .ground: "ゴロ"
        case .fly: "フライ"
        case .line: "ライナー"
        case .dp: "併殺"
        case .sacBunt: "犠打"
        case .sacFly: "犠飛"
        case .other: "その他"
        case .bb: "四球"
        case .hbp: "死球"
        case .e: "エラー"
        }
    }

    var systemImage: String {
        switch self {
        case .single: "1.circle"
        case .double: "2.circle"
        case .triple: "3.circle"
        case .hr: "baseball.fill"
        case .k: "xmark"
        case .ground: "arrow.down.right"
        case .fly: "arrow.up.right"
        case .line: "arrow.right"
        case .dp: "chevron.right.2"
        case .sacBunt: "arrow.forward"
        case .sacFly: "arrow.up.to.line"
        case .other: "ellipsis"
        case .bb: "circle"
        case .hbp: "cross.case"
        case .e: "exclamationmark.circle"
        }
    }
}

/// 打席入力画面の選択肢。type と detail は必ず対で扱う。
struct PlateAppearanceResultOption: Hashable, Identifiable, Sendable {
    let type: PlateAppearanceResultType
    let detail: PlateAppearanceResultDetail

    var id: PlateAppearanceResultDetail { detail }

    static let hitOptions: [PlateAppearanceResultOption] = [
        .init(type: .hit, detail: .single),
        .init(type: .hit, detail: .double),
        .init(type: .hit, detail: .triple),
        .init(type: .hit, detail: .hr),
    ]

    static let outOptions: [PlateAppearanceResultOption] = [
        .init(type: .out, detail: .k),
        .init(type: .out, detail: .ground),
        .init(type: .out, detail: .fly),
        .init(type: .out, detail: .line),
        .init(type: .out, detail: .dp),
        .init(type: .out, detail: .sacBunt),
        .init(type: .out, detail: .sacFly),
        .init(type: .out, detail: .other),
    ]

    static let onBaseOptions: [PlateAppearanceResultOption] = [
        .init(type: .walk, detail: .bb),
        .init(type: .walk, detail: .hbp),
        .init(type: .error, detail: .e),
    ]
}
