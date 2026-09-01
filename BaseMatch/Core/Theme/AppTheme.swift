import SwiftUI

enum AppTheme {
    static let fieldGreen = Color(hex: 0x1B4332)
    static let leatherBrown = Color(hex: 0x5C4033)
    static let stitchRed = Color(hex: 0xC62828)
    static let baseWhite = Color(hex: 0xFFF8F0)
    static let trophyGold = Color(hex: 0xD4A017)

    /// フローティングタブバーはセーフエリアに含まれないため、スクロール末尾に手動で確保する余白。
    static let floatingTabBarInset: CGFloat = 88

    /// ダークでは fieldGreen が沈んで文字が読めないため、明度を上げた同系色を使う。
    static let fieldGreenDark = Color(hex: 0x6FC49A)
    static let leatherBrownDark = Color(hex: 0xC9A98C)
    static let stitchRedDark = Color(hex: 0xFF8A80)
    static let trophyGoldDark = Color(hex: 0xEFC15A)
}

/// 4pt グリッド。レイアウトの余白はこのトークンだけを使い、直値を書かない。
enum Spacing {
    /// 4pt — アイコンとラベルなど、密着した要素の間。
    static let xxs: CGFloat = 4
    /// 8pt — 行内の要素間。
    static let xs: CGFloat = 8
    /// 12pt — 小見出しと本文など、まとまりの内側。
    static let sm: CGFloat = 12
    /// 16pt — 画面の左右余白、カード内側の標準。
    static let md: CGFloat = 16
    /// 24pt — セクション間。
    static let lg: CGFloat = 24
    /// 32pt — 画面上の大きな区切り。
    static let xl: CGFloat = 32
}

/// 角丸。iOS のグループ化セル（10pt）を基準に、少数のトークンへ寄せる。
enum Radius {
    /// 8pt — バッジ・チップなど小さな面。
    static let small: CGFloat = 8
    /// 12pt — カード・パネルの標準。
    static let medium: CGFloat = 12
    /// 16pt — 画面幅いっぱいの大きな面。
    static let large: CGFloat = 16
}

/// 役割ベースの配色。背景・文字・区切りはシステム色に委ね、
/// ブランド5色はアクセントとしてだけ使う（ダークモード対応をシステムに任せるため）。
struct AppColors {
    let colorScheme: ColorScheme

    private var isDark: Bool { colorScheme == .dark }

    // MARK: - ブランドアクセント

    var primary: Color { isDark ? AppTheme.fieldGreenDark : AppTheme.fieldGreen }
    var onPrimary: Color { isDark ? Color(hex: 0x062514) : .white }
    var accent: Color { primary }

    var primaryContainer: Color {
        isDark ? AppTheme.fieldGreenDark.opacity(0.22) : AppTheme.fieldGreen.opacity(0.12)
    }
    var onPrimaryContainer: Color { primary }

    var secondary: Color { isDark ? AppTheme.leatherBrownDark : AppTheme.leatherBrown }

    var tertiary: Color { isDark ? AppTheme.stitchRedDark : AppTheme.stitchRed }
    var tertiaryContainer: Color { tertiary.opacity(isDark ? 0.22 : 0.12) }
    var onTertiaryContainer: Color { tertiary }

    var gold: Color { isDark ? AppTheme.trophyGoldDark : AppTheme.trophyGold }

    /// gold は明度が高く、白文字ではコントラストが取れない。
    var onGold: Color { Color(hex: 0x3A2A05) }

    // MARK: - 勝敗

    var winColor: Color { primary }
    var drawColor: Color { gold }
    var lossColor: Color { Color(.secondaryLabel) }

    // MARK: - 背景（システム色ベース）

    /// ダークのシステム色は純黒背景 + #1C1C1E カードでコントラスト比 1.2:1 しかなく、
    /// 影も純黒背景では効かないためカードが消える。緑寄りの黒で段階を作り直す。
    var groupedBackground: Color { isDark ? Color(hex: 0x131614) : Color(.systemGroupedBackground) }
    var cardBackground: Color { isDark ? Color(hex: 0x242926) : Color(.secondarySystemGroupedBackground) }
    var elevatedBackground: Color { isDark ? Color(hex: 0x323835) : Color(.tertiarySystemGroupedBackground) }

    /// ダークでは影が沈むため、カード上端のハイライト枠で浮きを作る。
    var cardBorder: Color { isDark ? Color.white.opacity(0.12) : .clear }
    var cardBorderWidth: CGFloat { isDark ? 0.5 : 0 }

    var surface: Color { groupedBackground }
    var surfaceContainerLowest: Color { cardBackground }
    var surfaceContainerLow: Color { groupedBackground }
    var surfaceContainerHighest: Color { Color(.tertiarySystemFill) }

    // MARK: - 文字

    var onSurface: Color { Color(.label) }
    var onSurfaceVariant: Color { Color(.secondaryLabel) }
    var onSurfaceTertiary: Color { Color(.tertiaryLabel) }

    // MARK: - 区切り

    var outline: Color { Color(.separator) }
    var outlineVariant: Color { Color(.separator).opacity(0.6) }

    // MARK: - エラー

    var errorContainer: Color { tertiary.opacity(isDark ? 0.22 : 0.12) }
    var onErrorContainer: Color { tertiary }

    // MARK: - カレンダー

    /// 日本のカレンダー慣習に合わせ、日曜と土曜だけ文字色を変える。
    /// 週の並びは日曜始まりで、index は Calendar の weekday - 1。
    func weekdayColor(_ index: Int, default defaultColor: Color) -> Color {
        switch index {
        case 0: Color(.systemRed)
        case 6: Color(.systemBlue)
        default: defaultColor
        }
    }

    // MARK: - 濃色面の上の文字

    /// ヒーローなどブランド色のベタ塗りに載せる文字。透明度の直書きを防ぐ。
    var onDark: Color { .white }
    var onDarkVariant: Color { .white.opacity(0.8) }
    var onDarkTertiary: Color { .white.opacity(0.6) }

    /// 濃色面の上に置く区切り・面。
    var onDarkSeparator: Color { .white.opacity(0.2) }
    var onDarkFill: Color { .white.opacity(0.15) }

    var shadow: Color { .black }

    /// カードは影で浮かせず、面の色差で分ける。ダークだけ境界線で輪郭を補う。
    var cardShadow: Color { .clear }
}

private struct AppColorsKey: EnvironmentKey {
    static let defaultValue = AppColors(colorScheme: .light)
}

extension EnvironmentValues {
    var appColors: AppColors {
        get { self[AppColorsKey.self] }
        set { self[AppColorsKey.self] = newValue }
    }
}

extension View {
    /// 配色は colorScheme から導出するため、ルートで一度だけ注入する。
    func provideAppColors(_ colorScheme: ColorScheme) -> some View {
        environment(\.appColors, AppColors(colorScheme: colorScheme))
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
