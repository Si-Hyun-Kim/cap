# setup_device2_minimal.ps1
# 최소 버전 - 문법 오류 없음

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Device 2 Setup - Minimal Version" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 1. Python Check
Write-Host "[1/6] Checking Python..." -ForegroundColor Yellow
$pythonCheck = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCheck) {
    Write-Host "Python not found!" -ForegroundColor Red
    Write-Host "Install from: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}
$pythonVer = python --version
Write-Host "OK: $pythonVer" -ForegroundColor Green
Write-Host ""

# 2. Ollama Check
Write-Host "[2/6] Checking Ollama..." -ForegroundColor Yellow
$ollamaCheck = Get-Command ollama -ErrorAction SilentlyContinue
if (-not $ollamaCheck) {
    Write-Host "Ollama not found!" -ForegroundColor Red
    Write-Host "Install from: https://ollama.com/download/windows" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK: Ollama installed" -ForegroundColor Green
Write-Host ""

# 3. Navigate to device2
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$device2Dir = Join-Path $projectRoot "device2"

if (-not (Test-Path $device2Dir)) {
    Write-Host "ERROR: device2 folder not found!" -ForegroundColor Red
    exit 1
}

Set-Location $device2Dir
Write-Host "Working in: $device2Dir" -ForegroundColor Cyan
Write-Host ""

# 4. Create Virtual Environment
Write-Host "[3/6] Creating virtual environment..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "Virtual environment already exists" -ForegroundColor Green
} else {
    python -m venv venv
    Write-Host "Virtual environment created" -ForegroundColor Green
}
Write-Host ""

# 5. Install Packages
Write-Host "[4/6] Installing packages..." -ForegroundColor Yellow
& ".\venv\Scripts\python.exe" -m pip install --upgrade pip --quiet
& ".\venv\Scripts\pip.exe" install -r requirements.txt --quiet
Write-Host "Packages installed" -ForegroundColor Green
Write-Host ""

# 6. Pull Qwen Model
Write-Host "[5/6] Checking Qwen 2.5 model..." -ForegroundColor Yellow
$models = ollama list 2>&1
$modelsText = $models | Out-String
if ($modelsText -like "*qwen2.5:7b*") {
    Write-Host "Qwen 2.5 already downloaded" -ForegroundColor Green
} else {
    Write-Host "Downloading Qwen 2.5 (4.5GB)..." -ForegroundColor Yellow
    ollama pull qwen2.5:7b
    Write-Host "Qwen 2.5 downloaded" -ForegroundColor Green
}
Write-Host ""

# 7. Create Directories
Write-Host "[6/6] Creating directories..." -ForegroundColor Yellow
$dirs = @("models", "logs", "pids", "data")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Host "Directories created" -ForegroundColor Green
Write-Host ""

# 8. Create config.json
if (-not (Test-Path "config.json")) {
    Write-Host "Creating config.json..." -ForegroundColor Yellow
    
    $json = @'
{
  "device_id": "device2",
  "ip_address": "192.168.0.14",
  "ml_models": {
    "model_path": "models\\random_forest_model.joblib",
    "scaler_path": "models\\min_max_scaler.joblib",
    "encoder_path": "models\\label_encoder.joblib",
    "features_path": "models\\feature_names.joblib"
  },
  "ollama": {
    "base_url": "http://localhost:11434",
    "model": "qwen2.5:7b"
  },
  "device1": {
    "api_url": "http://192.168.0.42:8000",
    "rule_client_url": "http://192.168.0.42:10002"
  },
  "flow_receiver": {
    "host": "0.0.0.0",
    "port": 5001
  }
}
'@
    
    Set-Content -Path "config.json" -Value $json -Encoding UTF8
    Write-Host "config.json created" -ForegroundColor Green
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Train ML model: python train_model.py" -ForegroundColor Cyan
Write-Host "2. Start service: ..\scripts\start_device2.ps1" -ForegroundColor Cyan
Write-Host ""