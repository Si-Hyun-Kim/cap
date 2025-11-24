# setup_device2.ps1 - Windows 11 장치 2 설치
# 버그 수정 버전

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "장치 2 (Windows 11) 설치 스크립트" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 현재 IP 확인
try {
    $currentIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).IPAddress | Select-Object -First 1
    Write-Host "현재 장치 IP: $currentIP" -ForegroundColor Yellow
    Write-Host "예상 IP: 192.168.0.14" -ForegroundColor Yellow
    Write-Host ""
} catch {
    Write-Host "IP 주소를 가져올 수 없습니다." -ForegroundColor Yellow
    $currentIP = "Unknown"
}

if ($currentIP -ne "192.168.0.14") {
    Write-Host "IP 주소가 예상과 다릅니다." -ForegroundColor Yellow
    Write-Host "config.json에서 IP를 수정해야 합니다." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "계속하시겠습니까? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "설치 취소" -ForegroundColor Red
        exit 1
    }
}

# 프로젝트 루트 확인
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

Write-Host "프로젝트 루트: $projectRoot" -ForegroundColor Cyan
Write-Host ""

# device2 디렉토리 확인
$device2Path = Join-Path $projectRoot "device2"
if (-not (Test-Path $device2Path)) {
    Write-Host "device2 디렉토리가 없습니다!" -ForegroundColor Red
    Write-Host "현재 위치: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

Set-Location $device2Path

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "설치 시작" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 1. Python 확인
Write-Host "[1/7] Python 환경 확인 중..." -ForegroundColor Yellow
if (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonVersion = python --version 2>&1
    Write-Host "Python 설치됨: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "Python이 설치되지 않았습니다!" -ForegroundColor Red
    Write-Host "https://www.python.org/downloads/ 에서 설치하세요" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 2. pip 확인
Write-Host "[2/7] pip 확인 중..." -ForegroundColor Yellow
if (Get-Command pip -ErrorAction SilentlyContinue) {
    Write-Host "pip 설치됨" -ForegroundColor Green
} else {
    Write-Host "pip이 설치되지 않았습니다!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 3. Ollama 확인
Write-Host "[3/7] Ollama 확인 중..." -ForegroundColor Yellow
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Write-Host "Ollama 이미 설치됨" -ForegroundColor Green
} else {
    Write-Host "Ollama가 설치되지 않았습니다!" -ForegroundColor Red
    Write-Host "https://ollama.com/download/windows 에서 설치하세요" -ForegroundColor Yellow
    Write-Host ""
    $download = Read-Host "다운로드 페이지를 여시겠습니까? (y/N)"
    if ($download -eq "y" -or $download -eq "Y") {
        Start-Process "https://ollama.com/download/windows"
    }
    exit 1
}
Write-Host ""

# 4. 가상환경 생성
Write-Host "[4/7] Python 가상환경 생성 중..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "가상환경 이미 존재" -ForegroundColor Green
} else {
    python -m venv venv
    Write-Host "가상환경 생성 완료" -ForegroundColor Green
}
Write-Host ""

# 5. 패키지 설치
Write-Host "[5/7] Python 패키지 설치 중..." -ForegroundColor Yellow
& ".\venv\Scripts\python.exe" -m pip install --upgrade pip --quiet
& ".\venv\Scripts\pip.exe" install -r requirements.txt --quiet
Write-Host "패키지 설치 완료" -ForegroundColor Green
Write-Host ""

# 설치된 주요 패키지 확인
Write-Host "   주요 패키지:" -ForegroundColor Cyan
$packages = & ".\venv\Scripts\pip.exe" list
$packages | Select-String "scikit-learn|joblib|flask|openai|mcp" | ForEach-Object {
    Write-Host "   $($_)" -ForegroundColor Green
}
Write-Host ""

# 6. Qwen 모델 다운로드
Write-Host "[6/7] Qwen 2.5 모델 확인 중..." -ForegroundColor Yellow
$modelsList = ollama list 2>&1 | Out-String
if ($modelsList -match "qwen2.5:7b") {
    Write-Host "Qwen 2.5 이미 다운로드됨" -ForegroundColor Green
} else {
    Write-Host "Qwen 2.5 다운로드 중... (약 4.5GB, 시간 소요)" -ForegroundColor Yellow
    Write-Host "커피 한 잔 하세요..." -ForegroundColor Yellow
    ollama pull qwen2.5:7b
    Write-Host "Qwen 2.5 다운로드 완료" -ForegroundColor Green
}
Write-Host ""

# 7. 디렉토리 생성
Write-Host "[7/7] 디렉토리 생성 중..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path models, logs, pids, data | Out-Null
Write-Host "models, logs, pids, data 디렉토리 생성" -ForegroundColor Green
Write-Host ""

# config.json 생성
if (-not (Test-Path "config.json")) {
    Write-Host "config.json 생성 중..." -ForegroundColor Yellow
    
    $configContent = @"
{
  "device_id": "device2",
  "device_name": "LLM 서버 (Windows 11)",
  "ip_address": "$currentIP",
  "ml_models": {
    "model_path": "models\\random_forest_model.joblib",
    "scaler_path": "models\\min_max_scaler.joblib",
    "encoder_path": "models\\label_encoder.joblib",
    "features_path": "models\\feature_names.joblib"
  },
  "ollama": {
    "base_url": "http://localhost:11434",
    "api_url": "http://localhost:11434/api/generate",
    "model": "qwen2.5:7b",
    "timeout": 30,
    "temperature": 0.1
  },
  "device1": {
    "api_url": "http://192.168.0.42:8000",
    "rule_client_url": "http://192.168.0.42:10002"
  },
  "flow_receiver": {
    "host": "0.0.0.0",
    "port": 5001
  },
  "rules": {
    "starting_sid": 900000001,
    "confidence_threshold": 0.7
  }
}
"@
    
    $configContent | Out-File -FilePath "config.json" -Encoding UTF8
    Write-Host "config.json 생성 완료" -ForegroundColor Green
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "장치 2 (Windows 11) 설치 완료!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "ML 모델 파일이 필요합니다!" -ForegroundColor Yellow
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. ML 모델 훈련 (CICIDS2017 데이터셋 필요):" -ForegroundColor Yellow
Write-Host "   cd $device2Path" -ForegroundColor White
Write-Host "   .\venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host "   python train_model.py" -ForegroundColor White
Write-Host ""
Write-Host "2. 또는 이미 훈련된 모델이 있다면:" -ForegroundColor Yellow
Write-Host "   models 디렉토리에 *.joblib 파일 복사" -ForegroundColor White
Write-Host ""
Write-Host "3. 서비스 시작:" -ForegroundColor Yellow
Write-Host "   cd $projectRoot" -ForegroundColor White
Write-Host "   .\scripts\start_device2.ps1" -ForegroundColor White
Write-Host ""
Write-Host "4. 연결 테스트:" -ForegroundColor Yellow
Write-Host "   .\scripts\check_connection.ps1" -ForegroundColor White
Write-Host ""
Write-Host "장치 1 (192.168.0.42)도 시작해야 합니다!" -ForegroundColor Yellow
Write-Host ""