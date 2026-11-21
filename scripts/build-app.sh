#!/bin/zsh
# 編譯 Quich 並打包成 build/Quich.app
#   --zip      另外壓縮成 build/Quich.zip，用來上傳到 GitHub Releases
#   --install  複製到 /Applications 並啟動
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/Quich.app"
ZIP="build/Quich.zip"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -parse-as-library -target "$(uname -m)-apple-macos13.0" \
    Sources/Quich/*.swift -o "$APP/Contents/MacOS/Quich"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# 用本機臨時簽章（ad-hoc），讓系統允許登入時自動啟動等功能
codesign --force --sign - "$APP"
# 更新修改時間，讓 Finder 重新讀取圖示，不沿用舊的快取
touch "$APP"
echo "已建立 $APP"

for arg in "$@"; do
    case "$arg" in
    --zip)
        # 用 ditto 壓縮才會保留簽章與檔案屬性，一般的 zip 會讓簽章失效
        rm -f "$ZIP"
        ditto -c -k --keepParent "$APP" "$ZIP"
        echo "已建立 $ZIP"
        ;;
    --install)
        pkill -x Quich 2>/dev/null || true
        rm -rf /Applications/Quich.app
        cp -R "$APP" /Applications/
        open /Applications/Quich.app
        echo "已安裝到 /Applications 並啟動"
        ;;
    *)
        echo "不認得的參數：$arg（可用 --zip、--install）" >&2
        exit 1
        ;;
    esac
done
