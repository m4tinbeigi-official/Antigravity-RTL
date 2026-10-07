# Antigravity RTL Auto-Patcher Script for Windows
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

$BackupPath = "$AppAsarPath.bak"
$LogFile = "$env:LOCALAPPDATA\Antigravity-RTL\patcher.log"

if (-not (Test-Path "$env:LOCALAPPDATA\Antigravity-RTL")) {
    New-Item -Path "$env:LOCALAPPDATA\Antigravity-RTL" -ItemType Directory -Force | Out-Null
}

function Log-Message ($msg) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

if (-not $AppAsarPath -or -not (Test-Path $AppAsarPath)) {
    exit
}

$AsarCmd = $null
if (Get-Command npx -ErrorAction SilentlyContinue) {
    $AsarCmd = "npx @electron/asar"
}

if ($AsarCmd) {
    $TempExtracted = "$env:TEMP\extracted_app_watcher"
    if (Test-Path $TempExtracted) {
        Remove-Item -Path $TempExtracted -Recurse -Force -ErrorAction SilentlyContinue
    }

    Invoke-Expression "$AsarCmd extract `"$AppAsarPath`" `"$TempExtracted`""
    
    $PreloadPath = Get-ChildItem -Path $TempExtracted -Filter "preload.js" -Recurse | Select-Object -First 1
    $MainPath = Get-ChildItem -Path $TempExtracted -Filter "main.js" -Recurse | Select-Object -First 1

    $NeedsRepack = $false

    if ($PreloadPath) {
        $Content = Get-Content -Path $PreloadPath.FullName -Raw
        if (-not ($Content -like "*persian-rtl-vazirmatn-style*")) {
            Log-Message "Antigravity update detected. Re-applying RTL patch to preload..."
            Copy-Item -Path $AppAsarPath -Destination $BackupPath -Force
            
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
            Log-Message "Re-applying RTL patch to main..."
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
        Log-Message "✔ Antigravity app.asar successfully re-patched."
    }

    Remove-Item -Path $TempExtracted -Recurse -Force -ErrorAction SilentlyContinue
}
