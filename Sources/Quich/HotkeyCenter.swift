import Carbon.HIToolbox

// 透過 Carbon 的 RegisterEventHotKey 向系統登記全域熱鍵；
// 這種熱鍵由系統直接攔截，不會被前景 app（例如 Dia）吃掉
final class HotkeyCenter {
    static let shared = HotkeyCenter()

    private var refs: [EventHotKeyRef] = []
    private var actions: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1
    private let signature = OSType(0x5155_4348) // "QUCH"

    private init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotkeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)
            HotkeyCenter.shared.actions[hotkeyID.id]?()
            return noErr
        }, 1, &eventType, nil, nil)
    }

    // 登記一組熱鍵；回傳 false 代表這組鍵已被其他程式登記
    @discardableResult
    func register(_ combo: KeyCombo, action: @escaping () -> Void) -> Bool {
        let id = nextID
        nextID += 1

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(combo.keyCode, combo.carbonModifiers,
                                         EventHotKeyID(signature: signature, id: id),
                                         GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else { return false }

        refs.append(ref)
        actions[id] = action
        return true
    }

    func unregisterAll() {
        refs.forEach { UnregisterEventHotKey($0) }
        refs.removeAll()
        actions.removeAll()
    }
}
