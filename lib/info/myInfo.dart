import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../components/bottom_navigation_bar.dart';
import '../screens/character_selection_screen.dart';
import '../screens/coaching_report_screen.dart';
import '../screens/routine_success_screen.dart';
import '../services/api_service.dart';

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  String _userName = '사용자';
  String _userEmail = 'email@example.com';
  int _totalRoutines = 0;
  int _completedRoutines = 0;
  double _completionRate = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        print('❌ 사용자 ID가 없습니다.');
        return;
      }

      // /home/<user_id> API 호출
      final response = await ApiService().get('/home/$userId');

      if (response['result'] == 'success' && response['data'] != null) {
        final data = response['data'];
        final weeklyStats = data['이번 주 통계'] as Map<String, dynamic>?;

        setState(() {
          _userName = data['name'] ?? '사용자';
          _userEmail = prefs.getString('email') ?? 'email@example.com';
          _totalRoutines = data['총 루틴 수'] ?? 0;
          _completedRoutines = weeklyStats?['완료 루틴 수'] ?? 0;
          _completionRate = _totalRoutines > 0 
              ? (_completedRoutines / _totalRoutines * 100) 
              : 0.0;
        });
      }
    } catch (e) {
      print('❌ 사용자 데이터 로드 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 프로필 헤더 섹션
              _buildProfileHeader(),
              
              // 통계 카드들
              _buildStatsCards(),
              
              const SizedBox(height: 20),
              
              // 구독 플랜 섹션
              //_buildSubscriptionPlan(),
              
              const SizedBox(height: 20),
              
              // 바로가기 섹션
              _buildShortcutsSection(),
              
              const SizedBox(height: 20),
              
              // 계정 관리 섹션
              _buildAccountManagementSection(),
              
              const SizedBox(height: 20),
              
              // 업적 섹션
              //_buildAchievementsSection(),
              
              const SizedBox(height: 20),
              
              // 환경 설정 섹션
              _buildEnvironmentSettingsSection(),
              
              const SizedBox(height: 20),
              
              // 지원 및 정보 섹션
              _buildSupportSection(),
              
              const SizedBox(height: 20),
              
              // 로그아웃 버튼
              _buildLogoutButton(),
              
              const SizedBox(height: 20),
              
              // 계정 삭제
              _buildDeleteAccountButton(),
              
              const SizedBox(height: 100), // 하단 네비게이션 바 공간
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 5),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // 프로필 이미지
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Text(
                  _userName.isNotEmpty ? _userName[0] : '사',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(
                    Ionicons.camera_outline,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 사용자 이름
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // 이메일
          Text(
            _userEmail,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Ionicons.calendar_outline,
              value: '$_totalRoutines',
              label: '루틴',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Ionicons.checkmark_circle_outline,
              value: '${_completionRate.toStringAsFixed(0)}%',
              label: '완료율',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

 /* Widget _buildSubscriptionPlan() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Ionicons.diamond_outline, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Plus 플랜',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              const Text(
                '관리 >',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            '이번 달 사용량',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 진행률 바
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.3, // 15/50
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '15시간 / 50시간',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Text(
                '다음 결제일: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const Text(
                '2025.11.19',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Switch(
                value: false,
                onChanged: (value) {},
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }*/

  Widget _buildShortcutsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '바로가기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShortcutCard(
                  icon: Ionicons.document_text_outline,
                  label: '코칭 리포트',
                  color: Colors.orange,
                  badge: '1',
                  badgeColor: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CoachingReportScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShortcutCard(
                  icon: Ionicons.people_circle_outline,
                  label: '캐릭터',
                  color: Colors.purple,
                  badge: '5',
                  badgeColor: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CharacterSelectionScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShortcutCard(
                  icon: Ionicons.checkmark_circle_outline,
                  label: '루틴 완료',
                  color: Colors.green,
                  badge: '',
                  badgeColor: Colors.transparent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoutineSuccessScreen(),
                      ),
                    );
                  },
                ),
              ),
              /*const SizedBox(width: 12),
              Expanded(
                child: _buildShortcutCard(
                  icon: Ionicons.pricetag_outline,
                  label: '태그',
                  color: Colors.green,
                  badge: '24',
                  badgeColor: AppColors.primary,
                  onTap: null,
                ),
              ),*/
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String label,
    required Color color,
    required String badge,
    required Color badgeColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountManagementSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '계정 관리',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Ionicons.person_outline,
            title: '프로필 수정',
            color: AppColors.primary,
          ),
          /*_buildMenuItem(
            icon: Ionicons.card_outline,
            title: '구독 변경',
            subtitle: 'Plus',
            color: Colors.purple,
            badge: 'Plus',
            badgeColor: AppColors.primary,
          ),*/
          _buildMenuItem(
            icon: Ionicons.notifications_outline,
            title: '알림 설정',
            subtitle: 'ON',
            color: AppColors.primary,
          ),
          /*_buildMenuItem(
            icon: Ionicons.shield_checkmark_outline,
            title: '보안',
            color: Colors.green,
          ),*/
          /*_buildMenuItem(
            icon: Ionicons.link_outline,
            title: '연동 관리',
            subtitle: '2개 연동됨',
            color: Colors.grey,
          ),*/
        ],
      ),
    );
  }

  /*Widget _buildAchievementsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '업적',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAchievementCard(
                  icon: Ionicons.sparkles_outline,
                  title: '첫 루틴',
                  date: '2025.01.15',
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAchievementCard(
                  icon: Ionicons.trophy_outline,
                  title: '10회 달성',
                  date: '2025.02.10',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAchievementCard(
                  icon: Ionicons.diamond_outline,
                  title: '월간 왕',
                  date: '2025.03.01',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }*/


  Widget _buildEnvironmentSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '환경 설정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          /*_buildMenuItem(
            icon: Ionicons.musical_notes_outline,
            title: '음성 품질',
            subtitle: '고품질 >',
            color: AppColors.primary,
          ),
          _buildMenuItem(
            icon: Ionicons.folder_outline,
            title: '저장 위치',
            subtitle: '기기 >',
            color: Colors.grey,
          ),*/
          _buildMenuItem(
            icon: Ionicons.globe_outline,
            title: '언어',
            subtitle: '한국어 >',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '지원 및 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Ionicons.help_circle_outline,
            title: '도움말',
            color: AppColors.primary,
          ),
          /*_buildMenuItem(
            icon: Ionicons.chatbubble_outline,
            title: '문의하기',
            color: AppColors.primary,
          ),
          _buildMenuItem(
            icon: Ionicons.megaphone_outline,
            title: '공지사항',
            color: Colors.orange,
            badge: 'New',
            badgeColor: Colors.red,
          ),*/
          _buildMenuItem(
            icon: Ionicons.information_circle_outline,
            title: '앱 정보',
            subtitle: 'v1.2.3 >',
            color: Colors.grey,
          ),
          /*_buildMenuItem(
            icon: Ionicons.document_text_outline,
            title: '이용약관',
            color: Colors.grey,
          ),
          _buildMenuItem(
            icon: Ionicons.lock_closed_outline,
            title: '개인정보처리방침',
            color: Colors.grey,
          ),*/
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(
            Ionicons.chevron_forward,
            color: Colors.grey,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _showLogoutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.log_out_outline,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              '로그아웃',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton(
        onPressed: _showDeleteAccountDialog,
        child: const Text(
          '계정 삭제',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }


  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말로 로그아웃하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('계정 삭제'),
          content: const Text('정말로 계정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                // 계정 삭제 로직
              },
            ),
          ],
        );
      },
    );
  }
}