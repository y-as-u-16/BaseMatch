import SwiftUI

enum AppTheme {
    static let fieldGreen = Color(hex: 0x1B4332)
    static let leatherBrown = Color(hex: 0x5C4033)
    static let stitchRed = Color(hex: 0xC62828)
    static let baseWhite = Color(hex: 0xFFF8F0)
    static let trophyGold = Color(hex: 0xD4A017)

    /// iOS 標準のグループ化セルに合わせた角丸。旧 Material の 8pt から拡大。
    static let cornerRadius: CGFloat = 22
    static let cardCornerRadius: CGFloat = 22
    static let heroCornerRadius: CGFloat = 28
    static let controlCornerRadius: CGFloat = 16

    /// フローティングタブバーはセーフエリアに含まれないため、スクロール末尾に手動で確保する余白。
    static let floatingTabBarInset: CGFloat = 88

    /// ダークでは fieldGreen が沈んで文字が読めないため、明度を上げた同系色を使う。
    static let fieldGreenDark = Color(hex: 0x6FC49A)
    static let leatherBrownDark = Color(hex: 0xC9A98C)
    static let stitchRedDark = Color(hex: 0xFF8A80)
    static let trophyGoldDark = Color(hex: 0xEFC15A)

    static func heroGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let isDark = colorScheme == .dark
        return LinearGradient(
            colors: isDark
                ? [Color(hex: 0x14301F), Color(hex: 0x2E2119)]
                : [fieldGreen, leatherBrown],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func heroMesh(for colorScheme: ColorScheme) -> MeshGradient {
        let isDark = colorScheme == .dark
        let deep = isDark ? Color(hex: 0x0F2618) : fieldGreen
        let mid = isDark ? Color(hex: 0x1D3F2B) : Color(hex: 0x2C6446)
        let warm = isDark ? Color(hex: 0x33241B) : leatherBrown
        let glow = isDark ? Color(hex: 0x3D5A46) : Color(hex: 0x3F7C57)

        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                deep, mid, deep,
                mid, glow, warm,
                deep, warm, warm,
            ]
        )
    }
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

    var shadow: Color { .black }
    var cardShadow: Color { .black.opacity(isDark ? 0.5 : 0.08) }
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
