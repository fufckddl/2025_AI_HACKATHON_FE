import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../constants/app_colors.dart';
import '../auth/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 페이드 인 애니메이션
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // 스케일 애니메이션
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // 애니메이션 시작
    _animationController.forward();

    // 3초 후 인증 화면으로 이동
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 화면 크기에 따라 이미지 크기 조정
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // routty.png 이미지 사용
                          Container(
                            width: screenWidth * 0.9, // 화면 너비의 90%
                            height: screenHeight * 0.8, // 화면 높이의 80%
                            constraints: BoxConstraints(
                              maxWidth: 600, // 최대 너비 제한
                              maxHeight: 800, // 최대 높이 제한
                            ),
                            child: Image.asset(
                              'assets/images/routty.png',
                              fit: BoxFit.contain, // 이미지 비율 유지하며 컨테이너에 맞춤
                              errorBuilder: (context, error, stackTrace) {
                                // 이미지 로드 실패 시 대체 UI
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.image_not_supported,
                                      size: 100,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      '이미지를 불러올 수 없습니다',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // 대체 텍스트와 버튼
                                    const Text(
                                      '소아 ADHD 아동 일상·수면 관리 및 부모 지원 플랫폼',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primary.withValues(alpha: 0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: const Text(
                                        'Routy',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(builder: (context) => const AuthScreen()),
                                        );
                                      },
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.withValues(alpha: 0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Ionicons.play,
                                          color: Colors.grey.withValues(alpha: 0.6),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // 로딩 인디케이터
                          SizedBox(
                            width: screenWidth * 0.05,
                            height: screenWidth * 0.05,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}