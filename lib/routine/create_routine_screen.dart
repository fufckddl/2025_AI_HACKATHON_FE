import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/routine_model.dart';
import '../widgets/custom_button.dart';

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  
  bool _isLoading = false;
  
  // 옵션 관리
  List<Map<String, dynamic>> _options = [];
  
  @override
  void initState() {
    super.initState();
    // 초기 옵션 하나 추가
    _addOption();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add({
        'id': DateTime.now().millisecondsSinceEpoch,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              '루틴 생성',
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
              
              const SizedBox(height: 30),
              
              // 옵션 섹션
              _buildSectionTitle('루틴 옵션'),
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
                      : const Text(
                          '루틴 생성',
                          style: TextStyle(
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
      // RoutineModel 생성
      final routine = RoutineModel(
        id: 0, // 서버에서 자동 생성될 ID
        userId: 1, // 임시 사용자 ID (실제로는 로그인한 사용자 ID)
        name: _nameController.text.trim(),
        cycle: 1, // 기본값: 매일
        content: _contentController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // TODO: API 호출로 루틴 생성 처리
      // await ApiService().post('/routines', routine.toJson());
      
      // 임시로 루틴 객체를 사용하여 생성 시뮬레이션
      routine.toString(); // 변수 사용으로 경고 제거
      
      await Future.delayed(const Duration(seconds: 2)); // 임시 딜레이

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('루틴이 성공적으로 생성되었습니다!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // 루틴 목록 페이지로 이동
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('루틴 생성 중 오류가 발생했습니다: $e'),
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
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: option['minutes'],
                  label: '분전',
                  hint: '5',
                  icon: Ionicons.time_outline,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '분을 입력해주세요';
                    }
                    final minutes = int.tryParse(value);
                    if (minutes == null || minutes <= 0) {
                      return '올바른 분을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                flex: 5,
                child: _buildTextField(
                  controller: option['text'],
                  label: 'AI가 읽을 텍스트',
                  hint: '알림 텍스트를 입력하세요',
                  icon: Ionicons.chatbubble_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '텍스트를 입력해주세요';
                    }
                    return null;
                  },
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
