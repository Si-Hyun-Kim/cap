#!/usr/bin/env python3
"""
flow_extractor.py
Suricata EVE 로그 실시간 모니터링 및 장치 2로 전송
"""

import json
import time
import requests
import logging
from pathlib import Path

# 설정
EVE_LOG_PATH = '/var/log/suricata/eve.json'
DEVICE2_RECEIVER = 'http://192.168.0.14:5001/receive-flow'
MIN_FLOW_AGE = 5  # 최소 지속 시간 (초)

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('flow_extractor.log'),
        logging.StreamHandler()
    ]
)

def extract_flow_features(log_entry):
    """
    EVE 로그에서 Flow Feature 추출
    
    반환:
        dict: Flow 데이터 (13개 Feature)
    """
    if log_entry.get('event_type') != 'flow':
        return None
    
    flow = log_entry.get('flow', {})
    
    # 최소 지속 시간 체크
    flow_age = flow.get('age', 0)
    if flow_age < MIN_FLOW_AGE:
        return None
    
    # Flow 상태 필터 (established, closed만)
    flow_state = flow.get('state', '')
    if flow_state not in ['established', 'closed']:
        return None
    
    return {
        'timestamp': log_entry.get('timestamp'),
        'flow_id': log_entry.get('flow_id'),
        'src_ip': log_entry.get('src_ip'),
        'dest_ip': log_entry.get('dest_ip'),
        'src_port': log_entry.get('src_port'),
        'dest_port': log_entry.get('dest_port'),
        'proto': log_entry.get('proto'),
        'flow_age': flow_age,
        'flow_state': flow_state,
        'pkts_toserver': flow.get('pkts_toserver', 0),
        'pkts_toclient': flow.get('pkts_toclient', 0),
        'bytes_toserver': flow.get('bytes_toserver', 0),
        'bytes_toclient': flow.get('bytes_toclient', 0)
    }


def send_to_device2(flow_data):
    """
    Flow 데이터를 장치 2로 전송
    
    Args:
        flow_data (dict): Flow Feature
    
    반환:
        bool: 성공 여부
    """
    try:
        response = requests.post(
            DEVICE2_RECEIVER,
            json=flow_data,
            timeout=2
        )
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('is_malicious'):
                logging.warning(
                    f"🚨 악성 탐지! "
                    f"{result['attack_type']} "
                    f"(신뢰도: {result['confidence']:.2%}) "
                    f"- {flow_data['src_ip']} → {flow_data['dest_ip']}"
                )
            else:
                logging.info(
                    f"✓ 정상: {flow_data['src_ip']} → {flow_data['dest_ip']}"
                )
            
            return True
        else:
            logging.error(f"장치 2 응답 오류: {response.status_code}")
            return False
    
    except requests.exceptions.Timeout:
        logging.error("장치 2 타임아웃")
        return False
    except requests.exceptions.ConnectionError:
        logging.error("장치 2 연결 실패")
        return False
    except Exception as e:
        logging.error(f"전송 오류: {e}")
        return False


def stream_eve_log():
    """EVE 로그 실시간 스트리밍"""
    
    logging.info("=" * 60)
    logging.info("🚀 Flow Extractor 시작")
    logging.info("=" * 60)
    logging.info(f"📁 EVE 로그: {EVE_LOG_PATH}")
    logging.info(f"📡 장치 2: {DEVICE2_RECEIVER}")
    logging.info(f"⏱️  최소 지속 시간: {MIN_FLOW_AGE}초")
    logging.info("=" * 60)
    
    # 파일 체크
    while not Path(EVE_LOG_PATH).exists():
        logging.warning(f"EVE 로그 대기 중: {EVE_LOG_PATH}")
        time.sleep(1)
    
    # 파일 열기
    logfile = open(EVE_LOG_PATH, 'r')
    
    # 파일 끝으로 이동 (기존 로그 무시)
    logfile.seek(0, 2)
    
    logging.info("✅ 모니터링 시작!\n")
    
    # 무한 루프
    while True:
        line = logfile.readline()
        
        if not line:
            # 새 데이터 없음
            time.sleep(0.1)
            continue
        
        try:
            # JSON 파싱
            log_entry = json.loads(line.strip())
            
            # Flow Feature 추출
            flow_data = extract_flow_features(log_entry)
            
            if flow_data:
                # 장치 2로 전송
                send_to_device2(flow_data)
        
        except json.JSONDecodeError:
            continue
        except Exception as e:
            logging.error(f"처리 오류: {e}")


if __name__ == '__main__':
    try:
        stream_eve_log()
    except KeyboardInterrupt:
        logging.info("\n🛑 중지됨")
    except Exception as e:
        logging.error(f"치명적 오류: {e}")