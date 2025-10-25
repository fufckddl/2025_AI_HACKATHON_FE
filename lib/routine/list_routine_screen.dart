import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/routine_model.dart';
import '../widgets/custom_button.dart';
import 'create_routine_screen.dart';
import '../components/routine_detail_popup.dart';
import '../services/api_service.dart';

class ListRoutineScreen extends StatefulWidget {
  const ListRoutineScreen({super.key});

  @override
  State<ListRoutineScreen> createState() => _ListRoutineScreenState();
}

class _ListRoutineScreenState extends State<ListRoutineScreen> {
  List<RoutineModel> _routines = [];
  List<RoutineModel> _allRoutines = []; // 모든 루틴 저장
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 다른 페이지에서 돌아왔을 때 데이터 새로고침
    final ModalRoute? route = ModalRoute.of(context);
    if (route?.isCurrent == true) {
      _loadRoutines();
    }
  }

  // HTTP 날짜 형식을 파싱하는 헬퍼 함수
  DateTime _parseHttpDate(String dateStr) {
    try {
      // MySQL datetime 형식: "2025-10-25 20:28:31"
      if (dateStr.contains('-') && dateStr.contains(':') && dateStr.contains(' ')) {
        return DateTime.parse(dateStr);
      }
      
      // HTTP date 형식: "Sat, 25 Oct 2025 20:28:31 GMT"
      if (dateStr.contains(',')) {
        final parts = dateStr.split(',');
        if (parts.length >= 2) {
          final datePart = parts[1].trim();
          final dateComponents = datePart.split(' ');
          
          if (dateComponents.length >= 4) {
            final day = dateComponents[0].padLeft(2, '0');
            final monthMap = {
              'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
              'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
              'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
            };
            final month = monthMap[dateComponents[1]] ?? '01';
            final year = dateComponents[2];
            final time = dateComponents[3];
            
            final formattedDate = '$year-$month-$day $time';
            return DateTime.parse(formattedDate);
          }
        }
      }
      
      // 기본 파싱 시도
      return DateTime.parse(dateStr);
    } catch (e) {
      print('⚠️ 날짜 파싱 실패: $dateStr - $e');
      return DateTime.now();
    }
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 ID 가져오기
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId == null) {
        print('❌ 사용자 ID가 없습니다.');
        return;
      }

      // /routines/user/<user_id> API 호출 (전체 루틴 조회)
      final response = await ApiService().get('/routines/user/$userId');
      
      if (response['result'] == 'success' && response['data'] != null) {
        final routines = response['data'] as List<dynamic>?;
        
        if (routines != null) {
          print('📋 전체 루틴 개수: ${routines.length}');
          
          setState(() {
            _routines = routines.map((routine) {
              // routine_time 파싱
              DateTime routineDateTime = DateTime.now();
              if (routine['routine_time'] != null) {
                if (routine['routine_time'] is String) {
                  routineDateTime = _parseHttpDate(routine['routine_time'] as String);
                } else if (routine['routine_time'] is DateTime) {
                  routineDateTime = routine['routine_time'] as DateTime;
                }
              }
              
              // created_at 파싱
              DateTime createdAt = DateTime.now();
              if (routine['created_at'] != null) {
                if (routine['created_at'] is String) {
                  createdAt = _parseHttpDate(routine['created_at'] as String);
                } else if (routine['created_at'] is DateTime) {
                  createdAt = routine['created_at'] as DateTime;
                }
              }
              
              // updated_at 파싱
              DateTime updatedAt = DateTime.now();
              if (routine['updated_at'] != null) {
                if (routine['updated_at'] is String) {
                  updatedAt = _parseHttpDate(routine['updated_at'] as String);
                } else if (routine['updated_at'] is DateTime) {
                  updatedAt = routine['updated_at'] as DateTime;
                }
              }
              
              final routineContent = routine['routine_content'] ?? '';
              print('⏰ 루틴: ${routine['routine_name']}, 시간: $routineDateTime, content: $routineContent');
              
              return RoutineModel(
                id: routine['id'] ?? 0,
                userId: userId,
                name: routine['routine_name'] ?? '',
                cycle: 1,
                content: routineContent,
                createdAt: createdAt,
                updatedAt: updatedAt,
                routineTime: routineDateTime,
              );
            }).toList();
            
            _allRoutines = List<RoutineModel>.from(_routines);
            
            print('✅ 전체 루틴 로드 완료: ${_routines.length}개');
          });
        } else {
          print('❌ routines가 null입니다.');
          setState(() {
            _routines = [];
            _allRoutines = [];
          });
        }
      }
    } catch (e) {
      print('❌ 루틴 목록 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('루틴 목록을 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
            const Text(
              '루틴 목록',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh_outline, color: Colors.black),
            onPressed: _loadRoutines,
          ),
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _routines.isEmpty
              ? _buildEmptyState()
              : _buildRoutineList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRoutineScreen(),
            ),
          );
          
          if (result == true) {
            _loadRoutines();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '등록된 루틴이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 루틴을 만들어보세요!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: '루틴 생성하기',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRoutineScreen(),
                ),
              );
              
              if (result == true) {
                _loadRoutines();
              }
            },
            backgroundColor: AppColors.primary,
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineList() {
    return RefreshIndicator(
      onRefresh: _loadRoutines,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return _buildRoutineCard(routine);
        },
      ),
    );
  }

  Widget _buildRoutineCard(RoutineModel routine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () {
          _showRoutineDetails(routine);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Ionicons.calendar_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      routine.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Icon(
                    Ionicons.chevron_forward,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  const Icon(
                    Ionicons.time_outline,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${routine.routineTime.month}/${routine.routineTime.day} ${routine.routineTime.hour.toString().padLeft(2, '0')}:${routine.routineTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                routine.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoutineDetails(RoutineModel routine) {
    RoutineDetailPopup.show(
      context,
      routine,
      onDelete: () => _deleteRoutine(routine),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem(String minutes, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              minutes,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(RoutineModel routine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '루틴 삭제',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '정말로 "${routine.name}" 루틴을 삭제하시겠습니까?\n\n삭제된 루틴은 복구할 수 없습니다.',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRoutine(routine);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '삭제',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteRoutine(RoutineModel routine) async {
    try {
      // API 호출로 루틴 삭제
      final response = await ApiService().delete('/routines/${routine.id}/delete');
      
      if (response['result'] == 'success') {
        setState(() {
          _routines.removeWhere((r) => r.id == routine.id);
          _allRoutines.removeWhere((r) => r.id == routine.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${routine.name} 루틴이 삭제되었습니다.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['msg'] ?? '루틴 삭제에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasRoutineOptions(RoutineModel routine) {
    // 더미 로직: 실제로는 루틴 모델에서 옵션 정보를 가져와야 함
    // 예시: routine.id가 1인 경우에만 옵션이 있다고 가정
    return routine.id == 1;
  }
}
