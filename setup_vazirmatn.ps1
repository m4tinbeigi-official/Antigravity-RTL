# Setup Vazirmatn and RTL for Windows
# Project: Persian Gravity 🚀
# Dedicated to the memory of Saber Rastikerdar (خالق وزیرمتن)

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  نصب فونت وزیرمتن و تنظیم راست‌چین ادیتورها  " -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "    به یاد صابر راستی‌کردار، خالق وزیرمتن    " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Download and Install Vazirmatn Font
Write-Host "۱. در حال دریافت آخرین نسخه فونت وزیرمتن..." -ForegroundColor Yellow
 = Invoke-RestMethod -Uri "https://api.github.com/repos/rastikerdar/vazirmatn/releases/latest"
 = (.assets | Where-Object { .name -like "*.zip" }).browser_download_url | Select-Object -First 1

if (-not ) {
     = "https://github.com/rastikerdar/vazirmatn/releases/download/v33.003/vazirmatn-v33.003.zip"
}

 = ":TEMP\vazirmatn.zip"
 = ":TEMP\vazirmatn_extracted"

Write-Host "در حال دانلود فونت..."
Invoke-WebRequest -Uri  -OutFile 

if (Test-Path ) {
    Write-Host "در حال استخراج و نصب فونت..."
    Expand-Archive -Path  -DestinationPath  -Force
    
    # Target Fonts Folder for Current User
     = ":LOCALAPPDATA\Microsoft\Windows\Fonts"
    if (-not (Test-Path )) {
        New-Item -Path  -ItemType Directory | Out-Null
    }
    
     = Get-ChildItem -Path  -Filter "*.ttf" -Recurse
    
    # Copy and register each font
    foreach ( in ) {
         = Join-Path  .Name
        Copy-Item -Path .FullName -Destination  -Force
        
        # Registry key for active user font registration
         = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
         = .BaseName + " (TrueType)"
        Set-ItemProperty -Path  -Name  -Value .Name | Out-Null
    }
    
    # Cleanup
    Remove-Item -Path  -Force
    Remove-Item -Path  -Recurse -Force
    Write-Host "✔ فونت وزیرمتن با موفقیت روی ویندوز نصب شد." -ForegroundColor Green
} else {
    Write-Host "❌ خطا در دانلود فونت. اتصال اینترنت خود را بررسی کنید." -ForegroundColor Red
}

# 2. Patch Antigravity App UI on Windows
Write-Host ""
Write-Host "۲. در حال راست‌چین‌سازی ظاهر عمومی برنامه Antigravity..." -ForegroundColor Yellow
 = ":LOCALAPPDATA\Programs\Antigravity\resources\app.asar"

if (Test-Path ) {
    Write-Host "برنامه یافت شد. در حال اعمال پچ..."
    
    # Backup
     = ".bak"
    if (-not (Test-Path )) {
        Copy-Item -Path  -Destination  -Force
    }
    
    # Extract, patch, and repack requires Node.js/npx asar
    if (Get-Command npx -ErrorAction SilentlyContinue) {
         = ":TEMP\extracted_app"
        npx asar extract  
        
         = Get-ChildItem -Path  -Filter "preload.js" -Recurse | Select-Object -First 1
        
        if () {
             = Get-Content -Path .FullName -Raw
            if (-not ( -like "*persian-rtl-vazirmatn-style*")) {
                 = @"

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
"@
                Add-Content -Path .FullName -Value 
                npx asar pack  
                Remove-Item -Path  -Recurse -Force
                Write-Host "✔ ظاهر نرم‌افزار با موفقیت پچ شد." -ForegroundColor Green
            } else {
                Write-Host "ℹ️ پچ راست‌چین پیش از این روی نرم‌افزار اعمال شده است." -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "⚠️ ابزار Node.js (npx) جهت باز کردن و پچ کردن فایل‌های هسته برنامه نصب نیست." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ فایل برنامه Antigravity در مسیرهای استاندارد ویندوز یافت نشد." -ForegroundColor Yellow
}

# 3. Update settings.json for Windows Editors
Write-Host ""
Write-Host "۳. در حال اعمال تنظیمات روی ادیتورها..." -ForegroundColor Yellow

 = @(
    "PPDATA\Antigravity\User\settings.json",
    "PPDATA\Code\User\settings.json",
    "PPDATA\Cursor\User\settings.json",
    "PPDATA\Trae\User\settings.json",
    "PPDATA\VSCodium\User\settings.json",
    "PPDATA\Windsurf\User\settings.json"
)

foreach ( in ) {
    if (Test-Path ) {
        try {
             = Get-Content -Path  -Raw
            # Basic cleaning of JSONC comments
             =  -replace '//.*', ''
             = ConvertFrom-Json 
            
            if (-not ) {  = @{} }
            
             | Add-Member -NotePropertyName "editor.fontFamily" -NotePropertyValue "Vazirmatn, Consolas, 'Courier New', monospace" -Force
             | Add-Member -NotePropertyName "editor.renderWhitespace" -NotePropertyValue "boundary" -Force
            
             = ConvertTo-Json  -Depth 10
            Set-Content -Path  -Value  -Encoding utf8
            Write-Host "✔ تنظیمات روی  اعمال شد." -ForegroundColor Green
        } catch {
            Write-Host "❌ خطا در بروزرسانی فایل تنظیمات " -ForegroundColor Red
        }
    }
}

# 4. Setup Auto-Persistence Task
Write-Host ""
Write-Host "۴. در حال راه‌اندازی سرویس ماندگاری دائمی پچ پس از آپدیت‌ها..." -ForegroundColor Yellow
 = ":LOCALAPPDATA\Antigravity-RTL"
if (-not (Test-Path )) {
    New-Item -Path  -ItemType Directory -Force | Out-Null
}

 = Join-Path  "scripts\patch_antigravity.ps1"
if (Test-Path ) {
    Copy-Item -Path  -Destination (Join-Path  "patch_antigravity.ps1") -Force
}

try {
     = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"\patch_antigravity.ps1`""
     = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName "AntigravityRTLAutoPatch" -Action  -Trigger  -Description "Auto-reapplies RTL patch after Antigravity updates" -Force | Out-Null
    Write-Host "✔ تسک ماندگاری دائمی (Scheduled Task) در ویندوز با موفقیت ثبت شد." -ForegroundColor Green
} catch {
    Write-Host "ℹ️ راه‌اندازی Task خودکار با دسترسی عادی ممکن نشد (در صورت نیاز با دسترسی Administrator اجرا کنید)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "عملیات با موفقیت پایان یافت! لطفاً ادیتورها را بازنشانی کنید." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Read-Host "برای خروج کلید Enter را فشار دهید..."
