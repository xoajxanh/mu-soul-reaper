$projectDir = (Get-Item "$PSScriptRoot\..\..").FullName
if (-not (Test-Path "$projectDir\adb.exe")) {
    $projectDir = "D:\MUVH\android\mu-decompiled"
}
$testDir = "$projectDir\final\excute_test"
$inputFile = "$testDir\input.txt"
$luacExe = "$projectDir\lua53\luac53.exe"
$convertScript = "$projectDir\convert_64_to_32.py"
$tempLuac = "$testDir\input.luac"
$androidPath = "/storage/emulated/0/Android/data/com.vnyh.gp/files/input.luac"

$adbExe = "$testDir\adb.exe"
if (-not (Test-Path $adbExe)) {
    $adbExe = "$projectDir\adb.exe"
} 
if (-not (Test-Path $adbExe)) {
    $adbExe = "adb"
}

# Android Device ID do USER tu chon va quan ly
$androidId = "emulator-5562"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ">>> BIEN DICH & NAP SCRIPT TEST VAO ANDROID ($androidId) <<<" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $inputFile)) {
    Write-Host "LOI: Khong tim thay file input.txt!" -ForegroundColor Red
    Pause
    exit
}

# 1. Compile to luac
Write-Host "1. Bien dich input.txt sang Bytecode..."
& $luacExe "-s" "-o" $tempLuac $inputFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "LOI: Bien dich Lua that bai (Sai cu phap)!" -ForegroundColor Red
    Pause
    exit
}

# 2. Convert to 32-bit
Write-Host "2. Chuyen doi sang 32-bit..."
python $convertScript $tempLuac $tempLuac
if ($LASTEXITCODE -ne 0) {
    Write-Host "LOI: Chuyen doi 64-bit sang 32-bit that bai!" -ForegroundColor Red
    Pause
    exit
}

# 3. Patch header (giong trong compile_lua.py)
Write-Host "3. Patch Header Lua 5.3 32-bit..."
python -c "
with open(r'$tempLuac', 'rb') as f: data = bytearray(f.read())
if data[0:4] == b'\x1bLua':
    data[5] = 0x01
    del data[14]
    with open(r'$tempLuac', 'wb') as f: f.write(data)
"

# 4. Push to Android
Write-Host "4. Xoa output.txt cu va day file input.luac vao $androidId..."
& $adbExe -s $androidId shell "rm -f /storage/emulated/0/Android/data/com.vnyh.gp/files/output.txt"
& $adbExe -s $androidId push $tempLuac $androidPath

Write-Host ""
Write-Host "-> DA NAP SCRIPT THANH CONG VAO THIET BI $androidId!" -ForegroundColor Green
Write-Host "   - Ban co the bam nut [EXEC] mau do trong game." -ForegroundColor Yellow
Write-Host "   - Hoac go 't' roi Enter de tu dong cham [EXEC] tren man hinh." -ForegroundColor Cyan
Write-Host "   - Hoac bam Enter de keo log output.txt ve xem ngay." -ForegroundColor Gray
$choice = Read-Host "Lua chon [Enter=Lay log / t=Tap EXEC]"

if ($choice -eq 't' -or $choice -eq 'T') {
    Write-Host "Dang cham nut [EXEC] tai toa do (30, 910)..." -ForegroundColor Yellow
    & $adbExe -s $androidId shell input tap 30 910
    Start-Sleep -Seconds 2
}

# 5. Pull output
Write-Host "Dang lay output.txt ve..."
$destOut = "$testDir\output.txt"
& $adbExe -s $androidId pull "/storage/emulated/0/Android/data/com.vnyh.gp/files/output.txt" $destOut 2>$null

if (Test-Path $destOut) {
    Write-Host ""
    Write-Host "==================== [KET QUA OUTPUT.TXT] ====================" -ForegroundColor Green
    Get-Content $destOut -Tail 40
    Write-Host "==============================================================" -ForegroundColor Green
}
else {
    Write-Host "Chua co file output.txt tren thiet bi!" -ForegroundColor Yellow
}

while ($true) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "Lua chon tiep theo:" -ForegroundColor Cyan
    Write-Host "   [Enter] / [l] : Keo log output.txt moi nhat ve xem" -ForegroundColor Green
    Write-Host "   [t]           : Tap nut [EXEC] tai toa do (30, 910)" -ForegroundColor Yellow
    Write-Host "   [q]           : Thoat" -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan
    $act = Read-Host "Nhap lua chon [Enter=Keo log / t=EXEC / q=Thoat]"
    if ($act -eq 'q' -or $act -eq 'Q') { break }
    if ($act -eq 't' -or $act -eq 'T') {
        Write-Host "Dang cham nut [EXEC] tai toa do (30, 910)..." -ForegroundColor Yellow
        & $adbExe -s $androidId shell input tap 30 910
        Start-Sleep -Seconds 1
    }
    Write-Host "Dang lay output.txt ve..."
    & $adbExe -s $androidId pull "/storage/emulated/0/Android/data/com.vnyh.gp/files/output.txt" $destOut 2>$null
    if (Test-Path $destOut) {
        Write-Host ""
        Write-Host "==================== [KET QUA OUTPUT.TXT] ====================" -ForegroundColor Green
        Get-Content $destOut -Tail 40
        Write-Host "==============================================================" -ForegroundColor Green
    }
    else {
        Write-Host "Chua co file output.txt tren thiet bi!" -ForegroundColor Yellow
    }
}
