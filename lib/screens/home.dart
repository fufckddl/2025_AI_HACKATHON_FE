import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import '../constants/app_colors.dart';
import '../routine/routine.dart';
import 'character_selection_screen.dart';
import 'voice_chat_screen.dart';
import '../models/routine_model.dart';
import '../components/routine_detail_popup.dart';
import '../components/bottom_navigation_bar.dart';
import '../components/focus_tools_section.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDrawerOpen = false;

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
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 환영 메시지
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    '안녕하세요, 사용자님 👋',
                  style: TextStyle(
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
                      child: _buildSummaryCard('총 루틴', '21'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard('이번 주 성공 루틴', '20'),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRoutineScreen(),
            ),
          );
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
                  color: AppColors.primary.withValues(alpha: 0.1),
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
                color: Colors.orange.withValues(alpha: 0.1),
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
                  const Text(
                    '이번 주 목표 달성률: 75%',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
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
                    color: Colors.green.withValues(alpha: 0.1),
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
                  child: _buildStatItem('완료된 루틴', '20', Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem('연속 일수', '7', Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem('총 루틴', '21', Colors.purple),
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
        color: color.withValues(alpha: 0.1),
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
    
    // 오늘 해야할 루틴들 (더미 데이터)
    final todayRoutines = [
      {
        'title': '아침 운동',
        'time': '07:00',
        'cycle': '매일',
        'content': '30분 조깅과 스트레칭',
        'isCompleted': false,
      },
      {
        'title': '독서 시간',
        'time': '20:00',
        'cycle': '매일',
        'content': '30분 자기계발서 읽기',
        'isCompleted': true,
      },
      {
        'title': '일기 쓰기',
        'time': '21:00',
        'cycle': '매일',
        'content': '오늘 하루 정리하기',
        'isCompleted': false,
      },
    ];

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
                );
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
        ...todayRoutines.map((routine) => Column(
          children: [
            _buildTodayRoutineItem(
              routine['title'] as String,
              routine['time'] as String,
              routine['cycle'] as String,
              routine['content'] as String,
              routine['isCompleted'] as bool,
            ),
            const SizedBox(height: 12.0),
          ],
        )).toList(),
      ],
    );
  }

  Widget _buildTodayRoutineItem(String title, String time, String cycle, String content, bool isCompleted) {
    // 더미 루틴 모델 생성
    final dummyRoutine = RoutineModel(
      id: 1,
      userId: 1,
      name: title,
      cycle: 1, // 매일
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return InkWell(
      onTap: () {
        RoutineDetailPopup.show(context, dummyRoutine);
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
                  Ionicons.calendar_outline,
                  size: 16.0,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4.0),
                Text(
                  cycle,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              content,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[700],
              ),
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
