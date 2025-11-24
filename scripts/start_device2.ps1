# start_device2.ps1 - Windows 11 장치 2 시작

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🚀 장치 2 (Windows 11) 시작" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 프로젝트 루트
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$device2Path = Join-Path $projectRoot "device2"

# device2 확인
if (-not (Test-Path $device2Path)) {
    Write-Host "❌ 오류: device2 디렉토리가 없습니다!" -ForegroundColor Red
    exit 1
}

Set-Location $device2Path

# 가상환경 확인
if (-not (Test-Path "venv")) {
    Write-Host "❌ 오류: 가상환경이 없습니다!" -ForegroundColor Red
    Write-Host "먼저 setup_device2.ps1을 실행하세요." -ForegroundColor Yellow
    exit 1
}

# 디렉토리 생성
New-Item -ItemType Directory -Force -Path logs, pids, models | Out-Null

# ML 모델 확인
Write-Host "[사전 체크] ML 모델 파일 확인..." -ForegroundColor Yellow
if (-not (Test-Path "models\random_forest_model.joblib")) {
    Write-Host "❌ ML 모델 파일이 없습니다!" -ForegroundColor Red
    Write-Host "먼저 train_model.py를 실행하세요:" -ForegroundColor Yellow
    Write-Host "  python train_model.py" -ForegroundColor Cyan
    Write-Host ""
    $train = Read-Host "지금 훈련하시겠습니까? (y/N)"
    if ($train -eq "y" -or $train -eq "Y") {
        & ".\venv\Scripts\Activate.ps1"
        python train_model.py
        if ($LASTEXITCODE -ne 0) {
            Write-Host "훈련 실패!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "⚠ ML 모델 없이 계속합니다 (예측 불가)" -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ ML 모델 파일 존재" -ForegroundColor Green
}

# Ollama 확인
Write-Host "[사전 체크] Ollama 확인..." -ForegroundColor Yellow
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Ollama가 설치되지 않았습니다!" -ForegroundColor Red
    exit 1
}

$ollamaProcess = Get-Process ollama -ErrorAction SilentlyContinue
if (-not $ollamaProcess) {
    Write-Host "Ollama 시작 중..." -ForegroundColor Yellow
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

# Qwen 모델 확인
$models = ollama list 2>$null
if ($models -notmatch "qwen2.5:7b") {
    Write-Host "❌ Qwen 2.5 모델이 없습니다!" -ForegroundColor Red
    Write-Host "다운로드 중... (약 4.5GB)" -ForegroundColor Yellow
    ollama pull qwen2.5:7b
}

Write-Host "✓ Ollama 및 Qwen 2.5 준비 완료" -ForegroundColor Green

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "서비스 시작 중..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Flow Receiver 시작
Write-Host "[1/1] Flow Receiver 시작 (포트 5001)..." -ForegroundColor Green
Write-Host "       ⚡ 이것이 메인 자동 방어 시스템입니다!" -ForegroundColor Yellow

$logFile = Join-Path (Get-Location) "logs\flow_receiver.log"
$process = Start-Process -FilePath ".\venv\Scripts\python.exe" `
                        -ArgumentList "flow_receiver.py" `
                        -RedirectStandardOutput $logFile `
                        -RedirectStandardError "$logFile.err" `
                        -WindowStyle Hidden `
                        -PassThru

$process.Id | Out-File -FilePath "pids\flow_receiver.pid" -Encoding UTF8

Start-Sleep -Seconds 3

if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
    Write-Host "       ✓ 실행 중 (PID: $($process.Id))" -ForegroundColor Green
} else {
    Write-Host "       ✗ 시작 실패 - logs\flow_receiver.log 확인" -ForegroundColor Red
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ 장치 2 시작 완료!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "실행 중인 서비스:" -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -match "python|ollama"} | Select-Object Id, ProcessName, CPU | Format-Table
Write-Host ""
Write-Host "로그 확인 (실시간):" -ForegroundColor Yellow
Write-Host "  Get-Content logs\flow_receiver.log -Wait" -ForegroundColor Cyan
Write-Host ""
Write-Host "MCP Client 시작 (선택):" -ForegroundColor Yellow
Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor Cyan
Write-Host "  python qwen_mcp_client.py" -ForegroundColor Cyan
Write-Host ""
Write-Host "서비스 중지:" -ForegroundColor Yellow
Write-Host "  ..\scripts\stop_device2.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  주의: 장치 1도 시작해야 시스템이 작동합니다!" -ForegroundColor Yellow
Write-Host ""