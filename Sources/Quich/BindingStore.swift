import AppKit
import ServiceManagement

// 管理熱鍵清單與總開關；任何變動都會存檔並重新向系統登記熱鍵
final class BindingStore: ObservableObject {
    @Published var bindings: [AppBinding] = [] {
        didSet { save(); reregister() }
    }
    @Published var isEnabled: Bool = true {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.enabled); reregister() }
    }
    // 目標 app 已在前景時再按一次熱鍵的行為，所有 app 共用
    @Published var pressAgain: PressAgainAction = .stay {
        didSet { UserDefaults.standard.set(pressAgain.rawValue, forKey: Keys.pressAgain) }
    }
    // 隱藏後 Quich 仍在背景執行，熱鍵照常運作；再次打開 Quich 即可叫出設定視窗
    @Published var showsMenuBarIcon: Bool = true {
        didSet { UserDefaults.standard.set(showsMenuBarIcon, forKey: Keys.showsMenuBarIcon) }
    }
    // 設定視窗開著時，即使圖示設為隱藏也暫時顯示，方便確認目前狀態
    @Published var isSettingsOpen = false
    // 錄製新熱鍵期間暫停所有熱鍵，否則按下已登記的組合會直接觸發而錄不到
    @Published var isRecording = false {
        didSet { reregister() }
    }
    // 登記失敗（被其他程式佔用）的項目，設定視窗會標示出來
    @Published private(set) var conflictedIDs: Set<UUID> = []

    private enum Keys {
        static let bindings = "bindings"
        static let enabled = "enabled"
        static let showsMenuBarIcon = "showsMenuBarIcon"
        static let pressAgain = "pressAgain"
    }

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Keys.bindings),
           let saved = try? JSONDecoder().decode([AppBinding].self, from: data) {
            bindings = saved
        }
        isEnabled = defaults.object(forKey: Keys.enabled) as? Bool ?? true
        showsMenuBarIcon = defaults.object(forKey: Keys.showsMenuBarIcon) as? Bool ?? true
        pressAgain = defaults.string(forKey: Keys.pressAgain).flatMap(PressAgainAction.init) ?? .stay
        reregister()
    }

    func add(appAt url: URL) {
        guard !bindings.contains(where: { $0.appPath == url.path }) else { return }
        bindings.append(AppBinding(appPath: url.path))
    }

    func remove(_ id: UUID) {
        bindings.removeAll { $0.id == id }
    }

    // 檢查熱鍵是否已被清單中其他 app 使用
    func owner(of combo: KeyCombo, excluding id: UUID) -> AppBinding? {
        bindings.first { $0.id != id && $0.combo == combo }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(bindings) {
            UserDefaults.standard.set(data, forKey: Keys.bindings)
        }
    }

    private func reregister() {
        let center = HotkeyCenter.shared
        center.unregisterAll()
        guard isEnabled, !isRecording else {
            conflictedIDs = []
            return
        }

        var conflicts: Set<UUID> = []
        for binding in bindings {
            guard let combo = binding.combo else { continue }
            let ok = center.register(combo) { [weak self] in
                // 觸發當下重新讀取最新設定，避免用到舊的 app 路徑或「再按一次」行為
                guard let self, let latest = self.bindings.first(where: { $0.id == binding.id }) else { return }
                AppLauncher.trigger(latest, pressAgain: self.pressAgain)
            }
            if !ok { conflicts.insert(binding.id) }
        }
        if conflicts != conflictedIDs { conflictedIDs = conflicts }
    }
}

// 登入時自動啟動；需要以 .app 形式執行才有效
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func set(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Quich 無法變更登入時自動啟動：\(error.localizedDescription)")
        }
    }
}
