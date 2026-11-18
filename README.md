# Quich

Quick + Launch。住在選單列的小工具，用全域熱鍵打開指定的 app。

用 Carbon 的 `RegisterEventHotKey` 向系統登記熱鍵，所以不管前景是哪個 app（包括不轉交「服務」快捷鍵的 Dia 等 Chromium 瀏覽器）都有效。

## 功能

- 每個 app 綁一組熱鍵，在設定視窗直接按下組合鍵錄製
- 目標 app 已在前景時再按一次：「維持在前景」（預設）或「隱藏」
- 選單列下拉選單可以看所有熱鍵、一鍵暫停全部熱鍵
- 登入時自動啟動
- 第一次啟動（還沒設定任何 app）時會自動打開設定視窗

## 建置與安裝

需要 macOS 13 以上與 Xcode（或 Command Line Tools）。

```bash
./scripts/build-app.sh            # 只建立 build/Quich.app
./scripts/build-app.sh --install  # 建立後複製到 /Applications 並啟動
```

## App icon

`Resources/AppIcon.icns` 由 `scripts/make-icon.swift` 以程式繪製產生。要調整顏色或造型時修改該檔，再執行：

```bash
swift scripts/make-icon.swift Resources
```

## 專案結構

| 檔案 | 用途 |
| --- | --- |
| `QuichApp.swift` | 進入點 |
| `StatusMenu.swift` | 選單列圖示與下拉選單（原生 NSMenu） |
| `SettingsView.swift` | 設定視窗 |
| `HotkeyRecorder.swift` | 錄製熱鍵的按鈕 |
| `BindingStore.swift` | 熱鍵清單的儲存、登記與登入啟動 |
| `HotkeyCenter.swift` | 向系統登記全域熱鍵 |
| `AppLauncher.swift` | 打開或隱藏目標 app |
| `Models.swift` | 資料模型 |
