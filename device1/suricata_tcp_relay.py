#!/usr/bin/env python3
"""
suricata_tcp_relay.py
TCP → Unix Socket 중계 서버
포트: 10001
"""

import socket
import json
import logging

# 설정
RELAY_LISTEN_IP = '0.0.0.0'
RELAY_LISTEN_PORT = 10001
SURICATA_SOCKET_PATH = '/var/run/suricata/suricata-command.socket'
SURICATA_TIMEOUT = 5
BUFFER_SIZE = 4096

# 로깅
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('suricata_tcp_relay.log'),
        logging.StreamHandler()
    ]
)


def send_command_to_suricata(command_json):
    """
    Suricata Unix Socket으로 명령 전송
    
    Args:
        command_json (dict): Suricata 명령
    
    반환:
        dict: Suricata 응답
    """
    try:
        # Unix Socket 연결
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(SURICATA_TIMEOUT)
        sock.connect(SURICATA_SOCKET_PATH)
        
        # JSON 전송 (개행 추가)
        message = json.dumps(command_json) + '\n'
        sock.sendall(message.encode('utf-8'))
        
        # 응답 수신
        response_data = b""
        while True:
            chunk = sock.recv(BUFFER_SIZE)
            if not chunk:
                break
            response_data += chunk
            
            # 개행 문자로 종료 판단
            if b'\n' in chunk:
                break
        
        sock.close()
        
        # 응답 파싱
        response_str = response_data.decode('utf-8').strip()
        response = json.loads(response_str)
        
        return response
    
    except FileNotFoundError:
        logging.error(f"Suricata Socket 없음: {SURICATA_SOCKET_PATH}")
        return {'return': 'NOK', 'message': 'Socket file not found'}
    
    except socket.timeout:
        logging.error("Suricata 타임아웃")
        return {'return': 'NOK', 'message': 'Timeout'}
    
    except Exception as e:
        logging.error(f"Suricata 통신 오류: {e}")
        return {'return': 'NOK', 'message': str(e)}


def handle_client_command(client_socket, client_addr):
    """클라이언트 명령 처리"""
    try:
        # 데이터 수신
        data_bytes = client_socket.recv(BUFFER_SIZE)
        
        if not data_bytes:
            return
        
        # JSON 파싱
        command_json = json.loads(data_bytes.decode('utf-8'))
        
        logging.info(f"📨 명령 수신: {client_addr}")
        logging.info(f"   {command_json.get('command', 'unknown')}")
        
        # Suricata로 전달
        response = send_command_to_suricata(command_json)
        
        # 응답 전송
        response_json = json.dumps(response)
        client_socket.sendall(response_json.encode('utf-8'))
        
        if response.get('return') == 'OK':
            logging.info(f"✅ 성공")
        else:
            logging.error(f"❌ 실패: {response.get('message')}")
    
    except json.JSONDecodeError as e:
        logging.error(f"JSON 파싱 오류: {e}")
    
    except Exception as e:
        logging.error(f"처리 오류: {e}")
    
    finally:
        client_socket.close()


def start_relay_server():
    """TCP Relay 서버 시작"""
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_socket.bind((RELAY_LISTEN_IP, RELAY_LISTEN_PORT))
    server_socket.listen(5)
    
    logging.info("=" * 60)
    logging.info("🔌 Suricata TCP Relay 시작")
    logging.info("=" * 60)
    logging.info(f"📡 TCP 리스닝: {RELAY_LISTEN_IP}:{RELAY_LISTEN_PORT}")
    logging.info(f"🔧 Unix Socket: {SURICATA_SOCKET_PATH}")
    logging.info("=" * 60)
    logging.info("✅ 대기 중...\n")
    
    while True:
        try:
            client_socket, client_addr = server_socket.accept()
            handle_client_command(client_socket, client_addr)
        
        except KeyboardInterrupt:
            logging.info("\n🛑 서버 종료")
            break
        except Exception as e:
            logging.error(f"서버 오류: {e}")
    
    server_socket.close()


if __name__ == '__main__':
    start_relay_server()