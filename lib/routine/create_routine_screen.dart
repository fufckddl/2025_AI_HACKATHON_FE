import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/routine_model.dart';
import '../widgets/custom_button.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class CreateRoutineScreen extends StatefulWidget {
  final RoutineModel? routineToEdit;
  
  const CreateRoutineScreen({super.key, this.routineToEdit});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  
  bool _isLoading = false;
  
  // 옵션 관리
  List<Map<String, dynamic>> _options = [];
  
  @override
  void initState() {
    super.initState();
    
    // 수정 모드일 때 기존 데이터 로드
    if (widget.routineToEdit != null) {
      _nameController.text = widget.routineToEdit!.name;
      _contentController.text = widget.routineToEdit!.content;
      _dateController.text = '${widget.routineToEdit!.createdAt.year}-${widget.routineToEdit!.createdAt.month.toString().padLeft(2, '0')}-${widget.routineToEdit!.createdAt.day.toString().padLeft(2, '0')}';
      _timeController.text = '${widget.routineToEdit!.createdAt.hour.toString().padLeft(2, '0')}:${widget.routineToEdit!.createdAt.minute.toString().padLeft(2, '0')}';
      
      // 더미 옵션 데이터 추가 (실제로는 루틴 모델에서 가져와야 함)
      _addOption();
      _options[0]['minutes'].text = '5';
      _options[0]['text'].text = '운동 준비하세요!';
    } else {
      // 초기 옵션 하나 추가
      _addOption();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    // 옵션 컨트롤러들도 정리
    for (var option in _options) {
      option['minutes'].dispose();
      option['text'].dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'timing': '전', // 기본값: "전"
        'minutes': TextEditingController(),
        'text': TextEditingController(),
      });
    });
  }

  void _removeOption(int index) {
    setState(() {
      _options[index]['minutes'].dispose();
      _options[index]['text'].dispose();
      _options.removeAt(index);
    });
  }

  void _handleAIRoutineRecommendation() async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primary,
                ),
                SizedBox(height: 16),
                Text(
                  'AI가 아이의 패턴을 분석하고 있어요...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // AI 분석 시뮬레이션 (2초 딜레이)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 다이얼로그 닫기
    Navigator.of(context).pop();

    // AI 추천 데이터 (더미 데이터)
    final recommendedData = _generateAIRoutineRecommendation();

    // 추천 결과를 입력 필드에 채우기
    setState(() {
      _nameController.text = recommendedData['name'];
      _contentController.text = recommendedData['content'];
      
      // 날짜와 시간은 현재 시간으로 설정
      final now = DateTime.now();
      _dateController.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _timeController.text = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      // 기존 옵션 정리
      for (var option in _options) {
        option['minutes'].dispose();
        option['text'].dispose();
      }
      _options.clear();
      
      // AI 추천 옵션 추가
      for (var optionData in recommendedData['options']) {
        final minutesController = TextEditingController();
        final textController = TextEditingController();
        
        minutesController.text = optionData['minutes'];
        textController.text = optionData['text'];
        
        _options.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          'timing': optionData['timing'] ?? '전', // 기본값: "전"
          'minutes': minutesController,
          'text': textController,
        });
      }
    });

    // 성공 메시지 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Ionicons.checkmark_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('AI가 아이에게 맞는 루틴을 추천했어요!'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Map<String, dynamic> _generateAIRoutineRecommendation() {
    // 더미 데이터: 아이의 루틴 패턴을 분석하여 맞춤형 루틴 추천
    // TODO: 실제로는 아이의 루틴 이행 데이터와 AI 챗봇 대화 내용을 분석하여 추천
    
    final now = DateTime.now();
    final recommendations = [
      {
        'name': '오후 집중 독서 시간',
        'content': '아이의 독서 습관이 좋아지고 있어요! 오후 2시부터 30분 동안 책을 읽으며 집중력을 길러봐요. 독서 후에는 작은 보상을 받을 수 있어요!',
        'options': [
          {'minutes': '5', 'text': '책 읽기 준비하세요! 편안한 장소를 찾아보아요.'},
          {'minutes': '30', 'text': '책 읽기 시간이 끝났어요! 잘했어요!'},
        ],
      },
      {
        'name': '아침 기상 루틴',
        'content': '일찍 일어나는 습관을 만들어요! 매일 같은 시간에 일어나서 세수를 하고, 옷을 입는 순서대로 정해보아요. 완료하면 좋아하는 음식을 먹을 수 있어요!',
        'options': [
          {'minutes': '10', 'text': '잠에서 깨어나세요! 햇살이 반겨줘요.'},
          {'minutes': '5', 'text': '세수하고 옷 입을 시간이에요!'},
        ],
      },
      {
        'name': '저녁 정리 시간',
        'content': '하루를 마무리하는 루틴이에요! 10분 동안 장난감을 정리하고, 내일 입을 옷을 준비해요. 정리 완료하면 부모님과 함께 이야기할 수 있어요!',
        'options': [
          {'minutes': '15', 'text': '정리 시작할 시간이에요! 장난감 친구들이 집에 가고 싶어 해요.'},
          {'minutes': '5', 'text': '마지막 정리 시간! 깔끔하게 마무리해요.'},
        ],
      },
    ];

    // 현재 시간에 따라 다른 루틴 추천
    final recommendationIndex = now.hour % 3;
    return recommendations[recommendationIndex];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              widget.routineToEdit != null ? '루틴 수정' : '루틴 생성',
              style: const TextStyle(
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
          // AI 루틴 추천 버튼 (수정 모드가 아닐 때만 표시)
          if (widget.routineToEdit == null)
            IconButton(
              icon: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Ionicons.sparkles, color: AppColors.primary, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'AI 추천',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              onPressed: _handleAIRoutineRecommendation,
            ),
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 환영 메시지
              const Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text(
                  '새로운 루틴을 만들어보세요! 🎯',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              
              // 루틴 정보 섹션
              _buildSectionTitle('루틴 정보'),
              const SizedBox(height: 16),
              
              // 루틴 이름
              _buildTextField(
                controller: _nameController,
                label: '루틴 이름',
                hint: '루틴 이름을 입력하세요',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '루틴 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              
              // 루틴 내용
              _buildTextField(
                controller: _contentController,
                label: '루틴 내용',
                hint: '루틴에 대한 상세 내용을 입력하세요',
                icon: Icons.description,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '루틴 내용을 입력해주세요';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 날짜와 시간 필드
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _dateController,
                      label: '시작 날짜',
                      hint: '2025-01-15',
                      icon: Ionicons.calendar_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '날짜를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _timeController,
                      label: '시작 시간',
                      hint: '09:00',
                      icon: Ionicons.time_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '시간을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // 옵션 섹션
              _buildSectionTitle('루틴 옵션'),
              const SizedBox(height: 4),
              Text(
                '루틴 시작 -분전/후에 받을 알림 텍스트입니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              // 옵션 목록
              ..._options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                return _buildOptionItem(index, option);
              }).toList(),
              
              // 옵션 추가 버튼
              const SizedBox(height: 16),
              _buildAddOptionButton(),
              
              const SizedBox(height: 40),
              
              // 루틴 생성 버튼
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateRoutine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.routineToEdit != null ? '루틴 수정' : '루틴 생성',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 취소 버튼
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  void _handleCreateRoutine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 ID 가져오기
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 날짜와 시간 파싱
      final dateParts = _dateController.text.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      
      final timeParts = _timeController.text.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // DateTime 생성
      final routineDateTime = DateTime(year, month, day, hour, minute);
      final routineTimeStr = '${routineDateTime.year}-${routineDateTime.month.toString().padLeft(2, '0')}-${routineDateTime.day.toString().padLeft(2, '0')} ${routineDateTime.hour.toString().padLeft(2, '0')}:${routineDateTime.minute.toString().padLeft(2, '0')}:00';

      // 옵션 데이터 준비
      final options = _options.map((option) {
        return {
          'timing': option['timing'] ?? '전', // "전" 또는 "후"
          'minutes': option['minutes'].text.isEmpty ? null : int.tryParse(option['minutes'].text),
          'text': option['text'].text.trim(),
        };
      }).where((option) {
        // 빈 옵션 필터링
        return option['minutes'] != null && option['text'].isNotEmpty;
      }).toList();

      if (widget.routineToEdit != null) {
        // 수정 모드: 기존 루틴 업데이트
        // TODO: 수정 API 엔드포인트 구현 필요
        throw Exception('수정 기능은 아직 구현되지 않았습니다.');
        
        // 기존 알림 취소
        await NotificationService().cancelNotification(widget.routineToEdit!.id);
      } else {
        // 생성 모드: 새 루틴 생성
        final response = await ApiService().post('/routines', {
          'user_id': userId,
          'routine_name': _nameController.text.trim(),
          'routine_content': _contentController.text.trim(),
          'routine_time': routineTimeStr,
          'options': options,
        });
        
        if (response['result'] != 'success') {
          throw Exception(response['msg'] ?? '루틴 생성에 실패했습니다.');
        }
        
        final routineId = response['routine_id'];
        
        // 매일 특정 시간에 알림 예약
        await NotificationService().scheduleDailyNotification(
          id: routineId,
          title: _nameController.text.trim(), // 루틴 이름
          body: _contentController.text.trim(), // 루틴 내용
          time: Time(hour, minute),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.routineToEdit != null ? '루틴이 성공적으로 수정되었습니다!' : '루틴이 성공적으로 생성되었습니다!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // 홈 화면으로 돌아가면서 새로고침 신호 전달
        Navigator.pop(context, true); // true를 반환하여 홈 화면에 새로고침 신호 전달
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.routineToEdit != null ? '루틴 수정 중 오류가 발생했습니다: $e' : '루틴 생성 중 오류가 발생했습니다: $e'),
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

  Widget _buildOptionItem(int index, Map<String, dynamic> option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '옵션 ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (_options.length > 1)
                IconButton(
                  onPressed: () => _removeOption(index),
                  icon: const Icon(
                    Ionicons.close_circle,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 드롭다운, 분 입력, 알림 텍스트를 한 줄에 배치
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 드롭다운: "전" 또는 "후"
              SizedBox(
                width: 80,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String>(
                    value: option['timing'] ?? '전',
                    isExpanded: true,
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(
                        value: '전', 
                        child: Center(child: Text('전')),
                      ),
                      DropdownMenuItem(
                        value: '후', 
                        child: Center(child: Text('후')),
                      ),
                    ],
                    selectedItemBuilder: (BuildContext context) {
                      return <String>['전', '후'].map<Widget>((String item) {
                        return Center(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    onChanged: (value) {
                      setState(() {
                        option['timing'] = value;
                      });
                    },
                    icon: const Icon(Ionicons.chevron_down, color: Colors.grey, size: 18),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 분 입력 필드 (Icon + Input + "분" 텍스트를 하나로)
              Expanded(
                flex: 2,
                child: Container(
                  height: 56,
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
                  child: TextFormField(
                    controller: option['minutes'],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '5',
                      prefixIcon: Icon(Ionicons.time_outline, color: AppColors.primary),
                      suffixText: '분',
                      suffixStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 알림 텍스트 입력 필드
              Expanded(
                flex: 3,
                child: Container(
                  height: 56,
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
                  child: TextFormField(
                    controller: option['text'],
                    decoration: InputDecoration(
                      hintText: '알림 텍스트를 입력하세요.',
                      prefixIcon: Icon(Ionicons.chatbubble_outline, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddOptionButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: _addOption,
        icon: const Icon(
          Ionicons.add_circle_outline,
          color: AppColors.primary,
          size: 20,
        ),
        label: const Text(
          '옵션 추가',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

}
