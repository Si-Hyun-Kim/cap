#!/bin/bash
# setup_device2.sh - 장치 2 (LLM 서버) 자동 설치
# 이 스크립트는 장치 2 (192.168.0.14)에서만 실행하세요!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}🧠 장치 2 (LLM 서버) 설치 스크립트${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# 현재 IP 확인
CURRENT_IP=$(hostname -I | awk '{print $1}')
echo -e "${YELLOW}현재 장치 IP: ${CURRENT_IP}${NC}"
echo -e "${YELLOW}예상 IP: 192.168.0.14${NC}"
echo ""

if [[ "$CURRENT_IP" != "192.168.0.14"* ]]; then
    echo -e "${YELLOW}⚠️  IP 주소가 예상과 다릅니다.${NC}"
    echo -e "${YELLOW}   이 스크립트는 장치 2 (192.168.0.14)에서 실행해야 합니다.${NC}"
    echo ""
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}설치 취소${NC}"
        exit 1
    fi
fi

# 프로젝트 루트 확인
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo -e "${CYAN}프로젝트 루트: ${PROJECT_ROOT}${NC}"
echo ""

# device2 디렉토리 확인
if [ ! -d "$PROJECT_ROOT/device2" ]; then
    echo -e "${RED}❌ 오류: device2 디렉토리가 없습니다!${NC}"
    echo -e "${YELLOW}현재 위치: $(pwd)${NC}"
    exit 1
fi

cd "$PROJECT_ROOT/device2"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}설치 시작${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. 시스템 업데이트
echo -e "${YELLOW}[1/8] 시스템 업데이트 중...${NC}"
sudo apt update -qq
echo -e "${GREEN}✓ 완료${NC}"
echo ""

# 2. Python 환경
echo -e "${YELLOW}[2/8] Python 환경 확인 중...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}   Python 설치 중...${NC}"
    sudo apt install -y python3 python3-pip python3-venv
fi
PYTHON_VERSION=$(python3 --version)
echo -e "${GREEN}✓ ${PYTHON_VERSION}${NC}"
echo ""

# 3. Ollama 설치
echo -e "${YELLOW}[3/8] Ollama 확인 중...${NC}"
if ! command -v ollama &> /dev/null; then
    echo -e "${YELLOW}   Ollama 설치 중... (시간 소요)${NC}"
    curl -fsSL https://ollama.com/install.sh | sh
    echo -e "${GREEN}✓ Ollama 설치 완료${NC}"
else
    OLLAMA_VERSION=$(ollama --version 2>&1)
    echo -e "${GREEN}✓ Ollama 이미 설치됨 (${OLLAMA_VERSION})${NC}"
fi
echo ""

# 4. Qwen 2.5 모델 다운로드
echo -e "${YELLOW}[4/8] Qwen 2.5 모델 확인 중...${NC}"
if ! ollama list | grep -q "qwen2.5:7b"; then
    echo -e "${YELLOW}   Qwen 2.5 다운로드 중... (약 4.5GB, 시간 소요)${NC}"
    echo -e "${YELLOW}   ☕ 커피 한 잔 하세요...${NC}"
    ollama pull qwen2.5:7b
    echo -e "${GREEN}✓ Qwen 2.5 다운로드 완료${NC}"
else
    echo -e "${GREEN}✓ Qwen 2.5 이미 다운로드됨${NC}"
fi
echo ""

# 5. 가상환경 생성
echo -e "${YELLOW}[5/8] Python 가상환경 생성 중...${NC}"
if [ -d "venv" ]; then
    echo -e "${GREEN}✓ 가상환경 이미 존재${NC}"
else
    python3 -m venv venv
    echo -e "${GREEN}✓ 가상환경 생성 완료${NC}"
fi
echo ""

# 6. 패키지 설치
echo -e "${YELLOW}[6/8] Python 패키지 설치 중...${NC}"
source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo -e "${GREEN}✓ 패키지 설치 완료${NC}"

# 설치된 패키지 확인
echo -e "${CYAN}   주요 패키지:${NC}"
pip list | grep -E "scikit-learn|joblib|flask|openai|mcp" | while read line; do
    echo -e "   ${GREEN}•${NC} $line"
done
echo ""

# 7. 디렉토리 생성
echo -e "${YELLOW}[7/8] 디렉토리 생성 중...${NC}"
mkdir -p models logs pids data
echo -e "${GREEN}✓ models/, logs/, pids/, data/ 디렉토리 생성${NC}"
echo ""

# 8. config.json 생성
echo -e "${YELLOW}[8/8] 설정 파일 생성 중...${NC}"
if [ ! -f "config.json" ]; then
    cat > config.json << 'EOF'
{
  "device_id": "device2",
  "device_name": "LLM 서버",
  "ip_address": "192.168.0.14",
  
  "ml_models": {
    "model_path": "models/random_forest_model.joblib",
    "scaler_path": "models/min_max_scaler.joblib",
    "encoder_path": "models/label_encoder.joblib",
    "features_path": "models/feature_names.joblib"
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
EOF
    echo -e "${GREEN}✓ config.json 생성 완료${NC}"
else
    echo -e "${GREEN}✓ config.json 이미 존재${NC}"
fi
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 장치 2 설치 완료!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}⚠️  중요: ML 모델 파일이 필요합니다!${NC}"
echo ""
echo -e "${CYAN}다음 단계:${NC}"
echo ""
echo -e "${YELLOW}1. ML 모델 훈련 (CICIDS2017 데이터셋 필요):${NC}"
echo -e "   cd $PROJECT_ROOT/device2"
echo -e "   source venv/bin/activate"
echo -e "   python train_model.py"
echo ""
echo -e "${YELLOW}2. 또는 이미 훈련된 모델이 있다면:${NC}"
echo -e "   models/ 디렉토리에 *.joblib 파일 복사"
echo ""
echo -e "${YELLOW}3. 서비스 시작:${NC}"
echo -e "   cd $PROJECT_ROOT"
echo -e "   ./scripts/start_device2.sh"
echo ""
echo -e "${YELLOW}4. 연결 테스트:${NC}"
echo -e "   ./scripts/check_connection.sh"
echo ""
echo -e "${YELLOW}⚠️  중요: 장치 1 (192.168.0.42)도 설정해야 합니다!${NC}"
echo ""