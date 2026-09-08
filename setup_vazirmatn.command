#!/bin/bash

# Change directory to the script's directory
cd "$(dirname "$0")"

# Colors for terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Clear terminal screen
clear

# Header Art
echo -e "${CYAN}=====================================================${NC}"
echo -e "${YELLOW}           شتاب فارسی (Persian Gravity) 🚀           ${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo -e "${GREEN}    به یاد صابر راستی‌کردار، خالق فونت‌های آزاد فارسی    ${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo ""

# Functions
show_menu() {
    echo -e "${BLUE}لطفاً عملیات مورد نظر را انتخاب کنید:${NC}"
    echo -e "1) ${GREEN}نصب فونت و اعمال پچ راست‌چین‌سازی کامل (به همراه ماندگاری دائمی)${NC}"
    echo -e "2) ${CYAN}فعال‌سازی / بررسی وضعیت سرویس ماندگاری خودکار (Auto-Persistence Daemon)${NC}"
    echo -e "3) ${YELLOW}غیرفعال‌سازی سرویس ماندگاری خودکار${NC}"
    echo -e "4) ${RED}بازگرداندن برنامه‌ها به حالت اولیه (Restore Backup)${NC}"
    echo -e "5) خروج"
    echo ""
    read -p "انتخاب شما (1-5): " main_choice
}

choose_font() {
    echo ""
    echo -e "${BLUE}لطفاً فونت برنامه‌نویسی مورد نظر خود را انتخاب کنید:${NC}"
    echo -e "1) ${GREEN}وزیرمتن (Vazirmatn)${NC} [پیش‌فرض و پیشنهادی]"
    echo -e "2) شبنم (Shabnam)"
    echo -e "3) ساحل (Sahel)"
    echo -e "4) صمیم (Samim)"
    echo ""
    read -p "انتخاب شما (1-4) [پیش‌فرض 1]: " font_choice
    
    case $font_choice in
        2)
            FONT_NAME="Shabnam"
            ZIP_URL="https://github.com/rastikerdar/shabnam-font/releases/download/v5.0.2/shabnam-font-v5.0.2.zip"
            ;;
        3)
            FONT_NAME="Sahel"
            ZIP_URL="https://github.com/rastikerdar/sahel-font/releases/download/v3.4.0/sahel-font-v3.4.0.zip"
            ;;
        4)
            FONT_NAME="Samim"
            ZIP_URL="https://github.com/rastikerdar/samim-font/releases/download/v4.0.5/samim-font-v4.0.5.zip"
            ;;
        *)
            FONT_NAME="Vazirmatn"
            # Get latest version link from API
            LATEST_ZIP_URL=$(curl -s https://api.github.com/repos/rastikerdar/vazirmatn/releases/latest | grep "browser_download_url.*zip" | head -n 1 | cut -d '"' -f 4)
            if [ -z "$LATEST_ZIP_URL" ]; then
                ZIP_URL="https://github.com/rastikerdar/vazirmatn/releases/download/v33.003/vazirmatn-v33.003.zip"
            else
                ZIP_URL="$LATEST_ZIP_URL"
            fi
            ;;
    esac
}

install_font() {
    echo -e "\n${YELLOW}[۱/۴] در حال دانلود و نصب فونت $FONT_NAME...${NC}"
    curl -L -o /tmp/persian_font.zip "$ZIP_URL"
    
    if [ $? -eq 0 ]; then
        unzip -q /tmp/persian_font.zip -d /tmp/persian_font
        mkdir -p ~/Library/Fonts
        
        # Copy all ttf files recursively
        find /tmp/persian_font -name "*.ttf" -exec cp {} ~/Library/Fonts/ \;
        
        rm -rf /tmp/persian_font.zip /tmp/persian_font
        echo -e "${GREEN}✔ فونت $FONT_NAME با موفقیت روی سیستم‌عامل شما نصب شد.${NC}"
    else
        echo -e "${RED}❌ خطا در دانلود فونت. لطفاً اتصال اینترنت خود را بررسی کنید.${NC}"
        exit 1
    fi
}

patch_app() {
    echo -e "\n${YELLOW}[۲/۴] در حال راست‌چین‌سازی ظاهر عمومی برنامه Antigravity...${NC}"
    
    if [ -d "/Applications/Antigravity.app" ]; then
        # Check if asar package is available
        if ! command -v npx &> /dev/null; then
            echo -e "${RED}❌ ابزار Node.js/npx روی سیستم یافت نشد. لطفاً ابتدا Node.js را نصب کنید.${NC}"
            return 1
        fi
        
        echo "در حال استخراج بسته‌های نرم‌افزار..."
        npx asar extract "/Applications/Antigravity.app/Contents/Resources/app.asar" /tmp/extracted_app
        
        if [ $? -eq 0 ]; then
            # Backup original app.asar if backup doesn't exist
            if [ ! -f "/Applications/Antigravity.app/Contents/Resources/app.asar.bak" ]; then
                cp "/Applications/Antigravity.app/Contents/Resources/app.asar" "/Applications/Antigravity.app/Contents/Resources/app.asar.bak"
                echo "✔ یک نسخه پشتیبان از برنامه تهیه شد."
            fi
            
            # Find preload.js location
            PRELOAD_PATH=$(find /tmp/extracted_app -name "preload.js" | head -n 1)
            
            if [ -f "$PRELOAD_PATH" ]; then
                if grep -q "persian-rtl-vazirmatn-style" "$PRELOAD_PATH"; then
                    echo -e "${YELLOW}ℹ️ پچ راست‌چین پیش از این روی نرم‌افزار اعمال شده است.${NC}"
                else
                    echo "در حال تزریق کدهای راست‌چین و فونت..."
                    cat << EOF >> "$PRELOAD_PATH"

// RTL & Font Injector - Persian Gravity Project
window.addEventListener('DOMContentLoaded', () => {
    const style = document.createElement('style');
    style.id = 'persian-rtl-vazirmatn-style';
    style.innerHTML = \`
      @import url('https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css');
      
      * {
        font-family: '$FONT_NAME', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
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
    \`;
    document.head.appendChild(style);
});
EOF
                fi
                
                # Repack asar
                npx asar pack /tmp/extracted_app /tmp/app.asar
                cp /tmp/app.asar "/Applications/Antigravity.app/Contents/Resources/app.asar"
                rm -rf /tmp/extracted_app /tmp/app.asar
                
                # Re-sign app to prevent macOS security block
                echo "در حال تایید امضای دیجیتال محلی برنامه..."
                codesign --force --deep --sign - "/Applications/Antigravity.app" &>/dev/null
                
                echo -e "${GREEN}✔ پچ ظاهر نرم‌افزار با موفقیت اعمال شد.${NC}"
            else
                echo -e "${RED}❌ فایل preload.js جهت پچ کردن پیدا نشد.${NC}"
            fi
        else
            echo -e "${RED}❌ خطا در استخراج بسته نرم‌افزار.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ برنامه Antigravity.app در پوشه /Applications یافت نشد.${NC}"
    fi
}

update_editor_configs() {
    echo -e "\n${YELLOW}[۳/۴] در حال تنظیم فونت روی ادیتورها...${NC}"
    
    python3 -c "
import os, json

paths = [
    '~/Library/Application Support/Antigravity/User/settings.json',
    '~/Library/Application Support/Code/User/settings.json',
    '~/Library/Application Support/Cursor/User/settings.json',
    '~/Library/Application Support/Trae/User/settings.json',
    '~/Library/Application Support/VSCodium/User/settings.json',
    '~/Library/Application Support/Windsurf/User/settings.json'
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

            data['editor.fontFamily'] = "$FONT_NAME, Menlo, Monaco, 'Courier New', monospace"
            data['editor.renderWhitespace'] = 'boundary'
            
            with open(full_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            print(f'✔ تنظیمات فونت روی {p} اعمال شد.')
        except Exception as e:
            print(f'❌ خطا در بروزرسانی {p}: {e}')
"
}

setup_auto_persistence() {
    echo -e "\n${YELLOW}[۴/۴] در حال راه‌اندازی سرویس ماندگاری دائمی پچ پس از آپدیت‌ها (Auto-Persistence Daemon)...${NC}"
    
    HELPER_DIR="$HOME/.antigravity-rtl"
    HELPER_SCRIPT="$HELPER_DIR/patch_antigravity.sh"
    PLIST_PATH="$HOME/Library/LaunchAgents/com.antigravity.rtl.watcher.plist"
    
    mkdir -p "$HELPER_DIR"
    mkdir -p "$HOME/Library/LaunchAgents"
    mkdir -p "$HOME/Library/Logs"
    
    if [ -f "scripts/patch_antigravity.sh" ]; then
        cp -f "scripts/patch_antigravity.sh" "$HELPER_SCRIPT"
    fi
    chmod +x "$HELPER_SCRIPT"
    
    cat << EOF_PLIST > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.antigravity.rtl.watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$HELPER_SCRIPT</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/Applications/Antigravity.app/Contents/Resources/app.asar</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/antigravity-rtl.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/antigravity-rtl-error.log</string>
</dict>
</plist>
EOF_PLIST

    launchctl unload "$PLIST_PATH" &>/dev/null
    launchctl load "$PLIST_PATH" &>/dev/null
    
    echo -e "${GREEN}✔ سرویس پایش خودکار (LaunchAgent) با موفقیت در مک ثبت شد.${NC}"
    echo -e "${GREEN}  از این پس با هر آپدیت Antigravity، پچ راست‌چین به صورت خودکار اعمال خواهد شد.${NC}"
}

disable_auto_persistence() {
    PLIST_PATH="$HOME/Library/LaunchAgents/com.antigravity.rtl.watcher.plist"
    if [ -f "$PLIST_PATH" ]; then
        launchctl unload "$PLIST_PATH" &>/dev/null
        rm -f "$PLIST_PATH"
        echo -e "${GREEN}✔ سرویس پایش خودکار با موفقیت غیرفعال شد.${NC}"
    else
        echo -e "${YELLOW}ℹ️ سرویس پایش خودکار فعال نبود.${NC}"
    fi
}

restore_backup() {
    echo -e "\n${YELLOW}در حال بازگرداندن برنامه‌ها به حالت اولیه...${NC}"
    if [ -f "/Applications/Antigravity.app/Contents/Resources/app.asar.bak" ]; then
        cp "/Applications/Antigravity.app/Contents/Resources/app.asar.bak" "/Applications/Antigravity.app/Contents/Resources/app.asar"
        rm "/Applications/Antigravity.app/Contents/Resources/app.asar.bak"
        
        # Re-sign
        codesign --force --deep --sign - "/Applications/Antigravity.app" &>/dev/null
        echo -e "${GREEN}✔ برنامه Antigravity با موفقیت به حالت اولیه برگشت.${NC}"
    else
        echo -e "${RED}❌ هیچ نسخه پشتیبانی یافت نشد.${NC}"
    fi
}

# --- Main Program Execution ---
show_menu

if [ "$main_choice" == "1" ]; then
    choose_font
    install_font
    patch_app
    update_editor_configs
    setup_auto_persistence
    echo -e "\n${GREEN}=====================================================${NC}"
    echo -e "${GREEN}     عملیات با موفقیت انجام شد! برنامه را بازنشانی کنید.     ${NC}"
    echo -e "${GREEN}=====================================================${NC}"
elif [ "$main_choice" == "2" ]; then
    setup_auto_persistence
elif [ "$main_choice" == "3" ]; then
    disable_auto_persistence
elif [ "$main_choice" == "4" ]; then
    restore_backup
else
    echo "خروج از برنامه."
    exit 0
fi

echo ""
read -p "برای خروج کلید Enter را فشار دهید..."
