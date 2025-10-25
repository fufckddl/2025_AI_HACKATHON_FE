import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../constants/app_colors.dart';
import '../models/task_item.dart';

class FocusToolsSection extends StatefulWidget {
  const FocusToolsSection({super.key});

  @override
  State<FocusToolsSection> createState() => _FocusToolsSectionState();
}

class _FocusToolsSectionState extends State<FocusToolsSection> {
  List<TaskItem> _todoTasks = [];
  List<TaskItem> _completedTasks = [];
  final TextEditingController _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Ionicons.checkbox_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '집중력 유지 도구',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 할 일 추가 입력
          _buildTaskInput(),
          
          const SizedBox(height: 20),
          
          // 해야할 일과 끝낸 일 분리 표시
          Row(
            children: [
              Expanded(
                child: _buildTaskList('해야할 일', _todoTasks, false),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTaskList('끝낸 일', _completedTasks, true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 할 일 추가 입력 필드
  Widget _buildTaskInput() {
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                hintText: '새로운 할 일을 입력하세요...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (value) => _addTask(value),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _addTask(_taskController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Ionicons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 할 일 목록 표시
  Widget _buildTaskList(String title, List<TaskItem> tasks, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Ionicons.checkmark_circle : Ionicons.time,
                color: isCompleted ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green[700] : Colors.orange[700],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tasks.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  isCompleted ? '완료된 할 일이 없어요' : '할 일이 없어요',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...tasks.map((task) => _buildTaskItem(task, isCompleted)),
        ],
      ),
    );
  }

  // 개별 할 일 아이템
  Widget _buildTaskItem(TaskItem task, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleTask(task),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.grey[400]!,
                  width: 1,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Ionicons.checkmark,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.text,
              style: TextStyle(
                fontSize: 14,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey[600] : Colors.black87,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _deleteTask(task),
            child: Icon(
              Ionicons.trash_outline,
              color: Colors.red[400],
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 할 일 추가
  void _addTask(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _todoTasks.add(TaskItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text.trim(),
        createdAt: DateTime.now(),
      ));
    });
    
    _taskController.clear();
  }

  // 할 일 완료/미완료 토글
  void _toggleTask(TaskItem task) {
    setState(() {
      if (task.isCompleted) {
        // 완료된 할 일을 미완료로
        _completedTasks.remove(task);
        _todoTasks.add(task.copyWith(isCompleted: false));
      } else {
        // 미완료 할 일을 완료로
        _todoTasks.remove(task);
        _completedTasks.add(task.copyWith(isCompleted: true));
      }
    });
  }

  // 할 일 삭제
  void _deleteTask(TaskItem task) {
    setState(() {
      _todoTasks.remove(task);
      _completedTasks.remove(task);
    });
  }
}
