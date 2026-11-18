import AppKit
import Carbon.HIToolbox
import Combine

// 選單列圖示與下拉選單；改用原生 NSMenu，才能在每個項目前顯示 app 圖示
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let store: BindingStore
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var cancellable: AnyCancellable?

    init(store: BindingStore) {
        self.store = store
        super.init()

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        cancellable = store.$isEnabled.sink { [weak self] enabled in
            self?.updateIcon(enabled: enabled)
        }
    }

    // 熱鍵暫停時改成劃掉的閃電
    private func updateIcon(enabled: Bool) {
        let image = NSImage(systemSymbolName: enabled ? "bolt.fill" : "bolt.slash",
                            accessibilityDescription: "Quich")
        image?.isTemplate = true
        statusItem.button?.image = image
    }

    // 每次打開選單前重建，確保內容與目前設定一致
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let toggle = NSMenuItem(title: "啟用熱鍵", action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        toggle.state = store.isEnabled ? .on : .off
        menu.addItem(toggle)
        menu.addItem(.separator())

        if store.bindings.isEmpty {
            let empty = NSMenuItem(title: "尚未設定任何 app", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        }
        for binding in store.bindings {
            let item = NSMenuItem(title: binding.displayName, action: #selector(launch(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = binding.id
            item.image = AppLauncher.icon(for: binding.appPath, size: 16)
            // 借用選單原生的快捷鍵欄位，把熱鍵顯示在項目右側
            if let combo = binding.combo, let key = Self.keyEquivalent(for: combo) {
                item.keyEquivalent = key
                item.keyEquivalentModifierMask = Self.modifierMask(for: combo)
            }
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let settings = NSMenuItem(title: "設定…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(NSMenuItem(title: "結束 Quich", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func toggleEnabled() {
        store.isEnabled.toggle()
    }

    @objc private func launch(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID,
              let binding = store.bindings.first(where: { $0.id == id }) else { return }
        AppLauncher.trigger(binding)
    }

    @objc private func openSettings() {
        SettingsWindow.show(store: store)
    }

    private static func keyEquivalent(for combo: KeyCombo) -> String? {
        let special: [String: Int] = [
            "←": NSLeftArrowFunctionKey, "→": NSRightArrowFunctionKey,
            "↑": NSUpArrowFunctionKey, "↓": NSDownArrowFunctionKey,
            "↖": NSHomeFunctionKey, "↘": NSEndFunctionKey,
            "⇞": NSPageUpFunctionKey, "⇟": NSPageDownFunctionKey,
            "⌦": NSDeleteFunctionKey,
            "F1": NSF1FunctionKey, "F2": NSF2FunctionKey, "F3": NSF3FunctionKey, "F4": NSF4FunctionKey,
            "F5": NSF5FunctionKey, "F6": NSF6FunctionKey, "F7": NSF7FunctionKey, "F8": NSF8FunctionKey,
            "F9": NSF9FunctionKey, "F10": NSF10FunctionKey, "F11": NSF11FunctionKey, "F12": NSF12FunctionKey,
        ]
        switch combo.keyLabel {
        case "Space": return " "
        case "↩": return "\r"
        case "⇥": return "\t"
        case "⌫": return "\u{8}"
        default:
            if let code = special[combo.keyLabel], let scalar = UnicodeScalar(code) {
                return String(Character(scalar))
            }
            return combo.keyLabel.count == 1 ? combo.keyLabel.lowercased() : nil
        }
    }

    private static func modifierMask(for combo: KeyCombo) -> NSEvent.ModifierFlags {
        var mask: NSEvent.ModifierFlags = []
        if combo.carbonModifiers & UInt32(cmdKey) != 0 { mask.insert(.command) }
        if combo.carbonModifiers & UInt32(controlKey) != 0 { mask.insert(.control) }
        if combo.carbonModifiers & UInt32(optionKey) != 0 { mask.insert(.option) }
        if combo.carbonModifiers & UInt32(shiftKey) != 0 { mask.insert(.shift) }
        return mask
    }
}
