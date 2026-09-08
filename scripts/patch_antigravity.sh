#!/bin/bash
# Antigravity RTL Auto-Patcher Script
# Automatically reapplies RTL CSS and Vazirmatn font if app.asar was updated

LOG_FILE="$HOME/Library/Logs/antigravity-rtl.log"
APP_PATH="/Applications/Antigravity.app"
ASAR_PATH="$APP_PATH/Contents/Resources/app.asar"
BACKUP_PATH="$APP_PATH/Contents/Resources/app.asar.bak"
TMP_EXTRACT="/tmp/antigravity_extracted_watcher_$$"
TMP_ASAR="/tmp/app_watcher_$$.asar"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

if [ ! -d "$APP_PATH" ] || [ ! -f "$ASAR_PATH" ]; then
    exit 0
fi

# Ensure standard tool paths in PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$PATH"

if ! command -v npx &> /dev/null; then
    log "Warning: npx/node not found in PATH. Skipping auto-patch."
    exit 0
fi

# Extract and inspect
npx asar extract "$ASAR_PATH" "$TMP_EXTRACT" 2>/dev/null
if [ $? -ne 0 ]; then
    rm -rf "$TMP_EXTRACT"
    exit 0
fi

PRELOAD_PATH=$(find "$TMP_EXTRACT" -name "preload.js" | head -n 1)

if [ -f "$PRELOAD_PATH" ]; then
    if grep -q "persian-rtl-vazirmatn-style" "$PRELOAD_PATH"; then
        # Already patched
        rm -rf "$TMP_EXTRACT"
        exit 0
    fi

    log "Antigravity update detected (unpatched app.asar found). Re-applying RTL patch..."

    # Ensure backup of clean version
    cp -f "$ASAR_PATH" "$BACKUP_PATH"

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

    npx asar pack "$TMP_EXTRACT" "$TMP_ASAR" 2>/dev/null
    if [ -f "$TMP_ASAR" ]; then
        cp -f "$TMP_ASAR" "$ASAR_PATH"
        rm -f "$TMP_ASAR"
        codesign --force --deep --sign - "$APP_PATH" &>/dev/null
        log "✔ Antigravity app.asar successfully re-patched and signed."
    fi
fi

rm -rf "$TMP_EXTRACT" "$TMP_ASAR"
