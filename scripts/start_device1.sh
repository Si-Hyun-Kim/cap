#!/bin/bash
# start_device1.sh - 장치 1에서만 실행!

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}🚀 장치 1 (Suricata 서버) 시작${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# 현재 스크립트 위치에서 프로젝트 루트로 이동
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 장치 1 디렉토리 확인
if [ ! -d "$PROJECT_ROOT/device1" ]; then
    echo -e "${RED}❌ 오류: device1 디렉토리를 찾을 수 없습니다!${NC}"
    echo -e "${YELLOW}현재 위치: $(pwd)${NC}"
    exit 1
fi

cd "$PROJECT_ROOT/device1"

# 가상환경 확인
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ 오류: 가상환경이 없습니다!${NC}"
    echo -e "${YELLOW}먼저 setup_device1.sh를 실행하세요.${NC}"
    exit 1
fi

# 가상환경 활성화
source venv/bin/activate

# 디렉토리 생성
mkdir -p pids logs

# Suricata 상태 확인
echo -e "${YELLOW}[사전 체크] Suricata 상태 확인...${NC}"
if systemctl is-active --quiet suricata; then
    echo -e "${GREEN}✓ Suricata 실행 중${NC}"
else
    echo -e "${RED}✗ Suricata가 실행되지 않습니다!${NC}"
    read -p "Suricata를 시작하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl start suricata
        sleep 3
        echo -e "${GREEN}✓ Suricata 시작됨${NC}"
    else
        echo -e "${YELLOW}⚠ Suricata 없이 계속합니다 (일부 기능 제한)${NC}"
    fi
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}서비스 시작 중...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. API 서버 (포트 8000)
echo -e "${GREEN}[1/4] API 서버 시작 (포트 8000)...${NC}"
nohup python device1_api.py > logs/api.log 2>&1 &
API_PID=$!
echo $API_PID > pids/api.pid
sleep 2

if ps -p $API_PID > /dev/null; then
    echo -e "       ${GREEN}✓ 실행 중 (PID: $API_PID)${NC}"
else
    echo -e "       ${RED}✗ 시작 실패 - logs/api.log 확인${NC}"
fi

# 2. TCP Relay (포트 10001)
echo -e "${GREEN}[2/4] TCP Relay 시작 (포트 10001)...${NC}"
nohup python suricata_tcp_relay.py > logs/relay.log 2>&1 &
RELAY_PID=$!
echo $RELAY_PID > pids/relay.pid
sleep 2

if ps -p $RELAY_PID > /dev/null; then
    echo -e "       ${GREEN}✓ 실행 중 (PID: $RELAY_PID)${NC}"
else
    echo -e "       ${RED}✗ 시작 실패 - logs/relay.log 확인${NC}"
fi

# 3. Rule Command Client (포트 10002)
echo -e "${GREEN}[3/4] Rule Command Client 시작 (포트 10002)...${NC}"
nohup python rule_command_client.py > logs/rule_client.log 2>&1 &
RULE_PID=$!
echo $RULE_PID > pids/rule_client.pid
sleep 2

if ps -p $RULE_PID > /dev/null; then
    echo -e "       ${GREEN}✓ 실행 중 (PID: $RULE_PID)${NC}"
else
    echo -e "       ${RED}✗ 시작 실패 - logs/rule_client.log 확인${NC}"
fi

# 4. Flow Extractor
echo -e "${GREEN}[4/4] Flow Extractor 시작...${NC}"
nohup python flow_extractor.py > logs/flow_extractor.log 2>&1 &
FLOW_PID=$!
echo $FLOW_PID > pids/flow_extractor.pid
sleep 2

if ps -p $FLOW_PID > /dev/null; then
    echo -e "       ${GREEN}✓ 실행 중 (PID: $FLOW_PID)${NC}"
else
    echo -e "       ${RED}✗ 시작 실패 - logs/flow_extractor.log 확인${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 장치 1 시작 완료!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}실행 중인 서비스:${NC}"
ps aux | grep python | grep -E "device1_api|suricata_tcp_relay|rule_command_client|flow_extractor" | grep -v grep
echo ""
echo -e "${YELLOW}로그 확인:${NC}"
echo -e "  ${CYAN}tail -f logs/api.log${NC}"
echo -e "  ${CYAN}tail -f logs/flow_extractor.log${NC}"
echo ""
echo -e "${YELLOW}서비스 중지:${NC}"
echo -e "  ${CYAN}../scripts/stop_device1.sh${NC}"
echo ""
echo -e "${YELLOW}⚠️  주의: 장치 2도 시작해야 시스템이 작동합니다!${NC}"
echo ""