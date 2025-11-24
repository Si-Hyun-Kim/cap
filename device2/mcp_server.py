#!/usr/bin/env python3
"""
mcp_server.py
MCP Server - 도구 제공자
"""

from mcp.server.fastmcp import FastMCP
import joblib
import requests
import json
import numpy as np
import logging

mcp = FastMCP("suricata-defense-server")

# 설정
DEVICE1_API = "http://192.168.0.42:8000"
DEVICE1_RULE_CLIENT = "http://192.168.0.42:10002"
OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = "qwen2.5:7b"

# 로깅
logging.basicConfig(level=logging.INFO)

# ML 모델 로드
try:
    model = joblib.load('models/random_forest_model.joblib')
    scaler = joblib.load('models/min_max_scaler.joblib')
    le = joblib.load('models/label_encoder.joblib')
    feature_names = joblib.load('models/feature_names.joblib')
    logging.info("✅ ML 모델 로드 완료")
except Exception as e:
    logging.error(f"❌ ML 모델 로드 실패: {e}")
    model = None


@mcp.tool()
def get_suricata_logs(count: int = 10) -> str:
    """
    장치 1의 Suricata 로그를 가져옵니다.
    
    Args:
        count: 가져올 로그 개수 (기본 10)
    
    Returns:
        JSON 문자열: 로그 데이터
    """
    try:
        response = requests.get(
            f"{DEVICE1_API}/api/logs/suricata?count={count}",
            timeout=5
        )
        
        if response.status_code == 200:
            return json.dumps(response.json(), ensure_ascii=False, indent=2)
        else:
            return json.dumps({
                'error': f'HTTP {response.status_code}'
            })
    
    except Exception as e:
        return json.dumps({
            'error': str(e)
        })


@mcp.tool()
def analyze_network_flow(flow_data: dict) -> str:
    """
    네트워크 Flow를 ML 모델로 분석합니다.
    
    Args:
        flow_data: Flow Feature 딕셔너리
    
    Returns:
        JSON 문자열: 분석 결과
    """
    if model is None:
        return json.dumps({
            'error': 'Model not loaded'
        })
    
    try:
        # 13개 → 77개 변환 (flow_receiver.py와 동일 로직)
        total_packets = flow_data['pkts_toserver'] + flow_data['pkts_toclient']
        total_bytes = flow_data['bytes_toserver'] + flow_data['bytes_toclient']
        flow_age = max(flow_data['flow_age'], 1)
        
        features_dict = {
            "Flow_Duration": flow_age * 1_000_000,
            "Total_Fwd_Packets": flow_data['pkts_toserver'],
            "Total_Backward_Packets": flow_data['pkts_toclient'],
            "Total_Length_of_Fwd_Packets": flow_data['bytes_toserver'],
            "Total_Length_of_Bwd_Packets": flow_data['bytes_toclient'],
            "Flow_Bytes_s": total_bytes / flow_age,
            "Flow_Packets_s": total_packets / flow_age,
        }
        
        for fname in feature_names:
            if fname not in features_dict:
                features_dict[fname] = 0.0
        
        features = [features_dict[fname] for fname in feature_names]
        features = [0.0 if (np.isnan(f) or np.isinf(f)) else f for f in features]
        
        # 예측
        X_scaled = scaler.transform([features])
        prediction = model.predict(X_scaled)[0]
        predicted_label = le.inverse_transform([prediction])[0]
        confidence = model.predict_proba(X_scaled)[0].max()
        
        return json.dumps({
            'attack_type': predicted_label,
            'confidence': float(confidence),
            'is_malicious': predicted_label != 'BENIGN'
        }, ensure_ascii=False)
    
    except Exception as e:
        return json.dumps({
            'error': str(e)
        })


@mcp.tool()
def generate_suricata_rule(attack_type: str, src_ip: str, dest_ip: str, proto: str = "TCP") -> str:
    """
    Ollama를 사용하여 Suricata 룰을 생성합니다.
    
    Args:
        attack_type: 공격 유형
        src_ip: 출발지 IP
        dest_ip: 목적지 IP
        proto: 프로토콜 (기본 TCP)
    
    Returns:
        JSON 문자열: 생성된 룰
    """
    prompt = f"""You are a Suricata expert. Generate ONE line rule ONLY.

Attack: {attack_type}
Source: {src_ip}
Destination: {dest_ip}
Protocol: {proto}

Output format: drop tcp $EXTERNAL_NET any -> $HOME_NET any (msg:"AI_BLOCK:{attack_type}"; sid:900000001; rev:1;)

Rule:"""
    
    try:
        response = requests.post(
            OLLAMA_URL,
            json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False,
                "options": {"temperature": 0.1}
            },
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            generated_text = result.get('response', '').strip()
            
            # 룰 추출
            for line in generated_text.split('\n'):
                line = line.strip()
                if line.startswith(('drop', 'alert', 'reject')):
                    line = line.replace('```', '').strip()
                    if not line.endswith(';'):
                        line += ';'
                    return json.dumps({'rule': line}, ensure_ascii=False)
            
            # 기본 룰
            default_rule = f'drop tcp {src_ip} any -> $HOME_NET any (msg:"AI_BLOCK:{attack_type}"; sid:900000001; rev:1;)'
            return json.dumps({'rule': default_rule}, ensure_ascii=False)
        else:
            return json.dumps({'error': f'Ollama HTTP {response.status_code}'})
    
    except Exception as e:
        return json.dumps({'error': str(e)})


@mcp.tool()
def apply_rule_to_suricata(rule: str, sid: int = 900000001) -> str:
    """
    생성된 룰을 장치 1의 Suricata에 적용합니다.
    
    Args:
        rule: Suricata 룰 문자열
        sid: 룰 ID
    
    Returns:
        JSON 문자열: 적용 결과
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
            return json.dumps(response.json(), ensure_ascii=False)
        else:
            return json.dumps({
                'error': f'HTTP {response.status_code}'
            })
    
    except Exception as e:
        return json.dumps({
            'error': str(e)
        })


if __name__ == '__main__':
    print("=" * 60)
    print("🔧 MCP Server 시작")
    print("=" * 60)
    print("📋 제공 도구:")
    print("   1. get_suricata_logs(count)")
    print("   2. analyze_network_flow(flow_data)")
    print("   3. generate_suricata_rule(attack_type, src_ip, dest_ip, proto)")
    print("   4. apply_rule_to_suricata(rule, sid)")
    print("=" * 60)
    
    mcp.run(transport='stdio')