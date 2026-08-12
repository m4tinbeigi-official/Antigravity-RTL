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
$LatestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/rastikerdar/vazirmatn/releases/latest"
$ZipUrl = ($LatestRelease.assets | Where-Object { $_.name -like "*.zip" }).browser_download_url | Select-Object -First 1

if (-not $ZipUrl) {
    $ZipUrl = "https://github.com/rastikerdar/vazirmatn/releases/download/v33.003/vazirmatn-v33.003.zip"
}

$TempZip = "$env:TEMP\vazirmatn.zip"
$TempFolder = "$env:TEMP\vazirmatn_extracted"

Write-Host "در حال دانلود فونت..."
Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip

if (Test-Path $TempZip) {
    Write-Host "در حال استخراج و نصب فونت..."
    Expand-Archive -Path $TempZip -DestinationPath $TempFolder -Force
    
    # Target Fonts Folder for Current User
    $FontsFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    if (-not (Test-Path $FontsFolder)) {
        New-Item -Path $FontsFolder -ItemType Directory | Out-Null
    }
    
    $TtfFiles = Get-ChildItem -Path $TempFolder -Filter "*.ttf" -Recurse
    
    # Copy and register each font
    foreach ($File in $TtfFiles) {
        $TargetFile = Join-Path $FontsFolder $File.Name
        Copy-Item -Path $File.FullName -Destination $TargetFile -Force
        
        # Registry key for active user font registration
        $RegPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
        $FontName = $File.BaseName + " (TrueType)"
        Set-ItemProperty -Path $RegPath -Name $FontName -Value $File.Name | Out-Null
    }
    
    # Cleanup
    Remove-Item -Path $TempZip -Force
    Remove-Item -Path $TempFolder -Recurse -Force
    Write-Host "✔ فونت وزیرمتن با موفقیت روی ویندوز نصب شد." -ForegroundColor Green
} else {
    Write-Host "❌ خطا در دانلود فونت. اتصال اینترنت خود را بررسی کنید." -ForegroundColor Red
}

# 2. Patch Antigravity App UI on Windows
Write-Host ""
Write-Host "۲. در حال راست‌چین‌سازی ظاهر عمومی برنامه Antigravity..." -ForegroundColor Yellow
$AppAsarPath = "$env:LOCALAPPDATA\Programs\Antigravity\resources\app.asar"

if (Test-Path $AppAsarPath) {
    Write-Host "برنامه یافت شد. در حال اعمال پچ..."
    
    # Backup
    $BackupPath = "$AppAsarPath.bak"
    if (-not (Test-Path $BackupPath)) {
        Copy-Item -Path $AppAsarPath -Destination $BackupPath -Force
    }
    
    # Extract, patch, and repack requires Node.js/npx asar
    if (Get-Command npx -ErrorAction SilentlyContinue) {
        $TempExtracted = "$env:TEMP\extracted_app"
        npx asar extract $AppAsarPath $TempExtracted
        
        $PreloadPath = Get-ChildItem -Path $TempExtracted -Filter "preload.js" -Recurse | Select-Object -First 1
        
        if ($PreloadPath) {
            $Content = Get-Content -Path $PreloadPath.FullName -Raw
            if (-not ($Content -like "*persian-rtl-vazirmatn-style*")) {
                $InjectCode = @"

// RTL & Font Injector - Persian Gravity Project
window.addEventListener('DOMContentLoaded', () => {
    const style = document.createElement('style');
    style.id = 'persian-rtl-vazirmatn-style';
    style.innerHTML = \`
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
    \`;
    document.head.appendChild(style);
});
"@
                Add-Content -Path $PreloadPath.FullName -Value $InjectCode
                npx asar pack $TempExtracted $AppAsarPath
                Remove-Item -Path $TempExtracted -Recurse -Force
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

$EditorPaths = @(
    "$env:APPDATA\Antigravity\User\settings.json",
    "$env:APPDATA\Code\User\settings.json",
    "$env:APPDATA\Cursor\User\settings.json",
    "$env:APPDATA\Trae\User\settings.json",
    "$env:APPDATA\VSCodium\User\settings.json",
    "$env:APPDATA\Windsurf\User\settings.json"
)

foreach ($Path in $EditorPaths) {
    if (Test-Path $Path) {
        try {
            $Content = Get-Content -Path $Path -Raw
            # Basic cleaning of JSONC comments
            $CleanContent = $Content -replace '//.*', ''
            $Json = ConvertFrom-Json $CleanContent
            
            if (-not $Json) { $Json = @{} }
            
            $Json | Add-Member -NotePropertyName "editor.fontFamily" -NotePropertyValue "Vazirmatn, Consolas, 'Courier New', monospace" -Force
            $Json | Add-Member -NotePropertyName "editor.renderWhitespace" -NotePropertyValue "boundary" -Force
            
            $NewContent = ConvertTo-Json $Json -Depth 10
            Set-Content -Path $Path -Value $NewContent -Encoding utf8
            Write-Host "✔ تنظیمات روی $Path اعمال شد." -ForegroundColor Green
        } catch {
            Write-Host "❌ خطا در بروزرسانی فایل تنظیمات $Path" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "عملیات با موفقیت پایان یافت! لطفاً ادیتورها را بازنشانی کنید." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Read-Host "برای خروج کلید Enter را فشار دهید..."
