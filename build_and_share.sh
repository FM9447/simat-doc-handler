#!/usr/bin/env bash
# ============================================================
#  DocTransit — Build APK for sharing (MediaFire / WhatsApp / etc.)
#  Usage:  bash build_and_share.sh [arm64|arm32|universal]
# ============================================================

set -e

ARCH="${1:-arm64}"
FLUTTER_APP="$(dirname "$0")/flutter_app"
DIST_DIR="$(dirname "$0")/dist"
DATE=$(date +'%Y%m%d-%H%M')

echo ""
echo "══════════════════════════════════════════"
echo "   DocTransit APK Builder"
echo "   Arch: $ARCH  |  Date: $DATE"
echo "══════════════════════════════════════════"
echo ""

# 1. Build
echo "▶ Building release APK (split per ABI)…"
cd "$FLUTTER_APP"
flutter build apk --release --split-per-abi

# 2. Pick the right APK
case "$ARCH" in
  arm64)    SRC="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ;;
  arm32)    SRC="build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" ;;
  universal) SRC="build/app/outputs/flutter-apk/app-release.apk" ;;
  *)        echo "Unknown arch '$ARCH'. Use arm64 | arm32 | universal"; exit 1 ;;
esac

# 3. Copy to dist/
mkdir -p "$DIST_DIR"
DEST="$DIST_DIR/DocTransit-${ARCH}-${DATE}.apk"
cp "$SRC" "$DEST"

echo ""
echo "✅  APK ready at:"
echo "    $DEST"
echo ""
echo "📤  Share options:"
echo "    • Drag & drop to MediaFire / Google Drive / MEGA"
echo "    • Send via WhatsApp / Telegram from your file manager"
echo "    • Upload to Firebase App Distribution:"
echo "      firebase appdistribution:distribute \"$DEST\" \\"
echo "        --app com.simat.doctransit \\"
echo "        --groups testers \\"
echo "        --release-notes \"Manual build $DATE\""
echo ""
echo "  File size: $(du -sh "$DEST" | cut -f1)"
