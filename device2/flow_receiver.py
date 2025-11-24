#!/usr/bin/env python3
"""
flow_receiver.py
Flow 수신 & 자동 방어 (메인 시스템)
포트: 5001
"""

from flask import Flask, request, jsonify
import joblib
import requests
import json
import logging
import numpy as np
from threading import Lock

app = Flask(__name__)

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('flow_receiver.log'),
        logging.StreamHandler()
    ]
)

# 설정
DEVICE1_RULE_CLIENT = 'http://192.168.0.42:10002'
OLLAMA_URL = 'http://localhost:11434/api/generate'
OLLAMA_MODEL = 'qwen2.5:7b'

# 전역 변수
current_sid = 900000001
sid_lock = Lock()

# ML 모델 로드
try:
    model = joblib.load('models/random_forest_model.joblib')
    scaler = joblib.load('models/min_max_scaler.joblib')
    le = joblib.load('models/label_encoder.joblib')
    feature_names = joblib.load('models/feature_names.joblib')
    
    logging.info("✅ ML 모델 로드 완료")
    logging.info(f"   - Feature 개수: {len(feature_names)}")
    logging.info(f"   - 클래스 개수: {len(le.classes_)}")

except Exception as e:
    logging.error(f"❌ ML 모델 로드 실패: {e}")
    model = None


def get_next_sid():
    """Thread-safe SID 생성"""
    global current_sid
    with sid_lock:
        sid = current_sid
        current_sid += 1
        return sid


def convert_to_77_features(flow_data):
    """
    13개 Flow Feature → 77개 ML Feature 변환
    
    Args:
        flow_data (dict): Flow 데이터 (13개)
    
    반환:
        list: 77개 Feature 값
    """
    total_packets = flow_data['pkts_toserver'] + flow_data['pkts_toclient']
    total_bytes = flow_data['bytes_toserver'] + flow_data['bytes_toclient']
    flow_age = max(flow_data['flow_age'], 1)  # 0 방지
    
    # 기본 Feature 계산
    features_dict = {
        "Flow_Duration": flow_age * 1_000_000,  # 마이크로초
        "Total_Fwd_Packets": flow_data['pkts_toserver'],
        "Total_Backward_Packets": flow_data['pkts_toclient'],
        "Total_Length_of_Fwd_Packets": flow_data['bytes_toserver'],
        "Total_Length_of_Bwd_Packets": flow_data['bytes_toclient'],
        "Flow_Bytes_s": total_bytes / flow_age,
        "Flow_Packets_s": total_packets / flow_age,
        "Flow_IAT_Mean": (flow_age * 1_000_000) / max(total_packets, 1),
        "Fwd_IAT_Mean": (flow_age * 1_000_000) / max(flow_data['pkts_toserver'], 1),
        "Bwd_IAT_Mean": (flow_age * 1_000_000) / max(flow_data['pkts_toclient'], 1),
        "Fwd_Packet_Length_Mean": flow_data['bytes_toserver'] / max(flow_data['pkts_toserver'], 1),
        "Bwd_Packet_Length_Mean": flow_data['bytes_toclient'] / max(flow_data['pkts_toclient'], 1),
        "Packet_Length_Mean": total_bytes / max(total_packets, 1),
        "Packet_Length_Std": 0.0,  # 단순화
        "Packet_Length_Variance": 0.0,
        "Average_Packet_Size": total_bytes / max(total_packets, 1),
        "Fwd_Header_Length": flow_data['pkts_toserver'] * 20,  # 추정
        "Bwd_Header_Length": flow_data['pkts_toclient'] * 20,
    }
    
    # 나머지 Feature는 0.0으로 초기화
    for fname in feature_names:
        if fname not in features_dict:
            features_dict[fname] = 0.0
    
    # Feature 순서대로 리스트 생성
    return [features_dict[fname] for fname in feature_names]


def predict_attack(flow_data):
    """
    ML 모델로 공격 예측
    
    Args:
        flow_data (dict): Flow 데이터
    
    반환:
        dict: 예측 결과
    """
    if model is None:
        return {
            'is_malicious': False,
            'attack_type': 'UNKNOWN',
            'confidence': 0.0,
            'error': 'Model not loaded'
        }
    
    try:
        # Feature 변환
        features = convert_to_77_features(flow_data)
        
        # Infinity/NaN 처리
        features = [0.0 if (np.isnan(f) or np.isinf(f)) else f for f in features]
        
        # 스케일링
        X_scaled = scaler.transform([features])
        
        # 예측
        prediction = model.predict(X_scaled)[0]
        predicted_label = le.inverse_transform([prediction])[0]
        
        # 신뢰도
        probabilities = model.predict_proba(X_scaled)[0]
        confidence = probabilities.max()
        
        is_malicious = (predicted_label != 'BENIGN')
        
        return {
            'is_malicious': is_malicious,
            'attack_type': predicted_label,
            'confidence': float(confidence)
        }
    
    except Exception as e:
        logging.error(f"예측 오류: {e}")
        return {
            'is_malicious': False,
            'attack_type': 'ERROR',
            'confidence': 0.0,
            'error': str(e)
        }


def generate_suricata_rule(attack_type, flow_data):
    """
    Ollama (Qwen 2.5)로 Suricata 룰 생성
    
    Args:
        attack_type (str): 공격 유형
        flow_data (dict): Flow 데이터
    
    반환:
        str: Suricata 룰
    """
    sid = get_next_sid()
    
    # 공격 유형별 힌트
    hints = {
        'DDoS': 'Use threshold option: type both, track by_src, count 100, seconds 1',
        'PortScan': 'Use threshold option: type both, track by_src, count 50, seconds 1',
        'Web Attack': 'Use content option for HTTP detection, port 80 or 443',
        'Bot': 'Detect C&C communication patterns',
        'DoS': 'Use threshold for rate limiting'
    }
    
    hint = hints.get(attack_type, 'Create appropriate detection rule')
    
    prompt = f"""You are a Suricata IDS expert. Generate ONE line rule ONLY.

Attack Information:
- Type: {attack_type}
- Source IP: {flow_data['src_ip']}
- Destination IP: {flow_data['dest_ip']}
- Protocol: {flow_data['proto']}
- Hint: {hint}

Requirements:
1. Output ONLY the rule (one line, no explanation)
2. Format: drop tcp $EXTERNAL_NET any -> $HOME_NET any (msg:"AI_BLOCK:{attack_type}"; sid:{sid}; rev:1;)
3. Use appropriate options for {attack_type}
4. Do NOT include markdown, backticks, or any other text

Rule:"""
    
    try:
        response = requests.post(
            OLLAMA_URL,
            json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": 0.1,
                    "top_p": 0.9
                }
            },
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            generated_text = result.get('response', '').strip()
            
            # 룰 추출 (첫 번째 유효한 룰만)
            for line in generated_text.split('\n'):
                line = line.strip()
                if line.startswith(('drop', 'alert', 'reject', 'pass')):
                    # 백틱 제거
                    line = line.replace('```', '').strip()
                    
                    # 세미콜론으로 끝나는지 확인
                    if not line.endswith(';'):
                        line += ';'
                    
                    return line, sid
            
            # 유효한 룰을 찾지 못한 경우 기본 룰
            default_rule = f'drop tcp {flow_data["src_ip"]} any -> $HOME_NET any (msg:"AI_BLOCK:{attack_type}"; sid:{sid}; rev:1;)'
            logging.warning(f"유효한 룰 미생성, 기본 룰 사용")
            return default_rule, sid
        
        else:
            logging.error(f"Ollama 오류: {response.status_code}")
            return None, sid
    
    except Exception as e:
        logging.error(f"룰 생성 실패: {e}")
        return None, sid


def apply_rule_to_device1(rule, sid):
    """
    생성된 룰을 장치 1에 적용
    
    Args:
        rule (str): Suricata 룰
        sid (int): 룰 ID
    
    반환:
        bool: 성공 여부
    """
    try:
        response = requests.post(
            DEVICE1_RULE_CLIENT,
            json={
                "type": "ADD_RULE",
                "rule": rule,
                "sid": sid
            },
            timeout=5
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('return') == 'OK':
                logging.info(f"✅ 룰 적용 완료: SID {sid}")
                return True
            else:
                logging.error(f"❌ 룰 적용 실패: {result.get('message')}")
                return False
        else:
            logging.error(f"❌ 장치 1 응답 오류: {response.status_code}")
            return False
    
    except Exception as e:
        logging.error(f"❌ 룰 적용 오류: {e}")
        return False


@app.route('/health', methods=['GET'])
def health():
    """헬스 체크"""
    return jsonify({
        'status': 'healthy',
        'service': 'flow_receiver',
        'port': 5001,
        'model_loaded': model is not None
    })


@app.route('/receive-flow', methods=['POST'])
def receive_flow():
    """
    장치 1로부터 Flow 수신 및 처리
    
    POST /receive-flow
    Body: Flow 데이터 (JSON)
    """
    flow_data = request.json
    
    if not flow_data:
        return jsonify({'error': 'No data'}), 400
    
    src_ip = flow_data.get('src_ip', 'unknown')
    dest_ip = flow_data.get('dest_ip', 'unknown')
    
    # 1. ML 예측
    prediction = predict_attack(flow_data)
    
    if prediction['is_malicious']:
        attack_type = prediction['attack_type']
        confidence = prediction['confidence']
        
        logging.warning(
            f"🚨 악성 탐지! {attack_type} (신뢰도: {confidence:.2%}) "
            f"- {src_ip} → {dest_ip}"
        )
        
        # 2. Ollama 룰 생성
        logging.info(f"📝 Suricata 룰 생성 중...")
        rule, sid = generate_suricata_rule(attack_type, flow_data)
        
        if rule:
            logging.info(f"✓ 룰 생성 완료: {rule[:80]}...")
            
            # 3. 장치 1에 적용
            success = apply_rule_to_device1(rule, sid)
            
            return jsonify({
                'is_malicious': True,
                'attack_type': attack_type,
                'confidence': confidence,
                'rule_generated': True,
                'rule': rule,
                'sid': sid,
                'rule_applied': success
            })
        else:
            logging.error(f"❌ 룰 생성 실패")
            return jsonify({
                'is_malicious': True,
                'attack_type': attack_type,
                'confidence': confidence,
                'rule_generated': False,
                'error': 'Rule generation failed'
            })
    
    else:
        # 정상 트래픽
        return jsonify({
            'is_malicious': False,
            'attack_type': 'BENIGN'
        })


if __name__ == '__main__':
    print("=" * 60)
    print("🛡️ Flow Receiver & 자동 방어 시스템")
    print("=" * 60)
    print(f"📡 포트: 5001")
    print(f"🤖 ML 모델: {'✅ 로드됨' if model else '❌ 없음'}")
    print(f"🧠 Ollama: {OLLAMA_URL}")
    print(f"   모델: {OLLAMA_MODEL}")
    print(f"🎯 장치 1: {DEVICE1_RULE_CLIENT}")
    print("=" * 60)
    print("✅ 대기 중...\n")
    
    app.run(host='0.0.0.0', port=5001, debug=False)