param(
    [string]$Mode = "",
    [switch]$NoPause
)

$ErrorActionPreference = "Continue"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Thiet lap PATH chuan cho Python va Java
$env:JAVA_HOME = "C:\Program Files\Java\jdk-26.0.1"
$env:JAVA_OPTS = "-XX:-UsePerfData"
$env:Path = "C:\Users\xoajx\AppData\Local\Python\bin;C:\Program Files\Java\jdk-26.0.1\bin;" + [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

$rootDir = (Get-Item "$PSScriptRoot\..").FullName
Set-Location $rootDir

$baseApk       = Join-Path $rootDir "base\MU_base.apk"
$signerJar     = Join-Path $rootDir "build\uber-apk-signer.jar"
$compileScript = Join-Path $rootDir "compiled\tools\compile_lua.py"
$packScript    = Join-Path $rootDir "compiled\tools\pack_lua.py"
$compiledDir   = Join-Path $rootDir "compiled"
$compiledLuac  = Join-Path $compiledDir "luac"
$packedLuaMu2  = Join-Path $compiledDir "lua.mu2"
$packedBundles = Join-Path $compiledDir "bundles.txt"
$tempBuildDir  = Join-Path $rootDir "build\temp"

$winrar = "C:\Program Files\WinRAR\WinRAR.exe"
if (-not (Test-Path $winrar)) {
    if (Test-Path "C:\Program Files (x86)\WinRAR\WinRAR.exe") {
        $winrar = "C:\Program Files (x86)\WinRAR\WinRAR.exe"
    }
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     MU SOUL REAPER - BUILD & DEPLOYMENT UTILITY" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "CHON CHE DO BUILD:" -ForegroundColor Yellow
Write-Host " [1] CLIENT   : Build 'dev\client'   -> released\client\MU_client.apk     [MAC DINH]" -ForegroundColor Cyan
Write-Host " [2] CUSTOMER : Build 'dev\customer' -> released\customer\MU_customer.apk" -ForegroundColor Cyan
Write-Host " [0] ALL      : Build TAT CA cac phien ban (CLIENT + CUSTOMER)" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------" -ForegroundColor Gray

if ([string]::IsNullOrWhiteSpace($Mode)) {
    $modeInput = Read-Host "Nhap lua chon (1/2/0) [Nhan Enter = 1 (CLIENT)]"
} else {
    $modeInput = $Mode
    Write-Host "Lua chon tu dong: $modeInput" -ForegroundColor Green
}

$choice = 1
if (-not [string]::IsNullOrWhiteSpace($modeInput)) {
    $parsedInt = 1
    if ([int]::TryParse($modeInput.Trim(), [ref]$parsedInt)) {
        $choice = $parsedInt
    }
}

if (-not (Test-Path $baseApk)) {
    Write-Host "[LOI] Khong tim thay Base APK tai: $baseApk" -ForegroundColor Red
    if (-not $NoPause) { Pause }
    exit 1
}

if (-not (Test-Path $signerJar)) {
    Write-Host "[LOI] Khong tim thay uber-apk-signer.jar tai: $signerJar" -ForegroundColor Red
    if (-not $NoPause) { Pause }
    exit 1
}

function Build-ApkTask {
    param (
        [string]$Name,
        [string]$LuaSrcDir,
        [string]$OutputApkName,
        [string]$TargetFolder
    )

    $tempApkPath = Join-Path $tempBuildDir $OutputApkName

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   BUILDING $OutputApkName (Target: $Name)" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan

    # 0. Don dep moi truong truoc khi build
    if (Test-Path $tempBuildDir) { Remove-Item $tempBuildDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $compiledLuac) { Remove-Item $compiledLuac -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $packedLuaMu2) { Remove-Item $packedLuaMu2 -Force -ErrorAction SilentlyContinue }
    if (Test-Path $packedBundles) { Remove-Item $packedBundles -Force -ErrorAction SilentlyContinue }

    New-Item -ItemType Directory -Path $tempBuildDir -Force | Out-Null
    New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null

    # 1. Compile Lua
    Write-Host "1. Bien dich ma nguon Lua tu: $LuaSrcDir ..." -ForegroundColor Cyan
    if (-not (Test-Path $LuaSrcDir -PathType Container)) {
        Write-Host "[LOI] Thu muc ma nguon Lua khong ton tai: $LuaSrcDir" -ForegroundColor Red
        if (-not $NoPause) { Pause }
        exit 1
    }
    $env:LUA_SRC_DIR = $LuaSrcDir
    & python $compileScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[LOI] Bien dich Lua that bai cho $Name!" -ForegroundColor Red
        if (-not $NoPause) { Pause }
        exit 1
    }

    # 2. Pack lua.mu2 & bundles.txt
    Write-Host "2. Dong goi lua.mu2 va cap nhat bundles.txt..." -ForegroundColor Cyan
    & python $packScript
    if ($LASTEXITCODE -ne 0 -or (-not (Test-Path $packedLuaMu2))) {
        Write-Host "[LOI] Dong goi lua.mu2 that bai cho $Name!" -ForegroundColor Red
        if (-not $NoPause) { Pause }
        exit 1
    }

    # 3. Copy Base APK sang build\temp
    Write-Host "3. Khoi tao APK tam tu base\MU_base.apk..." -ForegroundColor Cyan
    Copy-Item -Path $baseApk -Destination $tempApkPath -Force

    # 4. Inject lua.mu2 va bundles.txt bang WinRAR (Store mode -m0)
    Write-Host "4. Inject lua.mu2 & bundles.txt vao $OutputApkName..." -ForegroundColor Cyan
    $argsLua = "a -m0 -ep -o+ -ibck -inul -apassets\Bundles `"$tempApkPath`" `"$packedLuaMu2`""
    $pLua = Start-Process -FilePath $winrar -ArgumentList $argsLua -Wait -PassThru -NoNewWindow
    if ($pLua.ExitCode -ne 0) {
        Write-Host "[LOI] WinRAR inject lua.mu2 that bai! (ExitCode: $($pLua.ExitCode))" -ForegroundColor Red
        if (-not $NoPause) { Pause }
        exit 1
    }

    if (Test-Path $packedBundles) {
        $argsBundles = "a -m0 -ep -o+ -ibck -inul -apassets `"$tempApkPath`" `"$packedBundles`""
        $pBundles = Start-Process -FilePath $winrar -ArgumentList $argsBundles -Wait -PassThru -NoNewWindow
        if ($pBundles.ExitCode -ne 0) {
            Write-Host "[LOI] WinRAR inject bundles.txt that bai! (ExitCode: $($pBundles.ExitCode))" -ForegroundColor Red
            if (-not $NoPause) { Pause }
            exit 1
        }
    }

    # 5. Sign APK voi uber-apk-signer
    Write-Host "5. Ky APK voi build\uber-apk-signer.jar..." -ForegroundColor Cyan
    $javaExe = "C:\Program Files\Java\jdk-26.0.1\bin\java.exe"
    if (-not (Test-Path $javaExe)) { $javaExe = "java" }
    $signArgs = @("-XX:-UsePerfData", "-jar", $signerJar, "-a", $tempApkPath, "--allowResign", "--overwrite")
    $pSign = Start-Process -FilePath $javaExe -ArgumentList $signArgs -Wait -PassThru -NoNewWindow
    if ($pSign.ExitCode -ne 0) {
        Write-Host "[LOI] Ky APK that bai cho $OutputApkName! (ExitCode: $($pSign.ExitCode))" -ForegroundColor Red
        if (-not $NoPause) { Pause }
        exit 1
    }

    # 6. Chuyen APK da ky sang thu muc released tuong ung
    $destPath = Join-Path $TargetFolder $OutputApkName
    Write-Host "6. Xuat APK ra: $destPath ..." -ForegroundColor Cyan
    if (Test-Path $destPath) { Remove-Item $destPath -Force -ErrorAction SilentlyContinue }
    Copy-Item -Path $tempApkPath -Destination $destPath -Force

    if (-not (Test-Path $destPath)) {
        Write-Host "[LOI] Khong the copy APK sang $destPath!" -ForegroundColor Red
        if (-not $NoPause) { Pause }
        exit 1
    }

    $srcSize = (Get-Item $tempApkPath).Length
    $dstSize = (Get-Item $destPath).Length
    if ($srcSize -ne $dstSize) {
        Write-Host "[LOI] Dung luong file sau khi sao chep bi lech! ($srcSize != $dstSize)" -ForegroundColor Red
        if (-not $NoPause) { Pause }
        exit 1
    }
    Write-Host "-> Da xuat thanh cong: $destPath" -ForegroundColor Green

    # 7. Don dep sach se file trung gian sau moi task
    if (Test-Path $tempBuildDir) { Remove-Item $tempBuildDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $compiledLuac) { Remove-Item $compiledLuac -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $packedLuaMu2) { Remove-Item $packedLuaMu2 -Force -ErrorAction SilentlyContinue }
    if (Test-Path $packedBundles) { Remove-Item $packedBundles -Force -ErrorAction SilentlyContinue }
}

# Thuc thi theo lua chon (1 = CLIENT, 2 = CUSTOMER, 0 = ALL)
if ($choice -eq 1 -or $choice -eq 0) {
    Build-ApkTask -Name "CLIENT" `
                  -LuaSrcDir (Join-Path $rootDir "dev\client") `
                  -OutputApkName "MU_client.apk" `
                  -TargetFolder (Join-Path $rootDir "released\client")
}

if ($choice -eq 2 -or $choice -eq 0) {
    Build-ApkTask -Name "CUSTOMER" `
                  -LuaSrcDir (Join-Path $rootDir "dev\customer") `
                  -OutputApkName "MU_customer.apk" `
                  -TargetFolder (Join-Path $rootDir "released\customer")
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " [SUCCESS] QUY TRINH BUILD & DEPLOY HOAN TAT!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

$releasedRoot = Join-Path $rootDir "released"
if (Test-Path $releasedRoot) {
    Start-Process "explorer.exe" -ArgumentList "`"$releasedRoot`""
}

if (-not $NoPause) { Pause }
