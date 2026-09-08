#!/bin/bash
# Antigravity RTL Auto-Patcher Script for Linux

LOG_FILE="$HOME/.local/share/antigravity-rtl/patcher.log"
mkdir -p "$HOME/.local/share/antigravity-rtl"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

APP_ASAR_PATHS=(
    "/usr/share/antigravity/resources/app.asar"
    "/opt/Antigravity/resources/app.asar"
    "/opt/antigravity/resources/app.asar"
    "$HOME/Antigravity/resources/app.asar"
)

APP_ASAR=""
for p in "${APP_ASAR_PATHS[@]}"; do
    if [ -f "$p" ]; then
        APP_ASAR="$p"
        break
    fi
done

if [ -z "$APP_ASAR" ]; then
    exit 0
fi

if ! command -v npx &> /dev/null; then
    exit 0
fi

TMP_EXTRACT="/tmp/antigravity_extracted_linux_watcher_$$"
npx asar extract "$APP_ASAR" "$TMP_EXTRACT" 2>/dev/null
if [ $? -ne 0 ]; then
    rm -rf "$TMP_EXTRACT"
    exit 0
fi

PRELOAD_PATH=$(find "$TMP_EXTRACT" -name "preload.js" | head -n 1)

if [ -f "$PRELOAD_PATH" ]; then
    if grep -q "persian-rtl-vazirmatn-style" "$PRELOAD_PATH"; then
        rm -rf "$TMP_EXTRACT"
        exit 0
    fi

    log "Antigravity update detected. Re-applying RTL patch..."
    cp -f "$APP_ASAR" "$APP_ASAR.bak" 2>/dev/null

    cat << 'INNER_EOF' >> "$PRELOAD_PATH"

// RTL & Font Injector - Persian Gravity Project
window.addEventListener('DOMContentLoaded', () => {
    const style = document.createElement('style');
    style.id = 'persian-rtl-vazirmatn-style';
    style.innerHTML = `
      @import url('https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css');

      * {
        font-family: 'Vazirmatn', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
      }

      p, li, span, div, h1, h2, h3, h4, h5, h6, textarea, input {
        unicode-bidi: plaintext !important;
        text-align: start !important;
      }

      code, pre, pre *, code *, kbd, .monospace {
        font-family: Menlo, Monaco, Consolas, "Fira Code", monospace !important;
        direction: ltr !important;
        unicode-bidi: normal !important;
        text-align: left !important;
      }
    `;
    document.head.appendChild(style);
});
INNER_EOF

    npx asar pack "$TMP_EXTRACT" "$APP_ASAR" 2>/dev/null
    log "✔ Antigravity app.asar successfully re-patched."
fi

rm -rf "$TMP_EXTRACT"
