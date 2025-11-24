#!/bin/bash
# setup_device1.sh - 장치 1 (Suricata 서버) 자동 설치
# 이 스크립트는 장치 1 (192.168.0.42)에서만 실행하세요!

set -e  # 오류 시 중단

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}🛡️  장치 1 (Suricata 서버) 설치 스크립트${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# 현재 IP 확인
CURRENT_IP=$(hostname -I | awk '{print $1}')
echo -e "${YELLOW}현재 장치 IP: ${CURRENT_IP}${NC}"
echo -e "${YELLOW}예상 IP: 192.168.0.42${NC}"
echo ""

if [[ "$CURRENT_IP" != "192.168.0.42"* ]]; then
    echo -e "${YELLOW}⚠️  IP 주소가 예상과 다릅니다.${NC}"
    echo -e "${YELLOW}   이 스크립트는 장치 1 (192.168.0.42)에서 실행해야 합니다.${NC}"
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

# device1 디렉토리 확인
if [ ! -d "$PROJECT_ROOT/device1" ]; then
    echo -e "${RED}❌ 오류: device1 디렉토리가 없습니다!${NC}"
    echo -e "${YELLOW}현재 위치: $(pwd)${NC}"
    exit 1
fi

cd "$PROJECT_ROOT/device1"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}설치 시작${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. 시스템 업데이트
echo -e "${YELLOW}[1/7] 시스템 업데이트 중...${NC}"
sudo apt update -qq
echo -e "${GREEN}✓ 완료${NC}"
echo ""

# 2. Suricata 설치 확인
echo -e "${YELLOW}[2/7] Suricata 확인 중...${NC}"
if ! command -v suricata &> /dev/null; then
    echo -e "${YELLOW}   Suricata 설치 중... (시간 소요)${NC}"
    sudo apt install -y suricata
    sudo systemctl enable suricata
    echo -e "${GREEN}✓ Suricata 설치 완료${NC}"
else
    SURICATA_VERSION=$(suricata --version 2>&1 | head -1)
    echo -e "${GREEN}✓ Suricata 이미 설치됨 (${SURICATA_VERSION})${NC}"
fi

# Suricata 시작 여부 확인
if ! systemctl is-active --quiet suricata; then
    echo -e "${YELLOW}   Suricata 시작 중...${NC}"
    sudo systemctl start suricata
    sleep 3
fi
echo ""

# 3. Python 환경
echo -e "${YELLOW}[3/7] Python 환경 확인 중...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}   Python 설치 중...${NC}"
    sudo apt install -y python3 python3-pip python3-venv
fi
PYTHON_VERSION=$(python3 --version)
echo -e "${GREEN}✓ ${PYTHON_VERSION}${NC}"
echo ""

# 4. 가상환경 생성
echo -e "${YELLOW}[4/7] Python 가상환경 생성 중...${NC}"
if [ -d "venv" ]; then
    echo -e "${GREEN}✓ 가상환경 이미 존재${NC}"
else
    python3 -m venv venv
    echo -e "${GREEN}✓ 가상환경 생성 완료${NC}"
fi
echo ""

# 5. 패키지 설치
echo -e "${YELLOW}[5/7] Python 패키지 설치 중...${NC}"
source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo -e "${GREEN}✓ 패키지 설치 완료${NC}"
echo ""

# 6. Suricata 로그 권한 설정
echo -e "${YELLOW}[6/7] Suricata 로그 권한 설정 중...${NC}"

# eve.json 확인
if [ -f "/var/log/suricata/eve.json" ]; then
    echo -e "   ${GREEN}✓${NC} eve.json 파일 존재"
    
    # 읽기 권한 확인
    if [ -r "/var/log/suricata/eve.json" ]; then
        echo -e "   ${GREEN}✓${NC} 읽기 권한 있음"
    else
        echo -e "   ${RED}✗${NC} 읽기 권한 없음"
        echo ""
        echo -e "   ${CYAN}권한 설정 방법:${NC}"
        echo -e "   ${YELLOW}1)${NC} 파일 권한 변경 (chmod 644)"
        echo -e "   ${YELLOW}2)${NC} 사용자를 adm 그룹에 추가"
        echo -e "   ${YELLOW}3)${NC} 둘 다"
        echo ""
        read -p "   선택 (1-3): " -n 1 -r
        echo
        
        case $REPLY in
            1)
                sudo chmod 644 /var/log/suricata/eve.json
                sudo chmod 755 /var/log/suricata
                echo -e "   ${GREEN}✓${NC} 파일 권한 변경 완료"
                ;;
            2)
                sudo usermod -a -G adm $USER
                echo -e "   ${GREEN}✓${NC} adm 그룹 추가 완료"
                echo -e "   ${YELLOW}⚠${NC} 'newgrp adm' 실행 후 재로그인 필요"
                ;;
            3)
                sudo chmod 644 /var/log/suricata/eve.json
                sudo chmod 755 /var/log/suricata
                sudo usermod -a -G adm $USER
                echo -e "   ${GREEN}✓${NC} 모든 권한 설정 완료"
                echo -e "   ${YELLOW}⚠${NC} 'newgrp adm' 실행 후 재로그인 필요"
                ;;
            *)
                echo -e "   ${YELLOW}⚠${NC} 건너뛰기"
                ;;
        esac
    fi
else
    echo -e "   ${YELLOW}⚠${NC} eve.json 파일 없음 (Suricata 시작 후 생성됨)"
fi
echo ""

# 7. 디렉토리 생성
echo -e "${YELLOW}[7/7] 디렉토리 생성 중...${NC}"
mkdir -p logs pids
echo -e "${GREEN}✓ logs/, pids/ 디렉토리 생성${NC}"
echo ""

# config.json 확인
if [ ! -f "config.json" ]; then
    echo -e "${YELLOW}⚠ config.json 생성 중...${NC}"
    cat > config.json << 'EOF'
{
  "device_id": "device1",
  "device_name": "Suricata 서버",
  "ip_address": "192.168.0.42",
  
  "suricata": {
    "eve_log_path": "/var/log/suricata/eve.json",
    "socket_path": "/var/run/suricata/suricata-command.socket",
    "rules_path": "/etc/suricata/rules"
  },
  
  "services": {
    "api": {
      "host": "0.0.0.0",
      "port": 8000
    },
    "relay": {
      "host": "0.0.0.0",
      "port": 10001
    },
    "rule_client": {
      "host": "0.0.0.0",
      "port": 10002
    }
  },
  
  "flow_extractor": {
    "min_flow_age": 5,
    "device2_url": "http://192.168.0.14:5001/receive-flow"
  }
}
EOF
    echo -e "${GREEN}✓ config.json 생성 완료${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 장치 1 설치 완료!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo -e "  ${CYAN}1. 서비스 시작:${NC}"
echo -e "     cd $PROJECT_ROOT"
echo -e "     ./scripts/start_device1.sh"
echo ""
echo -e "  ${CYAN}2. 연결 테스트:${NC}"
echo -e "     ./scripts/check_connection.sh"
echo ""
echo -e "${YELLOW}⚠️  중요: 장치 2 (192.168.0.14)도 설정해야 합니다!${NC}"
echo ""