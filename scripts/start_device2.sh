#!/bin/bash
# start_device2.sh - 장치 2에서만 실행!

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}🚀 장치 2 (LLM 서버) 시작${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# 현재 스크립트 위치에서 프로젝트 루트로 이동
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 장치 2 디렉토리 확인
if [ ! -d "$PROJECT_ROOT/device2" ]; then
    echo -e "${RED}❌ 오류: device2 디렉토리를 찾을 수 없습니다!${NC}"
    echo -e "${YELLOW}현재 위치: $(pwd)${NC}"
    exit 1
fi

cd "$PROJECT_ROOT/device2"

# 가상환경 확인
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ 오류: 가상환경이 없습니다!${NC}"
    echo -e "${YELLOW}먼저 setup_device2.sh를 실행하세요.${NC}"
    exit 1
fi

# 가상환경 활성화
source venv/bin/activate

# 디렉토리 생성
mkdir -p pids logs

# ML 모델 확인
echo -e "${YELLOW}[사전 체크] ML 모델 파일 확인...${NC}"
if [ ! -f "models/random_forest_model.joblib" ]; then
    echo -e "${RED}❌ ML 모델 파일이 없습니다!${NC}"
    echo -e "${YELLOW}먼저 train_model.py를 실행하세요:${NC}"
    echo -e "  ${CYAN}python train_model.py${NC}"
    echo ""
    read -p "지금 훈련하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        python train_model.py
        if [ $? -ne 0 ]; then
            echo -e "${RED}훈련 실패!${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠ ML 모델 없이 계속합니다 (예측 불가)${NC}"
    fi
else
    echo -e "${GREEN}✓ ML 모델 파일 존재${NC}"
fi

# Ollama 확인
echo -e "${YELLOW}[사전 체크] Ollama 확인...${NC}"
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}❌ Ollama가 설치되지 않았습니다!${NC}"
    exit 1
fi

if ! pgrep -x "ollama" > /dev/null; then
    echo -e "${YELLOW}Ollama 시작 중...${NC}"
    nohup ollama serve > logs/ollama.log 2>&1 &
    sleep 3
fi

# Qwen 모델 확인
if ! ollama list | grep -q "qwen2.5:7b"; then
    echo -e "${RED}❌ Qwen 2.5 모델이 없습니다!${NC}"
    echo -e "${YELLOW}다운로드 중... (약 4.5GB, 시간 소요)${NC}"
    ollama pull qwen2.5:7b
fi

echo -e "${GREEN}✓ Ollama 및 Qwen 2.5 준비 완료${NC}"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}서비스 시작 중...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Flow Receiver (포트 5001) - 메인!
echo -e "${GREEN}[1/1] Flow Receiver 시작 (포트 5001)...${NC}"
echo -e "       ${YELLOW}⚡ 이것이 메인 자동 방어 시스템입니다!${NC}"
nohup python flow_receiver.py > logs/flow_receiver.log 2>&1 &
FLOW_RCV_PID=$!
echo $FLOW_RCV_PID > pids/flow_receiver.pid
sleep 3

if ps -p $FLOW_RCV_PID > /dev/null; then
    echo -e "       ${GREEN}✓ 실행 중 (PID: $FLOW_RCV_PID)${NC}"
else
    echo -e "       ${RED}✗ 시작 실패 - logs/flow_receiver.log 확인${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 장치 2 시작 완료!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}실행 중인 서비스:${NC}"
ps aux | grep -E "ollama|flow_receiver" | grep -v grep
echo ""
echo -e "${YELLOW}로그 확인 (실시간):${NC}"
echo -e "  ${CYAN}tail -f logs/flow_receiver.log${NC}"
echo ""
echo -e "${YELLOW}MCP Client 시작 (선택):${NC}"
echo -e "  ${CYAN}python qwen_mcp_client.py${NC}"
echo ""
echo -e "${YELLOW}서비스 중지:${NC}"
echo -e "  ${CYAN}../scripts/stop_device2.sh${NC}"
echo ""
echo -e "${YELLOW}⚠️  주의: 장치 1도 시작해야 시스템이 작동합니다!${NC}"
echo ""