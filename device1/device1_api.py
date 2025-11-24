#!/usr/bin/env python3
"""
device1_api.py
Suricata 로그 조회 API (Flask)
포트: 8000
"""

from flask import Flask, jsonify, request
import json
from pathlib import Path
import logging

app = Flask(__name__)

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('device1_api.log'),
        logging.StreamHandler()
    ]
)

# 설정
EVE_LOG_PATH = '/var/log/suricata/eve.json'

@app.route('/health', methods=['GET'])
def health():
    """헬스 체크"""
    return jsonify({
        'status': 'healthy',
        'service': 'device1_api',
        'port': 8000
    })

@app.route('/api/logs/suricata', methods=['GET'])
def get_suricata_logs():
    """
    Suricata 로그 조회 API
    
    쿼리 파라미터:
        count (int): 가져올 로그 개수 (기본 10)
    
    반환:
        JSON: {"logs": [...]}
    """
    count = request.args.get('count', default=10, type=int)
    
    logs = []
    
    try:
        if not Path(EVE_LOG_PATH).exists():
            logging.error(f"EVE 로그 파일 없음: {EVE_LOG_PATH}")
            return jsonify({
                'error': 'EVE log file not found',
                'path': EVE_LOG_PATH
            }), 404
        
        with open(EVE_LOG_PATH, 'r') as f:
            lines = f.readlines()
            
            # 최근 로그부터 (역순)
            for line in reversed(lines[-count*2:]):  # 여유있게 2배
                try:
                    log = json.loads(line.strip())
                    
                    # Flow 타입만 필터링
                    if log.get('event_type') == 'flow':
                        flow = log.get('flow', {})
                        
                        logs.append({
                            'timestamp': log.get('timestamp'),
                            'src_ip': log.get('src_ip'),
                            'dest_ip': log.get('dest_ip'),
                            'src_port': log.get('src_port'),
                            'dest_port': log.get('dest_port'),
                            'proto': log.get('proto'),
                            'flow_age': flow.get('age', 0),
                            'pkts_toserver': flow.get('pkts_toserver', 0),
                            'pkts_toclient': flow.get('pkts_toclient', 0),
                            'bytes_toserver': flow.get('bytes_toserver', 0),
                            'bytes_toclient': flow.get('bytes_toclient', 0),
                            'flow_state': flow.get('state', 'unknown')
                        })
                        
                        if len(logs) >= count:
                            break
                
                except json.JSONDecodeError:
                    continue
        
        logging.info(f"로그 조회 완료: {len(logs)}개")
        
        return jsonify({
            'logs': logs,
            'count': len(logs)
        })
    
    except Exception as e:
        logging.error(f"로그 조회 오류: {e}")
        return jsonify({
            'error': str(e)
        }), 500


@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Suricata 통계"""
    try:
        total_flows = 0
        event_types = {}
        
        with open(EVE_LOG_PATH, 'r') as f:
            for line in f:
                try:
                    log = json.loads(line.strip())
                    event_type = log.get('event_type', 'unknown')
                    event_types[event_type] = event_types.get(event_type, 0) + 1
                    
                    if event_type == 'flow':
                        total_flows += 1
                
                except:
                    continue
        
        return jsonify({
            'total_flows': total_flows,
            'event_types': event_types
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    print("=" * 60)
    print("🚀 장치 1 API 서버 시작")
    print("=" * 60)
    print(f"📡 포트: 8000")
    print(f"📁 EVE 로그: {EVE_LOG_PATH}")
    print(f"🌐 엔드포인트:")
    print(f"   - GET /health")
    print(f"   - GET /api/logs/suricata?count=10")
    print(f"   - GET /api/stats")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=8000, debug=False)


@app.route('/api/stats', methods=['GET'])
def get_stats():
    """대시보드 통계"""
    try:
        # eve.json에서 최근 24시간 데이터 집계
        # (간단한 예시)
        return jsonify({
            "total_alerts_24h": 150,
            "blocked_attacks_24h": 120,
            "critical_alerts_24h": 25,
            "active_rules_count": 50,
            "severity_distribution": {
                "critical": 25,
                "high": 45,
                "medium": 50,
                "low": 30
            }
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/timeline', methods=['GET'])
def get_timeline():
    """시간대별 타임라인"""
    hours = request.args.get('hours', 24, type=int)
    
    # 실제로는 eve.json 파싱해서 시간대별 집계
    timeline = [
        {"time": f"{h:02d}:00", "count": random.randint(5, 20)}
        for h in range(24)
    ]
    
    return jsonify({"timeline": timeline})

@app.route('/api/rules', methods=['GET'])
def get_rules():
    """활성 룰 목록"""
    category = request.args.get('category', 'all')
    
    # Suricata 룰 파일 읽기
    rules = []
    rules_dir = "/etc/suricata/rules"
    
    try:
        for file in os.listdir(rules_dir):
            if file.endswith('.rules'):
                with open(os.path.join(rules_dir, file), 'r') as f:
                    for line in f:
                        if line.startswith('alert') or line.startswith('drop'):
                            rules.append({
                                "rule": line.strip(),
                                "file": file,
                                "category": "unknown"
                            })
        
        return jsonify({"rules": rules, "total": len(rules)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500