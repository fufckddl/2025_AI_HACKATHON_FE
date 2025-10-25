import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../routine/routine.dart';
import 'character_selection_screen.dart';
import 'voice_chat_screen.dart';
import '../models/routine_model.dart';
import '../components/routine_detail_popup.dart';
import '../components/bottom_navigation_bar.dart';
import '../components/focus_tools_section.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDrawerOpen = false;
  List<Map<String, dynamic>> _todayRoutines = [];
  bool _isLoadingRoutines = false;
  int _totalRoutines = 0;
  int _weeklySuccessRoutines = 0;
  int _completedRoutines = 0;
  int _streakDays = 0;
  String _userName = '사용자'; // 기본값
  double _goalAchievementRate = 0.0; // 목표 달성률 (0-1)
  int? _userId; // 현재 사용자 ID

  @override
  void initState() {
    super.initState();
    _loadTodayRoutines();
    // 페이지가 포커스를 받을 때마다 데이터 새로고침
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 다른 페이지에서 돌아왔을 때 데이터 새로고침
    final ModalRoute? route = ModalRoute.of(context);
    if (route?.isCurrent == true) {
      _loadTodayRoutines();
    }
  }

  Future<void> _loadTodayRoutines() async {
    setState(() {
      _isLoadingRoutines = true;
    });

    try {
      // 사용자 ID 가져오기
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId == null) {
        print('❌ 사용자 ID가 없습니다.');
        return;
      }

      // userId를 상태 변수에 저장
      setState(() {
        _userId = userId;
      });

      // /home/<user_id> API 호출
      final response = await ApiService().get('/home/$userId');
      
      if (response['result'] == 'success' && response['data'] != null) {
        final data = response['data'];
        
        // 통계 데이터 업데이트
        final weeklyStats = data['이번 주 통계'] as Map<String, dynamic>?;
        final successCount = data['이번 주 성공 루틴 수'] ?? 0;
        final totalCount = data['총 루틴 수'] ?? 1; // 0으로 나누기 방지
        
        setState(() {
          _userName = data['name'] ?? '사용자';
          _totalRoutines = totalCount;
          _weeklySuccessRoutines = successCount;
          _completedRoutines = weeklyStats?['완료 루틴 수'] ?? 0;
          _streakDays = weeklyStats?['연속 일수'] ?? 0;
          // 목표 달성률 = 성공 루틴 수 / 총 루틴 수
          _goalAchievementRate = totalCount > 0 ? successCount / totalCount : 0.0;
        });
        
        final todayRoutines = data['오늘의 루틴'] as List<dynamic>?;
        
        if (todayRoutines != null && todayRoutines.isNotEmpty) {
          setState(() {
            _todayRoutines = todayRoutines.map((routine) {
              // 시간을 hh:mm 형식으로 변환 (예: "09:30:00" -> "09:30")
              final timeStr = routine['time'] ?? '00:00:00';
              final timeParts = timeStr.split(':');
              final formattedTime = '${timeParts[0]}:${timeParts[1]}';
              
              return {
                'id': routine['id'], // 루틴 ID 추가
                'title': routine['routine_name'] ?? '',
                'time': formattedTime,
                'optionCount': routine['option_count'] ?? 0,
                'isCompleted': routine['is_success'] == 1,
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('❌ 오늘의 루틴 로드 실패: $e');
    } finally {
      setState(() {
        _isLoadingRoutines = false;
      });
    }
  }

  // 테스트 알림
  Future<void> _testNotification() async {
    try {
      print('🔔 테스트 알림 버튼 클릭됨');
      
      // 알림 서비스 사용
      final notificationService = NotificationService();
      
      // 알림 권한 확인
      final hasPermission = await notificationService.requestPermissions();
      print('🔔 알림 권한 상태: $hasPermission');
      
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알림 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // 10초 후 알림 예약
      print('🔔 10초 후 알림 예약 요청');
      
      await notificationService.scheduleTestIn10s();
      
      print('✅ 10초 후 알림 예약 처리 완료');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('10초 후 테스트 알림이 발송됩니다.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('❌ 알림 발송 실패: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 발송 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 8),
            const Text(
              '루티(ROUTY)',
            style: TextStyle(
            fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xffffffff),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Ionicons.menu, color: Colors.black),
          onPressed: () {
            setState(() {
              _isDrawerOpen = !_isDrawerOpen;
            });
          },
        ),
                actions: [
                  IconButton(
                    icon: const Icon(Ionicons.notifications_outline, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Ionicons.flash_outline, color: Colors.blue),
                    tooltip: '테스트 알림',
                    onPressed: _testNotification,
                  ),
                ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: Stack(
        children: [
          // 메인 콘텐츠
          RefreshIndicator(
            onRefresh: _loadTodayRoutines,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 환영 메시지
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    '안녕하세요, $_userName님 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                
                // 요약 카드들
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard('총 루틴', '$_totalRoutines'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard('이번 주 성공 루틴', '$_weeklySuccessRoutines'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // 루틴 관리 카드
                _buildRoutineCard(),
                
                const SizedBox(height: 30),
                
                // 목표 달성 카드
                _buildGoalCard(),
                
                const SizedBox(height: 30),
                
                // 통계 카드
                _buildStatsCard(),
                
                const SizedBox(height: 30),
                
                // 집중력 유지 도구 섹션
                const FocusToolsSection(),
                
                const SizedBox(height: 30),
                
                // 오늘 루틴 섹션
                _buildRecentRoutinesSection(),
              ],
              ),
            ),
          ),
          
          // 사이드 드로어
          if (_isDrawerOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    _buildDrawerItem(
                      icon: Ionicons.home_outline,
                      title: '홈',
                      isSelected: true,
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                      },
                    ),
                    _buildDrawerItem(
                      icon: Ionicons.calendar_outline,
                      title: '루틴 관리',
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                            builder: (context) => const ListRoutineScreen(),
                      ),
                    );
                  },
                    ),
                    _buildDrawerItem(
                      icon: Ionicons.people_outline,
                      title: '캐릭터 선택',
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CharacterSelectionScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Ionicons.mic_outline,
                      title: '음성 대화',
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VoiceChatScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Ionicons.trophy_outline,
                      title: '목표 달성',
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                      },
                    ),
                    _buildDrawerItem(
                      icon: Ionicons.stats_chart_outline,
                      title: '통계',
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                      },
                    ),
                    _buildDrawerItem(
                      icon: Ionicons.settings_outline,
                      title: '설정',
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                      },
                    ),
                    _buildDrawerItem(
                      icon: Ionicons.help_circle_outline,
                      title: '도움말',
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                      },
                ),
              ],
            ),
          ),
        ),
        ],
      ),
              bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 루틴 생성 화면으로 이동하고 결과 받기
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRoutineScreen(),
            ),
          );
          
          // 루틴이 성공적으로 생성되면 화면 새로고침
          if (result == true) {
            _loadTodayRoutines();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRoutineCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ListRoutineScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Ionicons.calendar_outline,
                  color: AppColors.primary,
                  size: 32.0,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '루틴 관리',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      '일상 루틴을 체계적으로 관리하고 목표를 달성해보세요.',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        const Icon(
                          Ionicons.arrow_forward_outline,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '루틴 목록 보기',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(
                Ionicons.trophy_outline,
                color: Colors.orange,
                size: 32.0,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '목표 달성률',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '이번 주 목표 달성률: ${(_goalAchievementRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  LinearProgressIndicator(
                    value: _goalAchievementRate.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _goalAchievementRate >= 0.8 ? Colors.green : 
                      _goalAchievementRate >= 0.5 ? Colors.orange : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Ionicons.stats_chart_outline,
                    color: Colors.green,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                const Text(
                  '이번 주 통계',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('성공한 루틴', '$_completedRoutines', Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem('연속 일수', '$_streakDays', Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem('총 루틴', '$_totalRoutines', Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.0,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRoutinesSection() {
    // 오늘 날짜 계산
    final now = DateTime.now();
    final today = '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘 루틴',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  today,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListRoutineScreen(),
                  ),
                ).then((_) {
                  // 루틴 목록 페이지에서 돌아왔을 때 오늘의 루틴 새로고침
                  _loadTodayRoutines();
                });
              },
              child: const Text(
                '전체보기 >',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        if (_isLoadingRoutines)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_todayRoutines.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Ionicons.calendar_clear_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    '오늘 루틴이 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._todayRoutines.asMap().entries.map((entry) {
            final index = entry.key;
            final routine = entry.value;
            return Column(
              children: [
                _buildTodayRoutineItem(
                  routine['title'] as String,
                  routine['time'] as String,
                  routine['optionCount'] as int,
                  routine['isCompleted'] as bool,
                  routine['id'] as int? ?? index + 1,
                  _userId ?? 0,
                ),
                const SizedBox(height: 12.0),
              ],
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTodayRoutineItem(String title, String time, int optionCount, bool isCompleted, int routineId, int userId) {
    // 루틴 모델 생성
    // time을 DateTime으로 변환 (시간 문자열 "HH:MM" 형태)
    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final routineTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    final routine = RoutineModel(
      id: routineId,
      userId: userId,
      name: title,
      cycle: 1, // 매일 (주기는 사용하지 않지만 필수 필드이므로 기본값 설정)
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      routineTime: routineTime,
    );

    return InkWell(
      onTap: () {
        RoutineDetailPopup.show(
          context,
          routine,
          onDelete: () {
            // 삭제 후 화면 새로고침
            _loadTodayRoutines();
          },
        );
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (isCompleted)
                  Row(
                    children: [
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Icon(
                  Ionicons.time_outline,
                  size: 16.0,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4.0),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16.0),
                Icon(
                  Ionicons.list_outline,
                  size: 16.0,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4.0),
                Text(
                  '옵션: $optionCount',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineItem(String title, String date, String duration, List<String> tags, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              if (isCompleted)
                Row(
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    const Text(
                      '완료',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              const Icon(Ionicons.calendar_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4.0),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 16.0),
              const Icon(Ionicons.time_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4.0),
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 8.0,
            children: tags.map((tag) => _buildTag(tag)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    Color backgroundColor;
    switch (text) {
      case '예산':
      case '제품':
      case '개발':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        break;
      case '마케팅':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        break;
      case '전략':
        backgroundColor = Colors.yellow.withValues(alpha: 0.1);
        break;
      case '스탠드업':
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.0,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }



}
