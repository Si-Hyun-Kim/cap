#!/usr/bin/env python3
"""
rule_command_client.py
AI 룰 추가 명령 수신 및 Suricata 적용
포트: 10002
"""

import socket
import json
import logging
import requests

# 설정
LISTEN_IP = '0.0.0.0'
LISTEN_PORT = 10002
RELAY_SERVER = 'http://127.0.0.1:10001'
BUFFER_SIZE = 4096

# 로깅
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('rule_command_client.log'),
        logging.StreamHandler()
    ]
)


def send_to_suricata_relay(command_json):
    """
    로컬 Relay Server로 Suricata 명령 전송
    
    Args:
        command_json (dict): Suricata 명령
    
    반환:
        dict: Suricata 응답
    """
    try:
        # TCP로 Relay Server에 전송
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        sock.connect(('127.0.0.1', 10001))
        
        # JSON 전송
        message = json.dumps(command_json) + '\n'
        sock.sendall(message.encode('utf-8'))
        
        # 응답 수신
        response_data = b""
        while True:
            chunk = sock.recv(BUFFER_SIZE)
            if not chunk:
                break
            response_data += chunk
        
        sock.close()
        
        # 응답 파싱
        response = json.loads(response_data.decode('utf-8'))
        return response
    
    except Exception as e:
        logging.error(f"Relay 통신 오류: {e}")
        return {'return': 'NOK', 'message': str(e)}


def process_add_rule_command(data):
    """
    룰 추가 명령 처리
    
    Args:
        data (dict): {"type": "ADD_RULE", "rule": "...", "sid": 900000001}
    """
    rule = data.get('rule')
    sid = data.get('sid')
    
    if not rule or not sid:
        logging.error("필수 파라미터 누락: rule, sid")
        return {'return': 'NOK', 'message': 'Missing rule or sid'}
    
    logging.info(f"📝 룰 추가 요청: SID {sid}")
    logging.info(f"   룰: {rule[:80]}...")
    
    # Suricata 명령 구성
    suricata_command = {
        "command": "rule-add",
        "rule": rule,
        "sid": sid
    }
    
    # Relay Server로 전송
    response = send_to_suricata_relay(suricata_command)
    
    if response.get('return') == 'OK':
        logging.info(f"✅ 룰 추가 성공: SID {sid}")
        return {'return': 'OK', 'message': 'Rule added successfully'}
    else:
        logging.error(f"❌ 룰 추가 실패: {response.get('message')}")
        return response


def handle_client_connection(client_socket):
    """클라이언트 연결 처리"""
    try:
        # 데이터 수신
        data_bytes = client_socket.recv(BUFFER_SIZE)
        
        if not data_bytes:
            return
        
        # JSON 파싱
        data = json.loads(data_bytes.decode('utf-8'))
        
        command_type = data.get('type')
        
        if command_type == 'ADD_RULE':
            response = process_add_rule_command(data)
        else:
            response = {'return': 'NOK', 'message': f'Unknown command: {command_type}'}
        
        # 응답 전송
        response_json = json.dumps(response)
        client_socket.sendall(response_json.encode('utf-8'))
    
    except json.JSONDecodeError as e:
        logging.error(f"JSON 파싱 오류: {e}")
        error_response = json.dumps({'return': 'NOK', 'message': 'Invalid JSON'})
        client_socket.sendall(error_response.encode('utf-8'))
    
    except Exception as e:
        logging.error(f"처리 오류: {e}")
    
    finally:
        client_socket.close()


def start_server():
    """TCP 서버 시작"""
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_socket.bind((LISTEN_IP, LISTEN_PORT))
    server_socket.listen(5)
    
    logging.info("=" * 60)
    logging.info("🎯 Rule Command Client 시작")
    logging.info("=" * 60)
    logging.info(f"📡 리스닝: {LISTEN_IP}:{LISTEN_PORT}")
    logging.info(f"🔌 Relay: {RELAY_SERVER}")
    logging.info("=" * 60)
    logging.info("✅ 대기 중...\n")
    
    while True:
        try:
            client_socket, client_addr = server_socket.accept()
            logging.info(f"📥 연결: {client_addr}")
            handle_client_connection(client_socket)
        
        except KeyboardInterrupt:
            logging.info("\n🛑 서버 종료")
            break
        except Exception as e:
            logging.error(f"서버 오류: {e}")
    
    server_socket.close()


if __name__ == '__main__':
    start_server()