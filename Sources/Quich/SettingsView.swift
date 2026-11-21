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
            // 關閉設定時通知 store，讓選單列圖示回到使用者設定的顯示狀態
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification,
                                                   object: newWindow, queue: .main) { _ in
                store.isSettingsOpen = false
            }
            window = newWindow
        }
        store.isSettingsOpen = true
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
            sectionTitle("熱鍵")
            card {
                if store.bindings.isEmpty {
                    Text("還沒有任何 app，按下方「新增 app」加入第一個。")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    Divider()
                }
                ForEach($store.bindings) { $binding in
                    row(for: $binding)
                    Divider()
                }
                Button {
                    pickApp()
                } label: {
                    Label("新增 app", systemImage: "plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            // 只在錄製熱鍵出錯時顯示錯誤訊息
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
            }

            sectionTitle("一般")
            card {
                settingRow("已在前景時再按一次") {
                    Picker("", selection: $store.pressAgain) {
                        ForEach(PressAgainAction.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
                Divider()
                settingRow("在選單列顯示圖示") {
                    Toggle("", isOn: $store.showsMenuBarIcon)
                }
                Divider()
                settingRow("登入時自動啟動") {
                    Toggle("", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            LaunchAtLogin.set(newValue)
                            launchAtLogin = LaunchAtLogin.isEnabled
                        }
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            HStack {
                Spacer()
                // 圖示隱藏時選單裡的「結束」也看不到，所以設定視窗也放一個
                Button("結束 Quich") { NSApp.terminate(nil) }
            }
            .padding(16)
        }
        .frame(width: 480)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    // 圓角卡片外框，仿系統設定的分區樣式
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.primary.opacity(0.08)))
            .padding(.horizontal, 16)
    }

    private func settingRow<Control: View>(_ title: String, @ViewBuilder control: () -> Control) -> some View {
        HStack {
            Text(title)
            Spacer()
            control()
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 38)
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
                .frame(width: 130)

            Button {
                store.remove(item.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("移除 \(item.displayName)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
