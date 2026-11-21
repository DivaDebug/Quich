<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="Quich 圖示">
</p>

# Quich

Quick + Launch。住在 Mac 選單列的小工具，按一組熱鍵就打開你指定的 app。不管現在停在哪個 app，熱鍵都有效。

## 功能

- **一鍵打開 app**：替常用的 app 各設一組熱鍵，按下就打開或切到前景；每組熱鍵都能單獨開關
- **再按一次的行為**：app 已經在前景時再按一次，可以選擇「維持在前景」或「隱藏」
- **安靜地待在背景**：可以從選單列暫停所有熱鍵，也可以把選單列圖示整個隱藏
- **登入時自動啟動**

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/settings-dark.png">
  <img src="docs/images/settings-light.png" width="480" alt="Quich 設定視窗">
</picture>

## 建置與安裝

需要 macOS 13 以上與 Xcode（或 Command Line Tools）。

```bash
./scripts/build-app.sh            # 只建立 build/Quich.app
./scripts/build-app.sh --install  # 建立後複製到 /Applications 並啟動
```
