#!/bin/bash

# Setup Vazirmatn and RTL for Linux
# Project: Persian Gravity 🚀
# Dedicated to the memory of Saber Rastikerdar (خالق وزیرمتن)

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}=============================================${NC}"
echo -e "${YELLOW}  نصب فونت وزیرمتن و تنظیم راست‌چین ادیتورها  ${NC}"
echo -e "${CYAN}=============================================${NC}"
echo -e "${GREEN}    به یاد صابر راستی‌کردار، خالق وزیرمتن    ${NC}"
echo -e "${CYAN}=============================================${NC}"
echo ""

# 1. Download and Install Vazirmatn Font
echo -e "${YELLOW}۱. در حال دریافت آخرین نسخه فونت وزیرمتن...${NC}"
LATEST_ZIP_URL=$(curl -s https://api.github.com/repos/rastikerdar/vazirmatn/releases/latest | grep "browser_download_url.*zip" | head -n 1 | cut -d '"' -f 4)

if [ -z "$LATEST_ZIP_URL" ]; then
    ZIP_URL="https://github.com/rastikerdar/vazirmatn/releases/download/v33.003/vazirmatn-v33.003.zip"
else
    ZIP_URL="$LATEST_ZIP_URL"
fi

echo "در حال دانلود فونت..."
curl -L -o /tmp/vazirmatn.zip "$ZIP_URL"

if [ $? -eq 0 ]; then
    echo "در حال استخراج و نصب فونت..."
    unzip -q /tmp/vazirmatn.zip -d /tmp/vazirmatn
    
    # Target Fonts Folder for Linux
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    
    # Copy all .ttf files
    find /tmp/vazirmatn -name "*.ttf" -exec cp {} "$FONT_DIR" \;
    
    # Rebuild font cache
    echo "در حال بروزرسانی کش فونت‌های سیستم..."
    fc-cache -f
    
    rm -rf /tmp/vazirmatn.zip /tmp/vazirmatn
    echo -e "${GREEN}✔ فونت وزیرمتن با موفقیت نصب شد.${NC}"
else
    echo -e "${RED}❌ خطا در دانلود فونت. اتصال اینترنت را بررسی کنید.${NC}"
fi

# 2. Patch Antigravity App UI on Linux
echo ""
echo -e "${YELLOW}۲. در حال راست‌چین‌سازی ظاهر عمومی برنامه Antigravity...${NC}"

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

if [ -n "$APP_ASAR" ]; then
    echo "برنامه در مسیر $APP_ASAR یافت شد."
    if [ ! -w "$APP_ASAR" ]; then
        echo -e "${YELLOW}⚠️ نیاز به دسترسی روت (sudo) برای اعمال تغییرات در پوشه سیستمی...${NC}"
        SUDO="sudo"
    else
        SUDO=""
    fi
    
    if command -v npx &> /dev/null; then
        $SUDO npx asar extract "$APP_ASAR" /tmp/extracted_app
        
        PRELOAD_PATH=$(find /tmp/extracted_app -name "preload.js" | head -n 1)
        
        if [ -f "$PRELOAD_PATH" ]; then
            if grep -q "persian-rtl-vazirmatn-style" "$PRELOAD_PATH"; then
                echo -e "${YELLOW}ℹ️ پچ راست‌چین پیش از این روی نرم‌افزار اعمال شده است.${NC}"
            else
                # Backup
                $SUDO cp "$APP_ASAR" "$APP_ASAR.bak"
                
                # Append CSS inject
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
                $SUDO npx asar pack /tmp/extracted_app "$APP_ASAR"
                rm -rf /tmp/extracted_app
                echo -e "${GREEN}✔ ظاهر نرم‌افزار با موفقیت پچ شد.${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️ ابزار Node.js (npx) برای استخراج و بسته‌بندی فایل‌های اصلی برنامه یافت نشد.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ برنامه Antigravity در مسیرهای استاندارد لینوکس یافت نشد.${NC}"
fi

# 3. Update settings.json for Linux Editors
echo ""
echo -e "${YELLOW}۳. در حال اعمال تنظیمات روی ادیتورها...${NC}"

python3 -c "
import os, json

paths = [
    '~/.config/Antigravity/User/settings.json',
    '~/.config/Code/User/settings.json',
    '~/.config/Cursor/User/settings.json',
    '~/.config/Trae/User/settings.json',
    '~/.config/VSCodium/User/settings.json',
    '~/.config/Windsurf/User/settings.json'
]

for p in paths:
    full_path = os.path.expanduser(p)
    if os.path.exists(full_path):
        try:
            with open(full_path, 'r', encoding='utf-8') as f:
                content = f.read().strip()
            
            clean_lines = [line for line in content.split('\n') if not line.strip().startswith('//')]
            try:
                data = json.loads('\n'.join(clean_lines))
            except Exception:
                data = {}

            data['editor.fontFamily'] = \"Vazirmatn, Menlo, Monaco, monospace\"
            data['editor.renderWhitespace'] = 'boundary'
            
            with open(full_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            print(f'✔ تنظیمات فونت روی {p} اعمال شد.')
        except Exception as e:
            print(f'❌ خطا در بروزرسانی {p}: {e}')
"

# 4. Setup Auto-Persistence in Linux
echo ""
echo -e "${YELLOW}۴. در حال راه‌اندازی سرویس ماندگاری دائمی پس از آپدیت‌ها...${NC}"
PERSIST_DIR="$HOME/.local/share/antigravity-rtl"
mkdir -p "$PERSIST_DIR"
if [ -f "scripts/patch_antigravity_linux.sh" ]; then
    cp -f "scripts/patch_antigravity_linux.sh" "$PERSIST_DIR/patch_antigravity.sh"
    chmod +x "$PERSIST_DIR/patch_antigravity.sh"
fi

mkdir -p "$HOME/.config/systemd/user"
cat << EOF_SERVICE > "$HOME/.config/systemd/user/antigravity-rtl.service"
[Unit]
Description=Antigravity RTL Auto-Patcher

[Service]
Type=oneshot
ExecStart=$PERSIST_DIR/patch_antigravity.sh
EOF_SERVICE

if [ -n "$APP_ASAR" ]; then
cat << EOF_PATH > "$HOME/.config/systemd/user/antigravity-rtl.path"
[Unit]
Description=Watch Antigravity app.asar for updates

[Path]
PathModified=$APP_ASAR
Unit=antigravity-rtl.service

[Install]
WantedBy=paths.target
EOF_PATH

    systemctl --user daemon-reload &>/dev/null
    systemctl --user enable --now antigravity-rtl.path &>/dev/null
    echo -e "${GREEN}✔ سرویس پایش خودکار systemd با موفقیت فعال شد.${NC}"
fi

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}عملیات پایان یافت! لطفاً ادیتورها را بازنشانی کنید.${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
read -p "برای خروج کلید Enter را فشار دهید..."
