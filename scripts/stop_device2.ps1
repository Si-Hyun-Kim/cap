# stop_device2.ps1 - Windows 11 장치 2 중지

Write-Host ""
Write-Host "🛑 장치 2 서비스 중지 중..." -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$device2Path = Join-Path $projectRoot "device2"

Set-Location $device2Path

$stopped = 0

# PID 파일로 중지
if (Test-Path "pids") {
    Get-ChildItem "pids\*.pid" | ForEach-Object {
        $pidFile = $_.FullName
        $pid = Get-Content $pidFile
        
        if (Get-Process -Id $pid -ErrorAction SilentlyContinue) {
            Stop-Process -Id $pid -Force
            Write-Host "  ● $($_.BaseName) 중지 (PID: $pid)" -ForegroundColor Red
            $stopped++
        }
        
        Remove-Item $pidFile -Force
    }
}

# 프로세스 이름으로도 중지
Get-Process | Where-Object {$_.Path -like "*device2*python*"} | ForEach-Object {
    Stop-Process -Id $_.Id -Force
    $stopped++
}

Write-Host ""

# Ollama 중지 여부 확인
$stopOllama = Read-Host "Ollama도 중지하시겠습니까? (y/N)"
if ($stopOllama -eq "y" -or $stopOllama -eq "Y") {
    Get-Process ollama -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "  ● Ollama 중지" -ForegroundColor Red
    $stopped++
}

Write-Host ""
Write-Host "✓ $stopped 개 서비스 중지 완료" -ForegroundColor Green
Write-Host ""