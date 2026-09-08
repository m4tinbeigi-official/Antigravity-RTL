# Antigravity RTL Auto-Patcher Script for Windows
$AppAsarPath = "$env:LOCALAPPDATA\Programs\Antigravity\resources\app.asar"
$BackupPath = "$AppAsarPath.bak"
$LogFile = "$env:LOCALAPPDATA\Antigravity-RTL\patcher.log"

if (-not (Test-Path "$env:LOCALAPPDATA\Antigravity-RTL")) {
    New-Item -Path "$env:LOCALAPPDATA\Antigravity-RTL" -ItemType Directory -Force | Out-Null
}

function Log-Message ($msg) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

if (-not (Test-Path $AppAsarPath)) {
    exit
}

if (Get-Command npx -ErrorAction SilentlyContinue) {
    $TempExtracted = "$env:TEMP\extracted_app_watcher"
    npx asar extract $AppAsarPath $TempExtracted
    
    $PreloadPath = Get-ChildItem -Path $TempExtracted -Filter "preload.js" -Recurse | Select-Object -First 1
    if ($PreloadPath) {
        $Content = Get-Content -Path $PreloadPath.FullName -Raw
        if (-not ($Content -like "*persian-rtl-vazirmatn-style*")) {
            Log-Message "Antigravity update detected. Re-applying RTL patch..."
            Copy-Item -Path $AppAsarPath -Destination $BackupPath -Force
            
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
            Log-Message "✔ Antigravity app.asar successfully re-patched."
        }
    }
    Remove-Item -Path $TempExtracted -Recurse -Force -ErrorAction SilentlyContinue
}
