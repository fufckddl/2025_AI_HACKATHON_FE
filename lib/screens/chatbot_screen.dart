import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import '../constants/app_colors.dart';
import '../components/bottom_navigation_bar.dart';
import '../models/chat_message.dart';
import '../services/ai_chat_service.dart';
import '../services/chat_storage_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 대화 기록 불러오기
  Future<void> _loadChatHistory() async {
    try {
      final messages = await ChatStorageService.loadChatHistory();
      if (mounted) {
        setState(() {
          _messages.addAll(messages);
        });
        _scrollToBottom();
      }
      
      // 대화 기록이 없으면 초기 인사 메시지 추가
      if (_messages.isEmpty) {
        _addBotMessage('안녕하세요! 저는 ROUTY 앱의 AI 챗봇입니다. 👨‍👩‍👧‍👦\n\nADHD 아동의 루틴 관리와 행동 변화에 대해 전문적인 조언을 드릴 수 있어요. 아이의 최근 루틴 이행 데이터를 바탕으로 맞춤형 코칭을 제공해드립니다!');
      }
    } catch (e) {
      print('Chat History Load Error: $e');
      if (_messages.isEmpty) {
        _addBotMessage('안녕하세요! 저는 ROUTY 앱의 AI 챗봇입니다. 👨‍👩‍👧‍👦\n\nADHD 아동의 루틴 관리와 행동 변화에 대해 전문적인 조언을 드릴 수 있어요. 아이의 최근 루틴 이행 데이터를 바탕으로 맞춤형 코칭을 제공해드립니다!');
      }
    }
  }

  void _addUserMessage(String text) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(message);
    });
    
    // 메시지 저장
    ChatStorageService.addMessage(message);
    _scrollToBottom();
  }

  void _addBotMessage(String text) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(message);
    });
    
    // 메시지 저장
    ChatStorageService.addMessage(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final message = _messageController.text.trim();
    _addUserMessage(message);
    _messageController.clear();

    // AI 응답 요청
    await _getAIResponse(message);
  }

  Future<void> _getAIResponse(String userMessage) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🤖 AI API 호출 시작: $userMessage');
      final startTime = DateTime.now();
      
      // AI API 호출
      final response = await AIChatService.sendMessageWithPersona(userMessage, _messages);
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('✅ AI 응답 완료 (${duration.inMilliseconds}ms): $response');
      
      if (mounted) {
        _addBotMessage(response);
        
        // 최근 50개 메시지만 유지 (메모리 절약)
        await ChatStorageService.keepRecentMessages(50);
      }
    } catch (e) {
      print('❌ AI Response Error: $e');
      if (mounted) {
        String errorMessage = '죄송해요. 잠시 문제가 생겼어요.';
        
        if (e.toString().contains('SocketException')) {
          errorMessage = '인터넷 연결을 확인해주세요! 📶';
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage = '응답이 너무 오래 걸려요. 다시 시도해보세요! ⏰';
        } else if (e.toString().contains('FormatException')) {
          errorMessage = '서버 응답에 문제가 있어요. 잠시 후 다시 시도해주세요! 🔧';
        }
        
        _addBotMessage(errorMessage);
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
              'ROUTY AI 코칭', //ADHD 아동 부모를 위한 전문 챗봇
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
          // 테스트용 버튼
          IconButton(
            icon: const Icon(Ionicons.bug_outline, color: Colors.orange),
            onPressed: () {
              _addUserMessage('요즘 아이가 책을 30분씩 읽고 있는데, 이게 ADHD가 완화된 걸까요?');
            },
          ),
          IconButton(
            icon: const Icon(Ionicons.refresh_outline, color: Colors.black),
            onPressed: () async {
              await ChatStorageService.clearChatHistory();
              setState(() {
                _messages.clear();
                _addBotMessage('안녕하세요! 저는 ROUTY 앱의 AI 챗봇입니다. 👨‍👩‍👧‍👦\n\nADHD 아동의 루틴 관리와 행동 변화에 대해 전문적인 조언을 드릴 수 있어요. 아이의 최근 루틴 이행 데이터를 바탕으로 맞춤형 코칭을 제공해드립니다!');
              });
            },
          ),
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFF9FAFB),
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: Column(
        children: [
          // 채팅 메시지 목록
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // 메시지 입력 영역
          _buildMessageInput(),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 3),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: const Icon(
                Ionicons.chatbubble_outline, //실제 사용자가 선택한 캐릭터의 이모지가 나와야 함
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? AppColors.primary 
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: message.isUser ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: message.isUser 
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: const Icon(
                Ionicons.person_outline,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Ionicons.send,
                      color: Colors.white,
                      size: 20,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: const Icon(
              Ionicons.chatbubble_outline,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI가 답변을 생성하고 있어요...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
