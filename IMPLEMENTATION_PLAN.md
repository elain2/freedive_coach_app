# FreeDive Coach - 기능 구현 계획

**작성일**: 2026-07-09
**버전**: 1.0

---

## 현재 상태

### 완료된 작업

| 구분 | 내용 |
|------|------|
| **프로토타입** | Flutter 앱 기본 구조 (7개 화면, 디자인 시스템) |
| **003-breathing-training** | CO2/O2 테이블 타이머 MVP 완료 |

### 기존 화면 구조

```
lib/
├── screens/
│   ├── home_screen.dart          # 홈 (대시보드)
│   ├── log_timeline_screen.dart  # 로그 타임라인 (목업)
│   ├── new_log_screen.dart       # 새 로그 작성 (목업)
│   ├── coach_screen.dart         # AI 코치 (목업)
│   ├── analysis_screen.dart      # 분석 결과 (목업)
│   ├── training_screen.dart      # 트레이닝 메뉴
│   ├── profile_screen.dart       # 마이 페이지 (목업)
│   ├── breathing_setup_screen.dart     # [신규] 호흡 훈련 설정
│   ├── breathing_timer_screen.dart     # [신규] 호흡 타이머
│   └── breathing_complete_screen.dart  # [신규] 훈련 완료
├── models/
│   ├── breathing_table.dart      # [신규] 호흡 테이블 모델
│   └── training_session.dart     # [신규] 훈련 세션 모델
├── services/
│   ├── table_generator.dart      # [신규] 테이블 생성 서비스
│   ├── timer_service.dart        # [신규] 타이머 상태 머신
│   └── training_storage.dart     # [신규] 로컬 저장소
└── widgets/
    ├── timer_display.dart        # [신규] 타이머 위젯
    └── round_indicator.dart      # [신규] 라운드 표시 위젯
```

---

## 기능 우선순위

| 순위 | 기능 | 상태 | 복잡도 | 의존성 |
|------|------|------|--------|--------|
| 1 | **003 호흡 훈련** | MVP 완료 | 중 | 없음 |
| 2 | **004 다이빙 시뮬레이션** | 미착수 | 중 | 003 타이머 재사용 |
| 3 | **001 스마트 로깅** | 미착수 | 높음 | AI API 연동 |
| 4 | **002 미디어 첨부** | 미착수 | 중 | 001 로그 모델 |
| 5 | **006 로그 타임라인/통계** | 미착수 | 중 | 001, 002 |
| 6 | **005 영상 폼 분석** | 미착수 | 높음 | AI Vision API |

---

## Phase 1: 오프라인 훈련 도구 (완료/진행중)

### 003 호흡 훈련 - CO2/O2 테이블 (완료)

**목표**: 개인 PB 기반 호흡 테이블 자동 생성 및 타이머 훈련

| User Story | 우선순위 | 상태 |
|------------|----------|------|
| US1: CO2 테이블 생성 및 훈련 | P1 | 완료 |
| US2: O2 테이블 생성 및 훈련 | P2 | 완료 |
| US3: 타이머 일시정지/재개/리셋 | P3 | 완료 |
| US4: 훈련 기록 저장 및 조회 | P4 | 완료 |

**구현 완료 항목**:
- BreathingTable, TrainingSession 모델
- TableGenerator (CO2/O2 테이블 자동 생성 알고리즘)
- TimerService (결정론적 상태 머신)
- 타이머 UI (대형 디스플레이, 라운드 표시)
- Keep Awake, 사운드/진동 알림
- 로컬 저장소 (SharedPreferences)

**잔여 작업 (Polish Phase)**:
- [ ] 백그라운드 타이머 지원 강화
- [ ] 훈련 기록 히스토리 화면
- [ ] 통계 대시보드 연동

---

### 004 다이빙 시뮬레이션 (다음 우선순위)

**목표**: 실제 다이브 전 타이밍 리허설을 위한 시각적 시뮬레이션

| User Story | 우선순위 | 예상 작업량 |
|------------|----------|-------------|
| US1: 시뮬레이션 파라미터 설정 | P1 | 중 |
| US2: 시뮬레이션 실행 및 시각화 | P2 | 높음 |
| US3: 시뮬레이션 제어 (일시정지/재개/중단) | P3 | 낮음 |

**핵심 엔티티**:
```dart
// SimulationProfile: 시뮬레이션 설정 프로필
- targetDepth: int (목표 수심, m)
- descentSpeed: double (하강 속도, m/s)
- ascentSpeed: double (상승 속도, m/s)
- freefallStartDepth: int (프리폴 시작 수심)
- freefallSpeed: double (프리폴 속도)
- mouthfillDepth: int (마우스필 수심)

// SimulationSession: 실행 세션
- profile: SimulationProfile
- startedAt: DateTime
- completedAt: DateTime?
- actualDiveTime: Duration
```

**기술 고려사항**:
- 003 TimerService 재사용 (일시정지/재개/리셋)
- 깊이 시각화 애니메이션 (AnimationController)
- 마일스톤 알림 (마우스필, 프리폴, 턴, 수면)
- Keep Awake, 백그라운드 타이머

**예상 파일 구조**:
```
lib/
├── models/
│   ├── simulation_profile.dart
│   └── simulation_session.dart
├── services/
│   └── simulation_service.dart
├── screens/
│   ├── simulation_setup_screen.dart
│   ├── simulation_run_screen.dart
│   └── simulation_complete_screen.dart
└── widgets/
    ├── depth_gauge.dart
    └── diver_animation.dart
```

---

## Phase 2: 스마트 로깅 시스템

### 001 스마트 로깅 (AI 파싱)

**목표**: 자유 형식 텍스트/음성 입력을 AI로 구조화된 로그 필드로 자동 변환

| User Story | 우선순위 | 예상 작업량 |
|------------|----------|-------------|
| US1: 텍스트로 다이빙 로그 작성 | P1 | 높음 |
| US2: 음성으로 다이빙 로그 작성 | P2 | 중 |
| US3: AI 파싱 실패 시 수동 입력 | P3 | 중 |

**핵심 엔티티**:
```dart
// DiveLog: 다이빙 기록
- id: String
- createdAt: DateTime
- date: DateTime (다이빙 날짜)
- location: String (장소)
- discipline: Discipline (CWT/CNF/FIM/DYN/STA)
- depth: int? (수심, m)
- distance: int? (거리, m - DYN용)
- duration: Duration? (시간 - STA용)
- weight: double? (웨이트, kg)
- equipment: String? (장비)
- mouthfillDepth: int? (마우스필 수심)
- freefallDepth: int? (프리폴 수심)
- contractions: String? (컨트랙션)
- condition: String? (컨디션 메모)
- tags: List<String> (태그)
- buddies: List<String> (버디)
- rawInput: String (원본 입력)
- aiParsed: bool (AI 파싱 여부)

// ParsedFields: AI 추출 필드
- fields: Map<String, dynamic>
- confidenceScores: Map<String, double>
```

**기술 고려사항**:
- AI API 연동 (Gemini/Claude API)
- 음성 인식 (speech_to_text 패키지)
- 오프라인 대기열 (AI 파싱 연결 시 수행)
- 신뢰도 기반 UI (70% 미만 하이라이트)
- 임시 저장 (앱 종료 시 복구)

**AI 프롬프트 예시**:
```
다이빙 기록을 구조화된 JSON으로 변환해주세요:
입력: "오늘 제주 협재에서 CWT 28m, 이퀄 타이트했어"

출력:
{
  "date": "2026-07-09",
  "location": "제주 협재",
  "discipline": "CWT",
  "depth": 28,
  "condition": "이퀄 타이트"
}
```

**예상 파일 구조**:
```
lib/
├── models/
│   ├── dive_log.dart
│   ├── parsed_fields.dart
│   └── discipline.dart
├── services/
│   ├── ai_parsing_service.dart
│   ├── speech_service.dart
│   └── log_storage.dart
├── screens/
│   ├── new_log_screen.dart (수정)
│   ├── log_review_screen.dart
│   └── log_detail_screen.dart
└── widgets/
    ├── field_editor.dart
    └── confidence_indicator.dart
```

---

### 002 미디어 첨부

**목표**: 다이빙 로그에 사진/동영상 첨부 및 개별 코멘트

| User Story | 우선순위 | 예상 작업량 |
|------------|----------|-------------|
| US1: 로그에 사진 첨부 | P1 | 중 |
| US2: 미디어에 개별 코멘트 추가 | P2 | 낮음 |
| US3: 로그에 동영상 첨부 | P3 | 중 |
| US4: 타임라인에서 미디어 보기 | P4 | 낮음 |

**핵심 엔티티**:
```dart
// MediaAttachment: 첨부 미디어
- id: String
- logId: String
- type: MediaType (photo/video)
- filePath: String
- thumbnailPath: String
- comment: String?
- order: int
- createdAt: DateTime
```

**기술 고려사항**:
- image_picker 패키지 (갤러리/카메라)
- video_player 패키지
- 썸네일 생성 (video_thumbnail)
- 로컬 파일 관리
- 저장 공간 체크

**의존성**: 001 스마트 로깅 (DiveLog 모델)

---

### 006 로그 타임라인 및 통계

**목표**: 로그 타임라인 조회, 종목별/월별 통계, 성장 그래프

| User Story | 우선순위 | 예상 작업량 |
|------------|----------|-------------|
| US1: 로그 타임라인 조회 | P1 | 중 |
| US2: 종목별/월별 통계 | P2 | 중 |
| US3: 성장 그래프 | P3 | 중 |
| US4: 로그 검색 및 필터 | P4 | 중 |

**기술 고려사항**:
- fl_chart 패키지 (그래프)
- 무한 스크롤 (ListView.builder)
- 로컬 통계 집계
- 검색/필터 인덱스

**의존성**: 001, 002 (로그 및 미디어 데이터)

---

## Phase 3: AI 코칭 기능

### 005 영상 폼 분석

**목표**: 다이빙 영상 업로드 → AI 폼 분석 → 항목별 점수/팁 제공

| User Story | 우선순위 | 예상 작업량 |
|------------|----------|-------------|
| US1: 영상 업로드 및 분석 요청 | P1 | 높음 |
| US2: 분석 결과 확인 | P2 | 중 |
| US3: 분석 결과 저장 및 로그 연결 | P3 | 중 |
| US4: 분석 결과 공유 | P4 | 낮음 |

**핵심 엔티티**:
```dart
// AnalysisRequest
- id: String
- discipline: Discipline
- analysisMode: AnalysisMode (overview/focused)
- videoPath: String
- requestedAt: DateTime

// AnalysisResult
- id: String
- requestId: String
- summary: String
- items: List<AnalysisItem>
- snsCaption: String
- confidenceScore: double
- linkedLogId: String?

// AnalysisItem
- name: String (유선형, 핀킥, 입수/자세, 이완)
- score: int (1-5)
- observation: String
- tip: String
```

**기술 고려사항**:
- AI Vision API (Gemini Vision)
- 영상 업로드/스트리밍
- 결과 이미지 카드 생성
- 공유 기능 (share_plus)

**의존성**: 001 (로그 연결 기능)

---

## 기술 스택 요약

### 의존성 (pubspec.yaml)

```yaml
dependencies:
  # 현재
  flutter: sdk
  google_fonts: ^6.1.0
  audioplayers: ^5.2.1
  vibration: ^1.8.4
  shared_preferences: ^2.2.2
  wakelock_plus: ^1.1.4

  # 추가 예정
  sqflite: ^2.3.0           # 로컬 DB (로그 저장)
  path_provider: ^2.1.1     # 파일 경로
  image_picker: ^1.0.4      # 미디어 선택
  video_player: ^2.8.1      # 동영상 재생
  video_thumbnail: ^0.5.3   # 썸네일 생성
  speech_to_text: ^6.3.0    # 음성 인식
  fl_chart: ^0.65.0         # 차트/그래프
  share_plus: ^7.2.1        # 공유 기능
  http: ^1.1.0              # API 호출
  flutter_dotenv: ^5.1.0    # 환경 변수
```

### 아키텍처

```
┌─────────────────────────────────────────────────────┐
│                    Screens (UI)                      │
├─────────────────────────────────────────────────────┤
│                   Widgets (공통)                     │
├─────────────────────────────────────────────────────┤
│                  Services (비즈니스 로직)            │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │  Timer  │ │   AI    │ │  Media  │ │ Storage │   │
│  │ Service │ │ Service │ │ Service │ │ Service │   │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘   │
├─────────────────────────────────────────────────────┤
│                  Models (데이터)                     │
│  DiveLog, BreathingTable, SimulationProfile, etc.   │
├─────────────────────────────────────────────────────┤
│              Local Storage (SQLite/SharedPrefs)      │
└─────────────────────────────────────────────────────┘
```

---

## 구현 로드맵

### Sprint 1 (현재)
- [x] 003 호흡 훈련 MVP

### Sprint 2
- [ ] 004 다이빙 시뮬레이션
- [ ] 003 호흡 훈련 Polish (히스토리, 통계)

### Sprint 3
- [ ] 001 스마트 로깅 (텍스트 입력)
- [ ] 로컬 DB 마이그레이션 (SQLite)

### Sprint 4
- [ ] 001 스마트 로깅 (음성 입력, AI 연동)
- [ ] 002 미디어 첨부

### Sprint 5
- [ ] 006 로그 타임라인/통계
- [ ] 성장 그래프

### Sprint 6
- [ ] 005 영상 폼 분석
- [ ] 전체 통합 테스트

---

## 다음 단계

**즉시 진행 가능**:
1. 004 다이빙 시뮬레이션 - 003 타이머 인프라 재사용
2. 003 호흡 훈련 히스토리 화면 추가

**AI API 준비 후 진행**:
3. 001 스마트 로깅 - AI 파싱 서비스
4. 005 영상 폼 분석 - Vision API 연동

---

*이 문서는 speckit 워크플로우의 specs/ 디렉토리 내용을 기반으로 작성되었습니다.*
