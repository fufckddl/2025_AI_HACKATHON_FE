# 2025 AI 해커톤 프로젝트 - 루티(RUTTY)

루틴 관리 Flutter 애플리케이션

## 프로젝트 개요

루티(RUTTY)는 개인의 일상 루틴을 체계적으로 관리하고 목표를 달성할 수 있도록 도와주는 Flutter 기반 모바일 애플리케이션입니다.

## 주요 기능

- 🏠 **홈화면**: 모던한 디자인의 대시보드
- 👤 **마이페이지**: 사용자 정보 및 설정 관리
- 📅 **루틴 관리**: 루틴 목록 및 생성 기능
- 🔐 **인증 시스템**: 로그인/회원가입 페이지
- 🎨 **통일된 디자인**: IonIcons 사용으로 일관된 UI/UX

## 기술 스택

- **Frontend**: Flutter
- **Language**: Dart
- **Icons**: IonIcons
- **Platform**: iOS, Android, Web

## 프로젝트 구조

```
lib/
├── auth/           # 인증 관련 페이지
├── constants/      # 앱 상수 및 색상
├── info/           # 마이페이지
├── models/         # 데이터 모델
├── routine/        # 루틴 관리 페이지
├── screens/       # 메인 화면
├── services/       # API 서비스
└── widgets/        # 재사용 가능한 위젯
```

## 시작하기

1. Flutter SDK 설치
2. 프로젝트 클론
3. 의존성 설치: `flutter pub get`
4. 앱 실행: `flutter run`

## 개발 환경

- Flutter 3.x
- Dart 3.x
- iOS 16 Pro 시뮬레이터 지원
- iPhone 최적화 UI/UX
