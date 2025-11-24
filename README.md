# 🛡️ AI 기반 네트워크 자동 방어 시스템

**Qwen 2.5 LLM + Random Forest ML + 실시간 웹 대시보드**

실시간 침입 탐지 및 자동 차단 시스템 with SIEM 스타일 대시보드

[![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://www.python.org/)
[![Suricata](https://img.shields.io/badge/Suricata-7.0+-orange.svg)](https://suricata.io/)
[![Ollama](https://img.shields.io/badge/Ollama-Qwen_2.5-green.svg)](https://ollama.com/)
[![Flask](https://img.shields.io/badge/Flask-3.0-red.svg)](https://flask.palletsprojects.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🎯 프로젝트 개요

**2개 장치 + 웹 대시보드**로 구성된 차세대 AI 기반 네트워크 자동 방어 시스템

### 핵심 개념
```
┌─────────────────────────────────────────────────────┐
│  장치 1 (Ubuntu/Linux)                              │
│  - Suricata IDS/IPS                                │
│  - 실시간 웹 대시보드 (Flask) 🎨                   │
│  - IP: 192.168.0.42                                │
└─────────────────────────────────────────────────────┘
                      ↕️ HTTP/TCP
┌─────────────────────────────────────────────────────┐
│  장치 2 (Windows 11)                                │
│  - AI 분석 (Random Forest + Qwen 2.5)             │
│  - 자동 룰 생성                                     │
│  - IP: 192.168.0.14                                │
└─────────────────────────────────────────────────────┘
```

### 작동 원리
```
[1] 공격 발생
    ↓
[2] 장치 1: Suricata 감지 → Flow 추출 (13개 Feature)
    ↓ HTTP (0.5초)
[3] 장치 2: ML 예측 (Random Forest, 0.01초)
    ↓ 악성 탐지 시
[4] 장치 2: LLM 룰 생성 (Qwen 2.5, 1.5초)
    ↓ TCP
[5] 장치 1: Suricata 적용 → 차단 완료!
    ↓
[6] 대시보드: 실시간 알림 표시 🎨

⏱️ 총 소요 시간: 약 2.5초
```

### 차별점

✅ **SIEM 스타일 웹 대시보드** - 실시간 모니터링 + 차트  
✅ **완전 자동화** - 사람 개입 없이 공격 탐지부터 차단까지  
✅ **이중 AI 구조** - ML(빠른 탐지) + LLM(정교한 룰 생성)  
✅ **한국어 지원** - Qwen 2.5의 다국어 능력  
✅ **Zero Cost** - 로컬 Ollama 사용, API 비용 없음  
✅ **원클릭 차단** - 대시보드에서 IP 즉시 차단  

---

### 데이터 흐름 (6단계)

| 시간 | 장치 | 동작 | 설명 |
|------|------|------|------|
| T+0초 | - | 🔴 공격 시작 | 네트워크 공격 발생 |
| T+0.1초 | 장치 1 | 🛡️ Suricata 탐지 | eve.json에 기록 |
| T+0.2초 | 장치 1 | 📊 Flow 추출 | 13개 Feature 추출 |
| T+0.5초 | 장치 1→2 | 📡 HTTP 전송 | Flow 데이터 전송 |
| T+0.51초 | 장치 2 | 🤖 ML 예측 | Random Forest 분석 |
| T+2초 | 장치 2 | 🧠 LLM 룰 생성 | Qwen 2.5 Suricata 룰 작성 |
| T+2.1초 | 장치 2→1 | 📡 TCP 전송 | 생성된 룰 전달 |
| T+2.5초 | 장치 1 | ✅ 룰 적용 | Suricata에 즉시 적용 |
| **실시간** | **장치 1** | **🎨 대시보드 갱신** | **웹 UI 자동 업데이트** |


---

## 💻 시스템 요구사항

### 장치 1 (Suricata 서버)

| 항목 | 요구사항 | 권장 |
|------|---------|------|
| **OS** | Ubuntu 20.04+ | Ubuntu 22.04 LTS |
| **CPU** | 2 Core | 4 Core |
| **RAM** | 4GB | 8GB |
| **Disk** | 20GB | 50GB |
| **Network** | 1Gbps | 10Gbps |
| **Software** | Suricata 6.0+, Python 3.8+ | Suricata 7.0+, Python 3.10+ |

### 장치 2 (LLM 서버)

| 항목 | 요구사항 | 권장 |
|------|---------|------|
| **OS** | Windows 11 | Windows 11 Pro |
| **CPU** | 4 Core | 8 Core (i7/Ryzen 7) |
| **RAM** | 16GB | 32GB |
| **Disk** | 50GB SSD | 100GB NVMe SSD |
| **GPU** | 선택 (CPU 가능) | NVIDIA RTX 3060+ |
| **Network** | 1Gbps | 10Gbps |
| **Software** | Python 3.10+, Ollama | Python 3.11+, Ollama, CUDA |

### 네트워크 요구사항

- **지연시간**: < 10ms (장치 간)
- **대역폭**: 최소 100Mbps
- **포트**:
  - 장치 1: 8000 (API), 8080 (대시보드), 10001 (Relay), 10002 (Rule Client)
  - 장치 2: 5001 (Flow Receiver), 11434 (Ollama)

## 🚀 빠른 시작

### 장치 1 (Ubuntu) - 10분
```bash
# 1. 프로젝트 클론
git clone https://github.com/your-repo/AI_Network_Defense_System.git
cd AI_Network_Defense_System

# 2. 실행 권한
chmod +x scripts/*.sh

# 3. 설치
./scripts/setup_device1.sh

# 4. 대시보드 파일 배치 (수동)
# dashboard/ 디렉토리에 HTML, CSS, JS 파일 복사

# 5. 시작
./scripts/start_device1.sh

# 6. 접속
# 브라우저: http://192.168.0.42:8080
# 로그인: admin / admin
```

### 장치 2 (Windows 11) - 15분
```powershell
# PowerShell 관리자 권한으로 실행

# 1. 프로젝트 다운로드
cd C:\Users\YourName\Documents
git clone https://github.com/your-repo/AI_Network_Defense_System.git
cd AI_Network_Defense_System

# 2. 실행 정책 설정 (최초 1회)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 3. 설치
.\scripts\setup_device2.ps1

# 4. ML 모델 훈련 (CICIDS2017 필요, 20-30분)
cd device2
.\venv\Scripts\Activate.ps1
python train_model.py

# 5. 시작
cd ..
.\scripts\start_device2.ps1
```

### 연결 테스트
```bash
# 장치 1에서
./scripts/check_connection.sh

# 장치 2에서 (PowerShell)
.\scripts\check_connection.ps1
```

---

## 📖 상세 설치 가이드

### 장치 1 (Ubuntu) - 상세

#### 1단계: Suricata 설치
```bash
# Suricata 저장소 추가
sudo add-apt-repository ppa:oisf/suricata-stable
sudo apt update

# Suricata 설치
sudo apt install -y suricata

# 버전 확인
suricata --version
# Suricata 7.0.x

# 자동 시작 설정
sudo systemctl enable suricata
sudo systemctl start suricata
```

#### 2단계: 프로젝트 설치
```bash
# 프로젝트 클론
git clone 
cd AI_Network_Defense_System

# 설치 스크립트 실행
chmod +x scripts/setup_device1.sh
./scripts/setup_device1.sh
```

**자동 수행 작업**:
- ✅ Python 3.10+ 확인/설치
- ✅ 가상환경 생성
- ✅ 패키지 설치 (Flask, flask-login, requests 등)
- ✅ Suricata 로그 권한 설정
- ✅ 디렉토리 생성 (logs, pids, dashboard)
- ✅ config.json 생성

#### 3단계: 추가 패키지 설치
```bash
cd device1
source venv/bin/activate
pip install flask-login
deactivate
```

#### 4단계: Suricata 권한 설정
```bash
# eve.json 읽기 권한
sudo chmod 644 /var/log/suricata/eve.json
sudo chmod 755 /var/log/suricata

# 사용자를 adm 그룹에 추가
sudo usermod -a -G adm $USER
newgrp adm
```

#### 5단계: 서비스 시작
```bash
./scripts/start_device1.sh
```

**시작되는 서비스 (5개)**:
1. `device1_api.py` (포트 8000) - API 서버
2. `dashboard/app.py` (포트 8080) - 🆕 웹 대시보드
3. `suricata_tcp_relay.py` (포트 10001) - Unix Socket 중계
4. `rule_command_client.py` (포트 10002) - 룰 수신
5. `flow_extractor.py` - 실시간 로그 전송


---

### 장치 2 (Windows 11) - 상세

#### 1단계: Python 설치
```powershell
# winget 사용
winget install Python.Python.3.11

# 확인
python --version
pip --version
```

#### 2단계: Ollama 설치
```powershell
# 다운로드: https://ollama.com/download/windows
# OllamaSetup.exe 실행

# 확인
ollama --version
```

#### 3단계: 프로젝트 설치
```powershell
cd C:\Users\YourName\Documents
git clone 
cd AI_Network_Defense_System

# 실행 정책
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 설치
.\scripts\setup_device2.ps1
```

##### 만약 setup_device2.ps1에 오류가 생긴다면, 수동으로 설치
###### 1. Python 확인

```shell
python --version
# 없으면: https://www.python.org/downloads/ 에서 설치
```

###### 2. Ollama 확인

```shell
ollama --version
# 없으면: https://ollama.com/download/windows 에서 설치
```

###### 3. device2로 이동

```shell
cd device2
```
###### 4. 가상환경 생성

```shell
python -m venv venv
```

###### 5. 가상환경 활성화

```shell
.\venv\Scripts\Activate.ps1
```

###### 6. pip 업그레이드

```shell
python -m pip install --upgrade pip
```

###### 7. 패키지 설치

```shell
pip install flask scikit-learn joblib numpy pandas mcp openai requests python-json-logger
```

###### 8. Qwen 2.5 다운로드

```shell
ollama pull qwen2.5:7b
```

###### 9. 디렉토리 생성

```shell
mkdir models
mkdir logs
mkdir pids
mkdir data
```

###### 10. config.json 생성

```shell
notepad config.json
```

📄 config.json 내용 (수동 생성)

```json
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
    "model": "qwen2.5:7b",
    "timeout": 30
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
```

#### 4단계: CICIDS2017 데이터셋 준비
```powershell
# 다운로드: https://www.unb.ca/cic/datasets/ids-2017.html
# 압축 해제 후 device2\data\ 폴더에 복사

# 필요한 8개 CSV 파일:
# - Friday-WorkingHours-Afternoon-DDos.pcap_ISCX.csv
# - Friday-WorkingHours-Afternoon-PortScan.pcap_ISCX.csv
# - Friday-WorkingHours-Morning.pcap_ISCX.csv
# - Monday-WorkingHours.pcap_ISCX.csv
# - Thursday-WorkingHours-Afternoon-Infilteration.pcap_ISCX.csv
# - Thursday-WorkingHours-Morning-WebAttacks.pcap_ISCX.csv
# - Tuesday-WorkingHours.pcap_ISCX.csv
# - Wednesday-workingHours.pcap_ISCX.csv
```

#### 5단계: ML 모델 훈련
```powershell
cd device2
.\venv\Scripts\Activate.ps1
python train_model.py

# 출력: (20-30분 소요)
# 정확도: 0.9987 (99.87%)
# 4개 파일 생성:
# - models\random_forest_model.joblib
# - models\min_max_scaler.joblib
# - models\label_encoder.joblib
# - models\feature_names.joblib
```

#### 6단계: 방화벽 설정
```powershell
# PowerShell 관리자 권한
New-NetFirewallRule -DisplayName "Flow Receiver" -Direction Inbound -LocalPort 5001 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Ollama API" -Direction Inbound -LocalPort 11434 -Protocol TCP -Action Allow
```

#### 7단계: 서비스 시작
```powershell
cd C:\Users\YourName\Documents\AI_Network_Defense_System
.\scripts\start_device2.ps1
```

---

## 🎨 웹 대시보드 사용법

### 접속
```
URL: http://192.168.0.42:8080
Username: admin
Password: admin
```


## 📂 프로젝트 구조

본 프로젝트는 **2개 장치**로 구성되어 있으며, 각 장치는 **독립적으로 설치 및 실행**됩니다.

---

### 🛡️ 장치 1 (Ubuntu/Linux) - Suricata 서버

**위치**: `~/AI_Network_Defense_System/`  
**IP**: 192.168.0.42  
**역할**: 침입 탐지, 웹 대시보드, 룰 적용

```
AI_Network_Defense_System/           # 프로젝트 루트
│
├── device1/                          # 🛡️ 장치 1 전용 디렉토리
│   │
│   ├── device1_api.py                # Flask API 서버
│   │   ├─ 포트: 8000
│   │   ├─ 역할: REST API 제공
│   │   └─ 기능: 로그 조회, 통계, 룰 관리
│   │
│   ├── flow_extractor.py             # 실시간 로그 전송
│   │   ├─ 입력: /var/log/suricata/eve.json
│   │   ├─ 출력: 장치 2 (HTTP POST)
│   │   └─ 기능: 13개 Feature 추출
│   │
│   ├── rule_command_client.py        # 룰 수신 서버
│   │   ├─ 포트: 10002 (TCP)
│   │   ├─ 입력: 장치 2에서 생성된 룰
│   │   └─ 기능: Suricata에 룰 적용
│   │
│   ├── suricata_tcp_relay.py         # Unix Socket 중계
│   │   ├─ 포트: 10001 (TCP)
│   │   ├─ 연결: /var/run/suricata/suricata-command.socket
│   │   └─ 기능: Suricata 명령 실행
│   │
│   ├── requirements.txt              # Python 패키지 목록
│   │   ├─ flask==3.0.0
│   │   ├─ flask-login==0.6.3
│   │   ├─ flask-cors==4.0.0
│   │   ├─ requests==2.31.0
│   │   └─ python-json-logger==2.0.7
│   │
│   ├── config.json                   # 장치 1 설정 파일
│   │   ├─ IP: 192.168.0.42
│   │   ├─ Suricata 경로
│   │   ├─ 장치 2 URL
│   │   └─ 서비스 포트
│   │
│   ├── venv/                         # Python 가상환경
│   │   └─ (pip install -r requirements.txt)
│   │
│   ├── logs/                         # 로그 파일 (자동 생성)
│   │   ├── api.log                   # API 서버 로그
│   │   ├── dashboard.log             # 대시보드 로그
│   │   ├── flow_extractor.log        # Flow 추출 로그
│   │   ├── rule_client.log           # 룰 수신 로그
│   │   └── relay.log                 # Unix Socket 중계 로그
│   │
│   ├── pids/                         # 프로세스 ID (자동 생성)
│   │   ├── api.pid
│   │   ├── dashboard.pid
│   │   ├── flow_extractor.pid
│   │   ├── rule_client.pid
│   │   └── relay.pid
│   │
│   └── dashboard/                    # 🎨 웹 대시보드
│       │
│       ├── app.py                    # Flask 대시보드 서버
│       │   ├─ 포트: 8080
│       │   ├─ 기능: 로그인, 통계, 차트, IP 차단
│       │   └─ 프록시: device1_api.py로 API 요청 전달
│       │
│       ├── templates/                # HTML 템플릿
│       │   ├── index.html            # 메인 대시보드 (SPA)
│       │   │   ├─ Overview: 통계 카드, 차트
│       │   │   ├─ Alerts: 로그 테이블
│       │   │   ├─ Rules: 룰 관리
│       │   │   ├─ Reports: 보고서 생성
│       │   │   └─ Settings: 설정
│       │   │
│       │   ├── login.html            # 로그인 페이지
│       │   │   ├─ Username/Password
│       │   │   └─ MFA 지원 (비활성화)
│       │   │
│       │   ├── 404.html              # 404 에러 페이지
│       │   └── 500.html              # 500 에러 페이지
│       │
│       ├── static/                   # 정적 파일
│       │   │
│       │   ├── css/
│       │   │   └── styles.css        # SIEM 스타일 CSS
│       │   │       ├─ 다크/라이트 테마
│       │   │       ├─ 반응형 디자인
│       │   │       └─ Chart.js 스타일
│       │   │
│       │   └── js/
│       │       └── script.js         # 프론트엔드 로직
│       │           ├─ Chart.js (라인/파이 차트)
│       │           ├─ API 호출 (Fetch)
│       │           ├─ 실시간 업데이트
│       │           └─ 이벤트 핸들러
│       │
│       └── generated_reports/        # 생성된 보고서 (자동 생성)
│           ├── report_2025-01-25.pdf
│           └── report_2025-01-24.html
│
└── scripts/                          # 🔧 장치 1 스크립트
    ├── setup_device1.sh              # 설치 스크립트 (Bash)
    │   ├─ Suricata 설치
    │   ├─ Python 환경 설정
    │   ├─ 패키지 설치
    │   ├─ 권한 설정
    │   └─ 대시보드 파일 복사
    │
    ├── start_device1.sh              # 시작 스크립트 (Bash)
    │   ├─ 5개 서비스 시작:
    │   │   1. device1_api.py (포트 8000)
    │   │   2. dashboard/app.py (포트 8080)
    │   │   3. suricata_tcp_relay.py (포트 10001)
    │   │   4. rule_command_client.py (포트 10002)
    │   │   5. flow_extractor.py
    │   └─ PID 파일 생성
    │
    └── stop_device1.sh               # 중지 스크립트 (Bash)
        └─ 모든 서비스 종료
```

**총 코드 라인**: ~2,500줄  
**디스크 사용량**: ~500MB (venv 포함)

### 🧠 장치 2 (Windows 11) - LLM 서버

**위치**: `C:\Users\YourName\Documents\AI_Network_Defense_System\`  
**IP**: 192.168.0.14  
**역할**: AI 분석, 자동 룰 생성
```
AI_Network_Defense_System\           # 프로젝트 루트
│
├── device2\                          # 🧠 장치 2 전용 디렉토리
│   │
│   ├── flow_receiver.py              # ⭐ 메인 자동 방어 시스템
│   │   ├─ 포트: 5001 (Flask)
│   │   ├─ 입력: 장치 1의 Flow 데이터 (13개 Feature)
│   │   ├─ ML 예측: Random Forest (0.01초)
│   │   ├─ LLM 룰 생성: Ollama + Qwen 2.5 (1.5초)
│   │   ├─ 출력: 장치 1 (TCP 10002)
│   │   └─ 기능: 자동 방어 전체 프로세스
│   │
│   ├── qwen_mcp_client.py            # MCP Client (모니터링)
│   │   ├─ 역할: LLM 기반 자동 모니터링
│   │   ├─ 주기: 10초마다 실행
│   │   ├─ 기능: 로그 분석 → 룰 생성 → 적용
│   │   └─ 출력: 한국어 보고서
│   │
│   ├── mcp_server.py                 # MCP Server (도구 제공)
│   │   ├─ 프로토콜: Model Context Protocol
│   │   ├─ 통신: stdio
│   │   └─ 4개 도구:
│   │       1. get_suricata_logs(count)
│   │       2. analyze_network_flow(flow_data)
│   │       3. generate_suricata_rule(...)
│   │       4. apply_rule_to_suricata(rule, sid)
│   │
│   ├── train_model.py                # ML 모델 훈련
│   │   ├─ 입력: CICIDS2017 데이터셋 (CSV)
│   │   ├─ 알고리즘: Random Forest
│   │   ├─ Feature: 77개
│   │   ├─ 클래스: 13개 (공격 유형)
│   │   ├─ 훈련 시간: 20-30분
│   │   ├─ 정확도: 99.87%
│   │   └─ 출력: 4개 joblib 파일
│   │
│   ├── requirements.txt              # Python 패키지 목록
│   │   ├─ flask==3.0.0
│   │   ├─ scikit-learn==1.3.2
│   │   ├─ joblib==1.3.2
│   │   ├─ numpy==1.24.3
│   │   ├─ pandas==2.1.4
│   │   ├─ mcp==1.1.2
│   │   ├─ openai==1.12.0
│   │   ├─ requests==2.31.0
│   │   └─ python-json-logger==2.0.7
│   │
│   ├── config.json                   # 장치 2 설정 파일
│   │   ├─ IP: 192.168.0.14
│   │   ├─ Ollama 설정
│   │   ├─ ML 모델 경로
│   │   ├─ 장치 1 URL
│   │   └─ 룰 생성 설정
│   │
│   ├── venv\                         # Python 가상환경
│   │   └─ (pip install -r requirements.txt)
│   │
│   ├── models\                       # ML 모델 파일 (훈련 후 생성)
│   │   ├── random_forest_model.joblib     # Random Forest 모델
│   │   │   ├─ 크기: ~20MB
│   │   │   ├─ 알고리즘: RandomForestClassifier
│   │   │   ├─ n_estimators: 100
│   │   │   └─ max_depth: 10
│   │   │
│   │   ├── min_max_scaler.joblib          # Feature Scaler
│   │   │   ├─ 크기: ~5MB
│   │   │   └─ 범위: [0, 1]
│   │   │
│   │   ├── label_encoder.joblib           # Label Encoder
│   │   │   ├─ 크기: ~1MB
│   │   │   └─ 클래스: 13개
│   │   │
│   │   └── feature_names.joblib           # Feature 이름
│   │       ├─ 크기: ~1KB
│   │       └─ 개수: 77개
│   │
│   ├── data\                         # CICIDS2017 데이터셋 (수동 다운로드)
│   │   ├── Friday-WorkingHours-Afternoon-DDos.pcap_ISCX.csv
│   │   │   └─ 크기: ~1.2GB
│   │   ├── Friday-WorkingHours-Afternoon-PortScan.pcap_ISCX.csv
│   │   │   └─ 크기: ~900MB
│   │   ├── Friday-WorkingHours-Morning.pcap_ISCX.csv
│   │   │   └─ 크기: ~850MB
│   │   ├── Monday-WorkingHours.pcap_ISCX.csv
│   │   │   └─ 크기: ~1.1GB
│   │   ├── Thursday-WorkingHours-Afternoon-Infilteration.pcap_ISCX.csv
│   │   │   └─ 크기: ~800MB
│   │   ├── Thursday-WorkingHours-Morning-WebAttacks.pcap_ISCX.csv
│   │   │   └─ 크기: ~750MB
│   │   ├── Tuesday-WorkingHours.pcap_ISCX.csv
│   │   │   └─ 크기: ~1GB
│   │   └── Wednesday-workingHours.pcap_ISCX.csv
│   │       └─ 크기: ~950MB
│   │   
│   │   총 크기: ~7GB
│   │   총 행 수: 2,830,743개
│   │   다운로드: https://www.unb.ca/cic/datasets/ids-2017.html
│   │
│   ├── logs\                         # 로그 파일 (자동 생성)
│   │   ├── flow_receiver.log         # Flow 수신 로그
│   │   ├── qwen_mcp_client.log       # MCP Client 로그
│   │   └── train_model.log           # 훈련 로그
│   │
│   └── pids\                         # 프로세스 ID (자동 생성)
│       └── flow_receiver.pid
│
├── scripts\                          # 🔧 장치 2 스크립트
│   ├── setup_device2.ps1             # 설치 스크립트 (PowerShell)
│   │   ├─ Python 설치 확인
│   │   ├─ Ollama 설치 확인
│   │   ├─ 가상환경 생성
│   │   ├─ 패키지 설치
│   │   ├─ Qwen 2.5 다운로드 (4.5GB)
│   │   └─ config.json 생성
│   │
│   ├── start_device2.ps1             # 시작 스크립트 (PowerShell)
│   │   ├─ Ollama 시작 (백그라운드)
│   │   ├─ Qwen 2.5 확인
│   │   ├─ ML 모델 확인
│   │   ├─ flow_receiver.py 시작
│   │   └─ PID 파일 생성
│   │
│   └── stop_device2.ps1              # 중지 스크립트 (PowerShell)
│       ├─ flow_receiver.py 종료
│       └─ Ollama 종료 (선택)
│
└── Ollama\                           # Ollama 설치 위치 (자동)
    └── models\
        └── qwen2.5_7b\               # Qwen 2.5 모델
            ├─ 크기: ~4.5GB
            ├─ 파라미터: 7B
            ├─ 토큰: 32K context
            └─ 기능: Suricata 룰 생성
```

**총 파일 수**: 30개 (데이터셋 포함)  
**총 코드 라인**: ~2,800줄  
**디스크 사용량**: ~13GB (Ollama 4.5GB + CICIDS2017 7GB + 기타)