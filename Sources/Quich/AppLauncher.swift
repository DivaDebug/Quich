import AppKit

enum AppLauncher {
    // 熱鍵觸發時呼叫：目標 app 已在前景就依設定處理，否則打開並切到前景
    static func trigger(_ binding: AppBinding, pressAgain: PressAgainAction) {
        if let front = NSWorkspace.shared.frontmostApplication, isSameApp(front, binding.appURL) {
            switch pressAgain {
            case .stay:
                return
            case .hide:
                front.hide()
                return
            }
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: binding.appURL, configuration: config) { _, error in
            if let error { NSLog("Quich 無法打開 \(binding.appPath)：\(error.localizedDescription)") }
        }
    }

    // 優先用 bundle identifier 比對，拿不到時退回比對路徑
    private static func isSameApp(_ running: NSRunningApplication, _ url: URL) -> Bool {
        if let targetID = Bundle(url: url)?.bundleIdentifier, let runningID = running.bundleIdentifier {
            return targetID == runningID
        }
        return running.bundleURL?.standardizedFileURL == url.standardizedFileURL
    }

    static func icon(for path: String, size: CGFloat) -> NSImage {
        let image = NSWorkspace.shared.icon(forFile: path).copy() as! NSImage
        image.size = NSSize(width: size, height: size)
        return image
    }
}
