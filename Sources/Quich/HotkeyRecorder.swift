import SwiftUI
import Carbon.HIToolbox

// 錄製熱鍵的按鈕：點下後攔截下一次按鍵，檢查合法後寫回設定
struct HotkeyRecorder: View {
    @EnvironmentObject var store: BindingStore
    @Binding var binding: AppBinding
    @Binding var message: String?

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            isRecording ? stop() : start()
        } label: {
            Text(isRecording ? "請按下按鍵…" : (binding.combo?.displayString ?? "點此錄製"))
                .font(.system(.body, design: .monospaced))
                .frame(width: 110)
        }
        .buttonStyle(.bordered)
        .tint(isRecording ? .accentColor : nil)
        .onDisappear(perform: stop)
    }

    private func start() {
        isRecording = true
        store.isRecording = true
        message = nil
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        guard isRecording else { return }
        isRecording = false
        store.isRecording = false
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])

        if Int(event.keyCode) == kVK_Escape {
            stop()
            return
        }
        if Int(event.keyCode) == kVK_Delete, flags.isEmpty {
            binding.combo = nil
            stop()
            return
        }
        guard let combo = KeyCombo(event: event) else {
            message = "熱鍵至少要包含 ⌃、⌥ 或 ⌘ 其中一個。"
            return
        }
        if let other = store.owner(of: combo, excluding: binding.id) {
            message = "\(combo.displayString) 已經被 \(other.displayName) 使用了。"
            return
        }
        message = nil
        stop()
        binding.combo = combo
    }
}
