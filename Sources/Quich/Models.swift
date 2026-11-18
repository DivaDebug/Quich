import AppKit
import Carbon.HIToolbox

// 目標 app 已在前景時，再按一次熱鍵要做的事
enum PressAgainAction: String, Codable, CaseIterable, Identifiable {
    case stay
    case hide

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stay: return "維持在前景"
        case .hide: return "隱藏"
        }
    }
}

// 一組熱鍵：Carbon 按鍵代碼與修飾鍵，加上顯示用的文字
struct KeyCombo: Codable, Equatable {
    var keyCode: UInt32
    var carbonModifiers: UInt32
    var keyLabel: String

    var displayString: String {
        var text = ""
        if carbonModifiers & UInt32(controlKey) != 0 { text += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { text += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { text += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { text += "⌘" }
        return text + keyLabel
    }

    // 從鍵盤事件建立熱鍵；沒有 ⌃ ⌥ ⌘ 任一修飾鍵時回傳 nil，避免一般打字被攔截
    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command) || flags.contains(.control) || flags.contains(.option) else { return nil }

        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }

        self.keyCode = UInt32(event.keyCode)
        self.carbonModifiers = modifiers
        self.keyLabel = KeyCombo.label(for: event)
    }

    init(keyCode: UInt32, carbonModifiers: UInt32, keyLabel: String) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.keyLabel = keyLabel
    }

    // 特殊鍵用符號表示，其他鍵取不含修飾鍵的字元
    private static func label(for event: NSEvent) -> String {
        let special: [Int: String] = [
            kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫",
            kVK_ForwardDelete: "⌦", kVK_LeftArrow: "←", kVK_RightArrow: "→",
            kVK_UpArrow: "↑", kVK_DownArrow: "↓", kVK_Home: "↖", kVK_End: "↘",
            kVK_PageUp: "⇞", kVK_PageDown: "⇟",
            kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
            kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        ]
        if let name = special[Int(event.keyCode)] { return name }
        return (event.charactersIgnoringModifiers ?? "?").uppercased()
    }
}

struct AppBinding: Codable, Identifiable, Equatable {
    var id = UUID()
    var appPath: String
    var combo: KeyCombo?
    var pressAgain: PressAgainAction = .stay

    var appURL: URL { URL(fileURLWithPath: appPath) }

    var displayName: String {
        FileManager.default.displayName(atPath: appPath).replacingOccurrences(of: ".app", with: "")
    }
}
