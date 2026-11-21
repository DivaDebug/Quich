import SwiftUI

@main
struct QuichApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // 選單列與設定視窗都由 AppDelegate 自己管理，這裡只放一個空的場景讓 SwiftUI 能啟動
    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = BindingStore()
    private var statusMenu: StatusMenuController?

    // 建立選單列圖示；還沒設定任何 app，或選單列圖示被隱藏（沒有其他入口）時，直接打開設定視窗
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusMenu = StatusMenuController(store: store)
        if store.bindings.isEmpty || !store.showsMenuBarIcon {
            SettingsWindow.show(store: store)
        }
    }

    // 選單列圖示隱藏時，唯一的入口是再次打開 Quich（Finder、Spotlight、Launchpad），這時顯示設定視窗
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindow.show(store: store)
        return true
    }
}
