import SwiftUI
import UniformTypeIdentifiers

// 設定視窗；Quich 沒有 Dock 圖示，所以自己管理視窗並在打開時把 app 切到前景
enum SettingsWindow {
    private static var window: NSWindow?

    static func show(store: BindingStore) {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView().environmentObject(store))
            let newWindow = NSWindow(contentViewController: hosting)
            newWindow.title = "Quich 設定"
            newWindow.styleMask = [.titled, .closable]
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            window = newWindow
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: BindingStore
    @State private var message: String?
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            if store.bindings.isEmpty {
                Text("按「新增 app」加入第一個要用熱鍵打開的 app。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
            ForEach($store.bindings) { $binding in
                row(for: $binding)
                Divider()
            }

            footer
        }
        .frame(width: 560)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("App").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 36)
            Text("熱鍵").frame(width: 130, alignment: .leading)
            Text("已在前景時再按一次").frame(width: 150, alignment: .leading)
            Spacer().frame(width: 24)
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func row(for binding: Binding<AppBinding>) -> some View {
        let item = binding.wrappedValue
        let conflicted = store.conflictedIDs.contains(item.id)

        return HStack(spacing: 12) {
            Image(nsImage: AppLauncher.icon(for: item.appPath, size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName).lineLimit(1)
                if conflicted {
                    Text("這組熱鍵已被其他程式佔用").font(.caption).foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HotkeyRecorder(binding: binding, message: $message)
                .frame(width: 130, alignment: .leading)

            Picker("", selection: binding.pressAgain) {
                ForEach(PressAgainAction.allCases) { Text($0.title).tag($0) }
            }
            .labelsHidden()
            .frame(width: 150)

            Button {
                store.remove(item.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("移除 \(item.displayName)")
            .frame(width: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    pickApp()
                } label: {
                    Label("新增 app", systemImage: "plus")
                }
                Spacer()
                Toggle("登入時自動啟動", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        LaunchAtLogin.set(newValue)
                        launchAtLogin = LaunchAtLogin.isEnabled
                    }
            }
            Text(message ?? "點熱鍵欄位後，直接按下新的組合鍵來錄製；按 Esc 取消，按 ⌫ 清除。")
                .font(.caption)
                .foregroundStyle(message == nil ? Color.secondary : Color.red)
        }
        .padding(16)
    }

    private func pickApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.prompt = "加入"
        guard panel.runModal() == .OK else { return }
        panel.urls.forEach { store.add(appAt: $0) }
    }
}
