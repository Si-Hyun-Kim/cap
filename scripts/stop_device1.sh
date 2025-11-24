#!/bin/bash
# stop_device1.sh - 장치 1 서비스만 중지

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}🛑 장치 1 서비스 중지 중...${NC}"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT/device1"

STOPPED=0

# PID 파일로 중지
if [ -d "pids" ]; then
    for pidfile in pids/*.pid; do
        if [ -f "$pidfile" ]; then
            pid=$(cat "$pidfile")
            if ps -p $pid > /dev/null 2>&1; then
                kill $pid 2>/dev/null
                echo -e "  ${RED}●${NC} $(basename $pidfile .pid) 중지 (PID: $pid)"
                ((STOPPED++))
            fi
            rm "$pidfile"
        fi
    done
fi

# 프로세스 이름으로도 중지
pkill -f "device1_api.py" 2>/dev/null && ((STOPPED++))
pkill -f "flow_extractor.py" 2>/dev/null && ((STOPPED++))
pkill -f "rule_command_client.py" 2>/dev/null && ((STOPPED++))
pkill -f "suricata_tcp_relay.py" 2>/dev/null && ((STOPPED++))

echo ""
echo -e "${GREEN}✓ ${STOPPED}개 서비스 중지 완료${NC}"
echo ""