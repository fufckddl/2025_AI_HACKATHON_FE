class AppConstants {
  // 앱 정보
  static const String appName = '해커톤 프로젝트';
  static const String appVersion = '1.0.0';
  
  // API 관련
  static const String baseUrl = 'http://192.168.100.107:5001';  // 백엔드 Flask 서버 (로컬 네트워크 IP)
  static const int apiTimeout = 30000; // 30초
  
  // UI 관련
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;
  static const double defaultBorderRadius = 8.0;
  
  // 애니메이션 관련
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  // 로컬 스토리지 키
  static const String userTokenKey = 'user_token';
  static const String userInfoKey = 'user_info';
}
