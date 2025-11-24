#!/usr/bin/env python3
"""
train_model.py
Random Forest 모델 훈련 (CICIDS2017 데이터셋)
"""

import pandas as pd
import numpy as np
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, MinMaxScaler
from sklearn.metrics import classification_report, accuracy_score
import logging
from pathlib import Path

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)

# CICIDS2017 데이터셋 파일 목록
DATASET_FILES = [
    'data/Friday-WorkingHours-Afternoon-DDos.pcap_ISCX.csv',
    'data/Friday-WorkingHours-Afternoon-PortScan.pcap_ISCX.csv',
    'data/Friday-WorkingHours-Morning.pcap_ISCX.csv',
    'data/Monday-WorkingHours.pcap_ISCX.csv',
    'data/Thursday-WorkingHours-Afternoon-Infilteration.pcap_ISCX.csv',
    'data/Thursday-WorkingHours-Morning-WebAttacks.pcap_ISCX.csv',
    'data/Tuesday-WorkingHours.pcap_ISCX.csv',
    'data/Wednesday-workingHours.pcap_ISCX.csv'
]

# 출력 디렉토리
OUTPUT_DIR = Path('models')


def load_and_clean_data(file_list):
    """
    데이터셋 로드 및 전처리
    
    Args:
        file_list: CSV 파일 리스트
    
    Returns:
        X (DataFrame): Feature
        y (Series): Label
    """
    logging.info("=" * 60)
    logging.info("데이터 로드 시작")
    logging.info("=" * 60)
    
    dfs = []
    
    for file_path in file_list:
        if not Path(file_path).exists():
            logging.warning(f"파일 없음: {file_path}")
            continue
        
        logging.info(f"로드 중: {file_path}")
        df = pd.read_csv(file_path, encoding='utf-8', low_memory=False)
        dfs.append(df)
    
    if not dfs:
        raise FileNotFoundError("데이터셋 파일이 없습니다!")
    
    # 모든 데이터 통합
    data = pd.concat(dfs, ignore_index=True)
    logging.info(f"✓ 총 {len(data):,}개 행 로드됨")
    
    # 컬럼 이름 정리 (공백 제거, 언더스코어 변환)
    data.columns = data.columns.str.strip().str.replace(' ', '_')
    
    logging.info("\n데이터 전처리 중...")
    
    # 불필요한 컬럼 제거
    drop_columns = ['Flow_ID', 'Source_IP', 'Source_Port', 
                    'Destination_IP', 'Destination_Port', 'Timestamp']
    
    for col in drop_columns:
        if col in data.columns:
            data = data.drop(columns=[col])
    
    # 무한대 값을 NaN으로 변환
    data = data.replace([np.inf, -np.inf], np.nan)
    
    # 결측치 제거
    before_dropna = len(data)
    data = data.dropna()
    after_dropna = len(data)
    logging.info(f"✓ 결측치 제거: {before_dropna - after_dropna:,}개 행")
    
    # Label 컬럼 확인
    if 'Label' not in data.columns:
        raise ValueError("Label 컬럼이 없습니다!")
    
    # Feature(X)와 Label(y) 분리
    X = data.drop(columns=['Label'])
    y = data['Label']
    
    logging.info(f"✓ Feature 개수: {X.shape[1]}")
    logging.info(f"✓ 최종 데이터: {len(X):,}개 행")
    
    return X, y


def preprocess_features_labels(X, y):
    """
    Feature 스케일링 및 Label 인코딩
    
    Args:
        X (DataFrame): Feature
        y (Series): Label
    
    Returns:
        X_scaled (ndarray): 스케일링된 Feature
        y_encoded (ndarray): 인코딩된 Label
        scaler (MinMaxScaler): 스케일러 객체
        le (LabelEncoder): 레이블 인코더 객체
        feature_names (list): Feature 이름 리스트
    """
    logging.info("\n" + "=" * 60)
    logging.info("Feature 전처리")
    logging.info("=" * 60)
    
    # Feature 이름 저장
    feature_names = X.columns.tolist()
    logging.info(f"Feature 개수: {len(feature_names)}")
    
    # Label 통합 (비슷한 공격 유형 합치기)
    label_mapping = {
        'Web Attack � Brute Force': 'Web Attack',
        'Web Attack � XSS': 'Web Attack',
        'Web Attack � Sql Injection': 'Web Attack',
    }
    
    y = y.replace(label_mapping)
    
    # Label 인코딩
    le = LabelEncoder()
    y_encoded = le.fit_transform(y)
    
    logging.info(f"\n공격 유형 ({len(le.classes_)}개):")
    for idx, label in enumerate(le.classes_):
        count = (y == label).sum()
        logging.info(f"  {idx}: {label} ({count:,}개)")
    
    # Feature 스케일링 (0~1 범위)
    logging.info("\nFeature 스케일링 중...")
    scaler = MinMaxScaler()
    X_scaled = scaler.fit_transform(X)
    
    logging.info("✓ 스케일링 완료")
    
    return X_scaled, y_encoded, scaler, le, feature_names


def train_and_save_model(X, y, scaler, le, feature_names):
    """
    Random Forest 모델 훈련 및 저장
    
    Args:
        X (ndarray): Feature
        y (ndarray): Label
        scaler: 스케일러
        le: 레이블 인코더
        feature_names: Feature 이름 리스트
    """
    logging.info("\n" + "=" * 60)
    logging.info("모델 훈련")
    logging.info("=" * 60)
    
    # Train/Test 분할 (80:20)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, 
        test_size=0.2, 
        random_state=42,
        stratify=y  # 클래스 비율 유지
    )
    
    logging.info(f"Train: {len(X_train):,}개")
    logging.info(f"Test:  {len(X_test):,}개")
    
    # Random Forest 모델
    logging.info("\nRandom Forest 훈련 중...")
    logging.info("  - n_estimators: 100")
    logging.info("  - max_depth: 10")
    logging.info("  - n_jobs: -1 (모든 CPU 사용)")
    
    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=10,
        random_state=42,
        n_jobs=-1,  # 모든 CPU 코어 사용
        verbose=1
    )
    
    model.fit(X_train, y_train)
    
    logging.info("✓ 훈련 완료")
    
    # 평가
    logging.info("\n모델 평가 중...")
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    logging.info(f"\n정확도: {accuracy:.4f} ({accuracy*100:.2f}%)")
    
    # 상세 리포트
    logging.info("\n분류 리포트:")
    report = classification_report(
        y_test, y_pred, 
        target_names=le.classes_,
        digits=4
    )
    print(report)
    
    # 모델 저장
    logging.info("\n" + "=" * 60)
    logging.info("모델 저장")
    logging.info("=" * 60)
    
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    # 1. Random Forest 모델
    model_path = OUTPUT_DIR / 'random_forest_model.joblib'
    joblib.dump(model, model_path)
    logging.info(f"✓ 모델: {model_path}")
    
    # 2. MinMax Scaler
    scaler_path = OUTPUT_DIR / 'min_max_scaler.joblib'
    joblib.dump(scaler, scaler_path)
    logging.info(f"✓ 스케일러: {scaler_path}")
    
    # 3. Label Encoder
    encoder_path = OUTPUT_DIR / 'label_encoder.joblib'
    joblib.dump(le, encoder_path)
    logging.info(f"✓ 인코더: {encoder_path}")
    
    # 4. Feature Names
    features_path = OUTPUT_DIR / 'feature_names.joblib'
    joblib.dump(feature_names, features_path)
    logging.info(f"✓ Feature: {features_path}")
    
    logging.info("\n✅ 모든 파일 저장 완료!")
    
    # 파일 크기 확인
    logging.info("\n파일 크기:")
    for file_path in OUTPUT_DIR.glob('*.joblib'):
        size_mb = file_path.stat().st_size / (1024 * 1024)
        logging.info(f"  {file_path.name}: {size_mb:.2f} MB")


def main():
    """메인 함수"""
    print("=" * 60)
    print("🤖 Random Forest 모델 훈련")
    print("=" * 60)
    print()
    
    try:
        # 1. 데이터 로드
        X, y = load_and_clean_data(DATASET_FILES)
        
        # 2. 전처리
        X_scaled, y_encoded, scaler, le, feature_names = preprocess_features_labels(X, y)
        
        # 3. 훈련 및 저장
        train_and_save_model(X_scaled, y_encoded, scaler, le, feature_names)
        
        print("\n" + "=" * 60)
        print("✅ 훈련 완료!")
        print("=" * 60)
        print()
        print("생성된 파일:")
        print("  - models/random_forest_model.joblib")
        print("  - models/min_max_scaler.joblib")
        print("  - models/label_encoder.joblib")
        print("  - models/feature_names.joblib")
        print()
        print("다음 단계:")
        print("  python flow_receiver.py")
        print()
    
    except Exception as e:
        logging.error(f"\n❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    main()