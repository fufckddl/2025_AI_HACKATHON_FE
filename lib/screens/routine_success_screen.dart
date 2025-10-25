import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';

class RoutineSuccessScreen extends StatefulWidget {
  const RoutineSuccessScreen({super.key});

  @override
  State<RoutineSuccessScreen> createState() => _RoutineSuccessScreenState();
}

class _RoutineSuccessScreenState extends State<RoutineSuccessScreen> {
  List<Map<String, dynamic>> _todayRoutines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayRoutines();
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
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        print('❌ 사용자 ID가 없습니다.');
        return;
      }

      final response = await ApiService().get('/home/$userId');

      if (response['result'] == 'success' && response['data'] != null) {
        final data = response['data'];
        final routines = data['오늘의 루틴'] as List<dynamic>?;

        if (routines != null) {
          setState(() {
            _todayRoutines = routines.map((routine) {
              final timeStr = routine['time'] ?? '00:00:00';
              final timeParts = timeStr.split(':');
              final formattedTime = '${timeParts[0]}:${timeParts[1]}';

              // 날짜 파싱 (routine_time에서 date 추출)
              final routineTime = routine['routine_time'] ?? '';
              String formattedDate = '';
              try {
                final timeStr = routineTime.toString();
                if (timeStr.isNotEmpty && timeStr.length >= 10) {
                  formattedDate = timeStr.substring(0, 10); // "YYYY-MM-DD"
                  print('📅 날짜 파싱: $formattedDate (원본: $routineTime)');
                }
              } catch (e) {
                print('⚠️ 날짜 파싱 실패: $e (routine_time: $routineTime)');
              }

              return {
                'id': routine['id'],
                'name': routine['routine_name'] ?? '',
                'content': routine['routine_content'] ?? '',
                'time': formattedTime,
                'date': formattedDate,
                'is_success': routine['is_success'] ?? 0,
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('❌ 루틴 로드 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRoutineSuccess(int routineId, int currentStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        return;
      }

      final newStatus = currentStatus == 1 ? 0 : 1;

      final response = await ApiService().put('/routines/$routineId/success', {
        'is_success': newStatus,
      });

      if (response['result'] == 'success') {
        // 성공 상태 업데이트 후 페이지 새로고침
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 1 ? '루틴을 완료했습니다! 🎉' : '루틴 완료를 취소했습니다.'),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 페이지 새로고침
        _loadTodayRoutines();
      }
    } catch (e) {
      print('❌ 루틴 성공 상태 변경 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          '루틴 성공 처리',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todayRoutines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '오늘 루틴이 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTodayRoutines,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _todayRoutines.length,
                    itemBuilder: (context, index) {
                      final routine = _todayRoutines[index];
                      final isCompleted = routine['is_success'] == 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: CheckboxListTile(
                          value: isCompleted,
                          onChanged: (value) {
                            _toggleRoutineSuccess(routine['id'], routine['is_success']);
                          },
                          title: Text(
                            routine['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              // 날짜와 시간 표시
                              Row(
                                children: [
                                  Icon(Ionicons.calendar_outline, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    routine['date']?.toString().isNotEmpty == true ? routine['date'] : '날짜 없음',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: routine['date']?.toString().isNotEmpty == true ? FontWeight.normal : FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Ionicons.time_outline, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    routine['time'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              if (routine['content'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  routine['content'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
