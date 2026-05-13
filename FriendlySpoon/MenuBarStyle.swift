import SwiftUI

enum MenuBarStyle: String, CaseIterable, Identifiable {
    case bars     // ▮▮▮▯  ▮▮▮▮       (default)
    case halves   // ◧ 78%  18% ◨    (bracketed)
    case numbers  // 78%  82%

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bars:    return "Block bars  ▮▮▮▯"
        case .halves:  return "Split halves  ◧ 78%  18% ◨"
        case .numbers: return "Numbers only  78% 82%"
        }
    }
}

enum HalfGlyphs: String, CaseIterable, Identifiable {
    case blocks    // ◧ ◨
    case circles   // ◐ ◑
    case arrows    // ◀ ▶
    case hands     // 🫲 🫱 (color emoji, won't tint)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .blocks:  return "Blocks  ◧ ◨"
        case .circles: return "Circles  ◐ ◑"
        case .arrows:  return "Arrows  ◀ ▶"
        case .hands:   return "Hands  🫲 🫱  (no color tint)"
        }
    }

    var left: String {
        switch self {
        case .blocks:  return "◧"
        case .circles: return "◐"
        case .arrows:  return "◀"
        case .hands:   return "🫲"
        }
    }

    var right: String {
        switch self {
        case .blocks:  return "◨"
        case .circles: return "◑"
        case .arrows:  return "▶"
        case .hands:   return "🫱"
        }
    }
}

private func bar4(_ pct: Int) -> String {
    let filled = max(0, min(4, Int(ceil(Double(pct) / 25.0))))
    return String(repeating: "▮", count: filled) + String(repeating: "▯", count: 4 - filled)
}

private func levelColor(_ pct: Int, colorize: Bool) -> Color {
    guard colorize else { return .primary }
    if pct < 20 { return .red }
    if pct < 50 { return .orange }
    return .primary
}

func menuBarContent(left: Int,
                    right: Int,
                    style: MenuBarStyle,
                    glyphs: HalfGlyphs,
                    colorize: Bool,
                    worstOnly: Bool) -> Text {
    if worstOnly {
        let worst = min(left, right)
        let leftIsWorst = left <= right
        let wc = levelColor(worst, colorize: colorize)
        switch style {
        case .bars:
            return Text(bar4(worst)).foregroundColor(wc)
        case .halves:
            // Keep the side glyph on the appropriate side of the number
            return leftIsWorst
                ? Text("\(glyphs.left) \(worst)%").foregroundColor(wc)
                : Text("\(worst)% \(glyphs.right)").foregroundColor(wc)
        case .numbers:
            return Text("\(worst)%").foregroundColor(wc)
        }
    }

    let lc = levelColor(left, colorize: colorize)
    let rc = levelColor(right, colorize: colorize)
    let gap = Text("  ")

    switch style {
    case .bars:
        return Text(bar4(left)).foregroundColor(lc)
            + gap
            + Text(bar4(right)).foregroundColor(rc)
    case .halves:
        // Bracketed: [glyph] L%  R% [glyph]
        return Text("\(glyphs.left) \(left)%").foregroundColor(lc)
            + gap
            + Text("\(right)% \(glyphs.right)").foregroundColor(rc)
    case .numbers:
        return Text("\(left)%").foregroundColor(lc)
            + gap
            + Text("\(right)%").foregroundColor(rc)
    }
}
