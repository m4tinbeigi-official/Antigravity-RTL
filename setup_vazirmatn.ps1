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
$LatestRelease = try {
    Invoke-RestMethod -Uri "https://api.github.com/repos/rastikerdar/vazirmatn/releases/latest" -ErrorAction SilentlyContinue
} catch { $null }

$DownloadUrl = $null
if ($LatestRelease -and $LatestRelease.assets) {
    $DownloadUrl = ($LatestRelease.assets | Where-Object { $_.name -like "*.zip" }).browser_download_url | Select-Object -First 1
}

if (-not $DownloadUrl) {
    $DownloadUrl = "https://github.com/rastikerdar/vazirmatn/releases/download/v33.003/vazirmatn-v33.003.zip"
}

$TempZip = "$env:TEMP\vazirmatn.zip"
$TempExtracted = "$env:TEMP\vazirmatn_extracted"

Write-Host "در حال دانلود فونت..."
Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

if (Test-Path $TempZip) {
    Write-Host "در حال استخراج و نصب فونت..."
    Expand-Archive -Path $TempZip -DestinationPath $TempExtracted -Force
    
    # Target Fonts Folder for Current User
    $FontsFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    if (-not (Test-Path $FontsFolder)) {
        New-Item -Path $FontsFolder -ItemType Directory | Out-Null
    }
    
    $TtfFiles = Get-ChildItem -Path $TempExtracted -Filter "*.ttf" -Recurse
    
    # Copy and register each font
    foreach ($File in $TtfFiles) {
        $TargetFile = Join-Path $FontsFolder $File.Name
        try {
            Copy-Item -Path $File.FullName -Destination $TargetFile -Force -ErrorAction Stop
        } catch {
            # Skip if file is currently locked/in use
        }
        
        # Registry key for active user font registration
        $RegPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
        $FontName = $File.BaseName + " (TrueType)"
        Set-ItemProperty -Path $RegPath -Name $FontName -Value $File.Name -ErrorAction SilentlyContinue | Out-Null
    }
    
    # Cleanup
    Remove-Item -Path $TempZip -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $TempExtracted -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✔ فونت وزیرمتن با موفقیت روی ویندوز نصب شد." -ForegroundColor Green
} else {
    Write-Host "❌ خطا در دانلود فونت. اتصال اینترنت خود را بررسی کنید." -ForegroundColor Red
}

# 2. Patch Antigravity App UI on Windows
Write-Host ""
Write-Host "۲. در حال راست‌چین‌سازی ظاهر عمومی برنامه Antigravity..." -ForegroundColor Yellow

$CandidatePaths = @(
    "$env:LOCALAPPDATA\Programs\Antigravity\resources\app.asar",
    "$env:LOCALAPPDATA\Programs\antigravity\resources\app.asar"
)

$AppAsarPath = $null
foreach ($Cand in $CandidatePaths) {
    if (Test-Path $Cand) {
        $AppAsarPath = $Cand
        break
    }
}

if ($AppAsarPath) {
    Write-Host "برنامه یافت شد ($AppAsarPath). در حال اعمال پچ..."
    
    # Backup
    $BackupPath = "$AppAsarPath.bak"
    if (-not (Test-Path $BackupPath)) {
        Copy-Item -Path $AppAsarPath -Destination $BackupPath -Force
    }

    $ResourcesDir = Split-Path -Parent $AppAsarPath
    $UnpackedDir = Join-Path $ResourcesDir "app.asar.unpacked"
    $BackupUnpacked = Join-Path $ResourcesDir "app.asar.bak.unpacked"
    if ((Test-Path $UnpackedDir) -and (-not (Test-Path $BackupUnpacked))) {
        Copy-Item -Path $UnpackedDir -Destination $BackupUnpacked -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Check for asar tool (prefer @electron/asar)
    $AsarCmd = $null
    if (Get-Command npx -ErrorAction SilentlyContinue) {
        $AsarCmd = "npx @electron/asar"
    }

    if ($AsarCmd) {
        $TempExtracted = "$env:TEMP\extracted_app"
        if (Test-Path $TempExtracted) {
            Remove-Item -Path $TempExtracted -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Extract
        Invoke-Expression "$AsarCmd extract `"$AppAsarPath`" `"$TempExtracted`""
        
        $PreloadPath = Get-ChildItem -Path $TempExtracted -Filter "preload.js" -Recurse | Select-Object -First 1
        $MainPath = Get-ChildItem -Path $TempExtracted -Filter "main.js" -Recurse | Select-Object -First 1
        
        $NeedsRepack = $false

        if ($PreloadPath) {
            $Content = Get-Content -Path $PreloadPath.FullName -Raw
            if (-not ($Content -like "*persian-rtl-vazirmatn-style*")) {
                $InjectCode = @'

// RTL & Font Injector - Persian Gravity Project
window.addEventListener('DOMContentLoaded', () => {
    try {
        const style = document.createElement('style');
        style.id = 'persian-rtl-vazirmatn-style';
        style.textContent = `
          * {
            font-family: 'Vazirmatn', 'Vazirmatn-UI', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
          }
          p, li, span, div, h1, h2, h3, h4, h5, h6, textarea, input, label {
            unicode-bidi: plaintext !important;
            text-align: start !important;
          }
          code, pre, pre *, code *, kbd, .monospace, .monaco-editor, .monaco-editor * {
            font-family: Consolas, Menlo, Monaco, "Fira Code", monospace !important;
            direction: ltr !important;
            unicode-bidi: normal !important;
            text-align: left !important;
          }
        `;
        document.head.appendChild(style);
    } catch (e) {}
});
'@
                Add-Content -Path $PreloadPath.FullName -Value $InjectCode
                $NeedsRepack = $true
            }
        }

        if ($MainPath) {
            $MainContent = Get-Content -Path $MainPath.FullName -Raw
            if (-not ($MainContent -like "*antigravityRtlCss*")) {
                $MainInject = @'

// Antigravity RTL & Vazirmatn Font Injector
const antigravityRtlCss = `
  * {
    font-family: 'Vazirmatn', 'Vazirmatn-UI', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
  }
  p, li, span, div, h1, h2, h3, h4, h5, h6, textarea, input, label {
    unicode-bidi: plaintext !important;
    text-align: start !important;
  }
  code, pre, pre *, code *, kbd, .monospace, .monaco-editor, .monaco-editor * {
    font-family: Consolas, Menlo, Monaco, "Fira Code", monospace !important;
    direction: ltr !important;
    unicode-bidi: normal !important;
    text-align: left !important;
  }
`;

if (typeof electron_1 !== 'undefined' && electron_1.app) {
  electron_1.app.on('web-contents-created', (_event, contents) => {
    const inject = () => { contents.insertCSS(antigravityRtlCss).catch(() => {}); };
    contents.on('dom-ready', inject);
    contents.on('did-finish-load', inject);
    contents.on('did-navigate', inject);
    contents.on('did-navigate-in-page', inject);
  });
}
'@
                Add-Content -Path $MainPath.FullName -Value $MainInject
                $NeedsRepack = $true
            }
        }

        if ($NeedsRepack) {
            Invoke-Expression "$AsarCmd pack `"$TempExtracted`" `"$AppAsarPath`" --unpack-dir `"node_modules/chrome-devtools-mcp`""
            Write-Host "✔ ظاهر نرم‌افزار با موفقیت پچ شد." -ForegroundColor Green
        } else {
            Write-Host "ℹ️ پچ راست‌چین پیش از این روی نرم‌افزار اعمال شده است." -ForegroundColor Yellow
        }

        Remove-Item -Path $TempExtracted -Recurse -Force -ErrorAction SilentlyContinue
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
    "$env:APPDATA\antigravity\User\settings.json",
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

# 4. Setup Auto-Persistence Task
Write-Host ""
Write-Host "۴. در حال راه‌اندازی سرویس ماندگاری دائمی پچ پس از آپدیت‌ها..." -ForegroundColor Yellow
$PersistDir = "$env:LOCALAPPDATA\Antigravity-RTL"
if (-not (Test-Path $PersistDir)) {
    New-Item -Path $PersistDir -ItemType Directory -Force | Out-Null
}

$ScriptSource = Join-Path $PSScriptRoot "scripts\patch_antigravity.ps1"
if (Test-Path $ScriptSource) {
    Copy-Item -Path $ScriptSource -Destination (Join-Path $PersistDir "patch_antigravity.ps1") -Force
}

try {
    $Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PersistDir\patch_antigravity.ps1`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName "AntigravityRTLAutoPatch" -Action $Action -Trigger $Trigger -Description "Auto-reapplies RTL patch after Antigravity updates" -Force | Out-Null
    Write-Host "✔ تسک ماندگاری دائمی (Scheduled Task) در ویندوز با موفقیت ثبت شد." -ForegroundColor Green
} catch {
    Write-Host "ℹ️ راه‌اندازی Task خودکار با دسترسی عادی ممکن نشد (در صورت نیاز با دسترسی Administrator اجرا کنید)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "عملیات با موفقیت پایان یافت! لطفاً ادیتورها را بازنشانی کنید." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
if ([Environment]::UserInteractive) {
    Read-Host "برای خروج کلید Enter را فشار دهید..."
}
