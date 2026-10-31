param (
    [string]$Target = "$PSScriptRoot\exec_cmd.ps1",
    [string]$Command = ""
)

# Thiet lap ma hoa UTF-8 cho toan bo output va input console
try {
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}
$OutputEncoding = [System.Text.Encoding]::UTF8

# Vo hieu hoa pager de cac lenh Git (git log, git diff,...) khong bao gio bi treo cho phim Bam
$env:GIT_PAGER = "cat"
$env:PAGER = "cat"
$env:JAVA_HOME = "C:\Program Files\Java\jdk-26.0.1"
$env:JAVA_OPTS = "-XX:-UsePerfData"
$env:PATH = "C:\Users\xoajx\AppData\Local\Python\bin;C:\Program Files\Java\jdk-26.0.1\bin;$env:USERPROFILE\.local\share\jadx\bin;$env:PATH"

# Tu dong tim thu muc goc chua .git (Project Root)
$rootDir = (Get-Item "$PSScriptRoot\..").FullName
if (-not (Test-Path "$rootDir\.git")) {
    $curr = $PSScriptRoot
    while ($curr -and (-not (Test-Path "$curr\.git"))) {
        $parent = Split-Path -Parent $curr
        if ($parent -eq $curr) { break }
        $curr = $parent
    }
    if (Test-Path "$curr\.git") { $rootDir = $curr } else { $rootDir = (Get-Item "$PSScriptRoot\..").FullName }
}
$global:ProjectRoot = $rootDir
$global:GitRoot = $rootDir
$env:PROJECT_ROOT = $rootDir

Write-Host "==================== [AGENT MASTER EXECUTOR] ====================" -ForegroundColor Cyan
Write-Host "Thoi gian   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Project Root: $global:ProjectRoot" -ForegroundColor DarkCyan

if (-not [string]::IsNullOrWhiteSpace($Command)) {
    Write-Host "Dang thuc thi Command : $Command" -ForegroundColor Yellow
} else {
    Write-Host "Dang thuc thi Script  : $Target" -ForegroundColor Gray
}
Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray

$sw = [System.Diagnostics.Stopwatch]::StartNew()

try {
    if (-not [string]::IsNullOrWhiteSpace($Command)) {
        # Thuc thi truc tiep lenh PowerShell / Git / Python truyen vao
        Invoke-Expression $Command
        $exitCode = if ($LASTEXITCODE -ne $null) { $LASTEXITCODE } else { 0 }
    } else {
        if (-not (Test-Path $Target)) {
            Write-Host "[ERROR] Khong tim thay file kich ban: $Target" -ForegroundColor Red
            exit 1
        }
        # Chay file kich ban duoc chi dinh (vd: exec_cmd.ps1)
        . $Target
        $exitCode = if ($LASTEXITCODE -ne $null) { $LASTEXITCODE } else { 0 }
    }
    
    $sw.Stop()
    Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[SUCCESS] Thuc thi thanh cong trong $($sw.ElapsedMilliseconds)ms (ExitCode: $exitCode)" -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Cyan
    exit $exitCode
}
catch {
    $sw.Stop()
    Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[FAILED] Gap loi ngoai le khi thuc thi: $_" -ForegroundColor Red
    Write-Host "Stack Trace:`n$($_.ScriptStackTrace)" -ForegroundColor DarkRed
    Write-Host "=========================================================" -ForegroundColor Cyan
    exit 1
}
