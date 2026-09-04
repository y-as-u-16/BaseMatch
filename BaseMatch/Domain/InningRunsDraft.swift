import Foundation

/// 試合作成・編集画面が持つイニング別得点の下書き。
///
/// `home` / `away` は先攻・後攻の枠であって自チームの枠ではない。表・裏の枠は
/// 固定なので、先攻・後攻を切り替えたら中身を入れ替えないと、入力済みの得点が
/// 相手のものとして保存される。
struct InningRunsDraft: Equatable, Sendable {
    private(set) var home: [Int]
    private(set) var away: [Int]

    init(home: [Int] = [], away: [Int] = []) {
        self.home = home
        self.away = away
    }

    var isEmpty: Bool { home.isEmpty && away.isEmpty }

    var homeTotal: Int { home.reduce(0, +) }
    var awayTotal: Int { away.reduce(0, +) }

    /// 先攻・後攻の切り替えに追従させる。自チームの得点は自チームについていく。
    mutating func swapHalves() {
        swap(&home, &away)
    }

    /// イニング数を増やしたときに配列が短いままだと参照で落ちるため、読み出しは 0 で補う。
    func runs(isHome: Bool, inningIndex: Int) -> Int {
        let runs = isHome ? home : away
        return inningIndex < runs.count ? runs[inningIndex] : 0
    }

    mutating func setRuns(_ value: Int, isHome: Bool, inningIndex: Int, innings: Int) {
        var runs = isHome ? home : away
        if runs.count < innings {
            runs.append(contentsOf: Array(repeating: 0, count: innings - runs.count))
        }
        guard inningIndex < runs.count else { return }
        runs[inningIndex] = value
        if isHome { home = runs } else { away = runs }
    }

    /// イニング数を減らしたら余った回の得点は捨てる。合計に紛れ込むのを防ぐ。
    mutating func trim(to innings: Int) {
        if home.count > innings { home = Array(home.prefix(innings)) }
        if away.count > innings { away = Array(away.prefix(innings)) }
    }

    /// 表裏で長さがずれるとラインスコアの列が揃わないため、選んだイニング数まで 0 で埋める。
    func padded(to innings: Int) -> (home: [Int], away: [Int]) {
        (Self.pad(home, to: innings), Self.pad(away, to: innings))
    }

    private static func pad(_ runs: [Int], to innings: Int) -> [Int] {
        guard runs.count < innings else { return Array(runs.prefix(innings)) }
        return runs + Array(repeating: 0, count: innings - runs.count)
    }
}
