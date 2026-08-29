import SwiftUI

/// iOS 26 で追加された表現（Liquid Glass / MeshGradient）を、
/// デプロイターゲット iOS 17 でも破綻しない代替に落とすための分岐層。
/// 呼び出し側に `if #available` を散らさないよう、ここに集約する。

extension View {
    /// iOS 26: Liquid Glass / それ以前: 半透明マテリアル。
    func adaptiveGlass(in shape: some Shape) -> some View {
        modifier(AdaptiveGlassModifier(shape: shape, isInteractive: false))
    }

    /// タップに追従するグラス。フォールバックでは通常のマテリアルと同じ見た目になる。
    func adaptiveInteractiveGlass(in shape: some Shape) -> some View {
        modifier(AdaptiveGlassModifier(shape: shape, isInteractive: true))
    }
}

private struct AdaptiveGlassModifier<S: Shape>: ViewModifier {
    let shape: S
    let isInteractive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if isInteractive {
                content.glassEffect(.regular.interactive(), in: shape)
            } else {
                content.glassEffect(.regular, in: shape)
            }
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}

/// ヒーロー背景。iOS 18+ は MeshGradient、それ以前は同系色の LinearGradient。
struct HeroBackground: View {
    let colorScheme: ColorScheme

    var body: some View {
        if #available(iOS 18, *) {
            AppTheme.heroMesh(for: colorScheme)
        } else {
            AppTheme.heroGradient(for: colorScheme)
        }
    }
}
