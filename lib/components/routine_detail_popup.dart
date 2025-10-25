import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../constants/app_colors.dart';
import '../models/routine_model.dart';
import '../routine/create_routine_screen.dart';
import '../services/api_service.dart';

class RoutineDetailPopup {
  static void show(
    BuildContext context,
    RoutineModel routine, {
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RoutineDetailPopupContent(
        routine: routine,
        onDelete: onDelete,
      ),
    );
  }
}

class _RoutineDetailPopupContent extends StatefulWidget {
  final RoutineModel routine;
  final VoidCallback? onDelete;
  
  const _RoutineDetailPopupContent({
    required this.routine,
    this.onDelete,
  });
  
  @override
  State<_RoutineDetailPopupContent> createState() => _RoutineDetailPopupContentState();
}

class _RoutineDetailPopupContentState extends State<_RoutineDetailPopupContent> {
  bool _isLoading = true;
  Map<String, dynamic>? _routineData;
  List<Map<String, dynamic>> _options = [];
  
  @override
  void initState() {
    super.initState();
    _loadRoutineDetail();
  }
  
  Future<void> _loadRoutineDetail() async {
    try {
      // /routines/<routine_id> API 호출
      final response = await ApiService().get('/routines/${widget.routine.id}');
      
      if (response['result'] == 'success' && response['data'] != null) {
        setState(() {
          _routineData = response['data']['routine'];
          _options = List<Map<String, dynamic>>.from(response['data']['options'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 루틴 상세 정보 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
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
                          _routineData?['routine_name'] ?? widget.routine.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: '생성일',
                    value: _routineData?['created_at'] != null
                        ? _formatDate(_routineData!['created_at'])
                        : '${widget.routine.createdAt.year}.${widget.routine.createdAt.month}.${widget.routine.createdAt.day}',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildDetailRow(
                    icon: Icons.update,
                    label: '수정일',
                    value: _routineData?['updated_at'] != null
                        ? _formatDate(_routineData!['updated_at'])
                        : '${widget.routine.updatedAt.year}.${widget.routine.updatedAt.month}.${widget.routine.updatedAt.day}',
                  ),
                  
                  // 루틴 옵션 섹션 (옵션이 있는 경우에만 표시)
                  if (_options.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '루틴 옵션',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 실제 옵션 데이터 표시
                    ..._options.map((option) => Column(
                      children: [
                        _buildOptionItem(
                          '${option['minutes']}분전',
                          option['text'] ?? '',
                        ),
                        const SizedBox(height: 8),
                      ],
                    )),
                  ],
                  
                  if (_routineData?['routine_content'] != null && _routineData!['routine_content'].toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '내용',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _routineData!['routine_content'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  
                  // 액션 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // 팝업창 닫기
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateRoutineScreen(
                                  routineToEdit: widget.routine,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Ionicons.create_outline, size: 20),
                          label: const Text('수정'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showDeleteConfirmDialog(context, widget.routine, widget.onDelete);
                          },
                          icon: const Icon(Ionicons.trash_outline, size: 20),
                          label: const Text('삭제'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  String _formatDate(String dateStr) {
    try {
      // MySQL timestamp 형식: '2025-10-25 17:07:35' 또는 HTTP date 형식 등
      if (dateStr.contains(',')) {
        // HTTP date 형식: 'Sat, 25 Oct 2025 17:07:35 GMT'
        // 간단히 공백으로 split하여 날짜 부분만 추출
        final parts = dateStr.split(' ');
        if (parts.length >= 4) {
          // 월 이름을 숫자로 변환
          final monthMap = {
            'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
            'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
            'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
          };
          final day = parts[1].padLeft(2, '0');
          final month = monthMap[parts[2]] ?? '01';
          final year = parts[3];
          return '$year-$month-$day';
        }
      }
      // '2025-10-25 17:07:35' 형식인 경우
      return dateStr.split(' ')[0];
    } catch (e) {
      return dateStr;
    }
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    RoutineModel routine,
    VoidCallback? onDelete,
  ) {
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                if (!isDeleting)
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
                  onPressed: isDeleting ? null : () async {
                    setState(() {
                      isDeleting = true;
                    });

                                         try {
                       // API 호출로 루틴 삭제
                       final response = await ApiService().delete('/routines/${routine.id}/delete');

                      if (response['result'] == 'success') {
                        // 다이얼로그 닫기
                        Navigator.of(context).pop();

                        // 팝업창 닫기
                        Navigator.of(context).pop();

                        // 콜백 호출 (화면 새로고침)
                        if (onDelete != null) {
                          onDelete();
                        }

                        // 성공 메시지 표시
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${routine.name} 루틴이 삭제되었습니다.'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        setState(() {
                          isDeleting = false;
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response['msg'] ?? '루틴 삭제에 실패했습니다.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      setState(() {
                        isDeleting = false;
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('오류가 발생했습니다: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
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
      },
    );
  }
}
