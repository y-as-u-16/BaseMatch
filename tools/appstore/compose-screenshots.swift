import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation

// App Store 6.9インチ必須サイズ
let W = 1320.0, H = 2868.0

struct Shot {
    let file: String
    let caption: String
    let sub: String
}

let args = CommandLine.arguments
guard args.count >= 4 else {
    print("usage: compose <srcDir> <outDir> <ja|en>")
    exit(1)
}
let srcDir = args[1], outDir = args[2], lang = args[3]

let ja = [
    Shot(file: "01-home", caption: "今季の成績が、ひと目で。", sub: "打率・防御率・勝敗をホームに集約"),
    Shot(file: "02-record", caption: "試合はカレンダーで管理。", sub: "日付をタップして記録を呼び出す"),
    Shot(file: "03-stats", caption: "打率も防御率も、自動で計算。", sub: "選手ごとの成績を自動集計"),
    Shot(file: "04-plate-input", caption: "打席の記録は、ワンタップ。", sub: "結果を選ぶだけで登録完了"),
]
let en = [
    Shot(file: "01-home", caption: "Your season at a glance", sub: "AVG, ERA, and record on one screen"),
    Shot(file: "02-record", caption: "Games on a calendar", sub: "Tap any date to pull up a game"),
    Shot(file: "03-stats", caption: "AVG and ERA, calculated", sub: "Per-player stats, totaled for you"),
    Shot(file: "04-plate-input", caption: "Log at-bats in one tap", sub: "Pick the result and you're done"),
]
let shots = lang == "ja" ? ja : en

// ブランドカラー（AppTheme の fieldGreen 系）
let top = NSColor(srgbRed: 0.106, green: 0.263, blue: 0.196, alpha: 1)
let bottom = NSColor(srgbRed: 0.043, green: 0.129, blue: 0.094, alpha: 1)

for shot in shots {
    let srcPath = "\(srcDir)/\(shot.file).png"
    guard let src = NSImage(contentsOfFile: srcPath) else {
        print("skip: \(srcPath)"); continue
    }

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H),
        // 描画用。alpha 付きでないと NSGraphicsContext が作れないため、
        // 不透明化は書き出し直前に行う。
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { exit(1) }
    rep.size = NSSize(width: W, height: H)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

    // 背景グラデーション
    NSGradient(starting: top, ending: bottom)?
        .draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

    // キャプション
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineSpacing = 8

    let title = NSAttributedString(string: shot.caption, attributes: [
        .font: NSFont.systemFont(ofSize: 88, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: para,
    ])
    let subtitle = NSAttributedString(string: shot.sub, attributes: [
        .font: NSFont.systemFont(ofSize: 46, weight: .medium),
        .foregroundColor: NSColor.white.withAlphaComponent(0.72),
        .paragraphStyle: para,
    ])

    let margin = 80.0
    let textW = W - margin * 2
    let titleH = title.boundingRect(
        with: NSSize(width: textW, height: 500),
        options: [.usesLineFragmentOrigin]
    ).height
    let subH = subtitle.boundingRect(
        with: NSSize(width: textW, height: 300),
        options: [.usesLineFragmentOrigin]
    ).height

    // 上部にキャプション、下に端末画面
    let titleTop = 130.0
    title.draw(with: NSRect(x: margin, y: H - titleTop - titleH, width: textW, height: titleH),
               options: [.usesLineFragmentOrigin])
    subtitle.draw(with: NSRect(x: margin, y: H - titleTop - titleH - 28 - subH, width: textW, height: subH),
                  options: [.usesLineFragmentOrigin])

    // 端末画面（角丸＋影付き）
    let deviceW = W * 0.82
    let scale = deviceW / W
    let deviceH = H * scale
    let deviceX = (W - deviceW) / 2
    let captionBottom = H - titleTop - titleH - 28 - subH
    let gap = 90.0
    let deviceY = captionBottom - gap - deviceH

    let radius = 58.0 * scale * 2.4
    let frame = NSRect(x: deviceX, y: deviceY, width: deviceW, height: deviceH)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 46,
                  color: NSColor.black.withAlphaComponent(0.45).cgColor)
    let path = NSBezierPath(roundedRect: frame, xRadius: radius, yRadius: radius)
    NSColor.white.setFill()
    path.fill()
    ctx.restoreGState()

    ctx.saveGState()
    path.addClip()
    src.draw(in: frame, from: .zero, operation: .sourceOver, fraction: 1.0)
    ctx.restoreGState()

    NSGraphicsContext.restoreGraphicsState()

    // App Store Connect はアルファ付き PNG を拒否する。
    // noneSkipLast のコンテキストへ描き直してアルファを落とす。
    guard let cg = rep.cgImage,
          let opaqueCtx = CGContext(
              data: nil, width: Int(W), height: Int(H),
              bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
          ) else {
        print("context failed: \(shot.file)"); continue
    }
    opaqueCtx.draw(cg, in: CGRect(x: 0, y: 0, width: W, height: H))
    guard let flat = opaqueCtx.makeImage() else {
        print("flatten failed: \(shot.file)"); continue
    }
    // NSBitmapImageRep を経由すると alpha 情報が復活してしまうため、
    // CGImage を CGImageDestination で直接書き出す。
    let dest = "\(outDir)/\(shot.file).png"
    guard let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: dest) as CFURL, "public.png" as CFString, 1, nil
    ) else {
        print("destination failed: \(shot.file)"); continue
    }
    // flat 自体は不透明だが、ImageIO は既定で RGBA として書き出すため明示する。
    let props: [CFString: Any] = [kCGImagePropertyHasAlpha: false]
    CGImageDestinationAddImage(destination, flat, props as CFDictionary)
    guard CGImageDestinationFinalize(destination) else {
        print("write failed: \(shot.file)"); continue
    }
    print("wrote \(dest)")
}
