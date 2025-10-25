import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatStorageService {
  static const String _chatHistoryKey = 'chat_history';
  
  // 대화 기록 저장
  static Future<void> saveChatHistory(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((msg) => msg.toJson()).toList();
      final jsonString = jsonEncode(messagesJson);
      await prefs.setString(_chatHistoryKey, jsonString);
    } catch (e) {
      print('Chat Storage Save Error: $e');
    }
  }
  
  // 대화 기록 불러오기
  static Future<List<ChatMessage>> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_chatHistoryKey);
      
      if (jsonString == null) {
        return [];
      }
      
      final List<dynamic> messagesJson = jsonDecode(jsonString);
      return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      print('Chat Storage Load Error: $e');
      return [];
    }
  }
  
  // 대화 기록 삭제
  static Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatHistoryKey);
    } catch (e) {
      print('Chat Storage Clear Error: $e');
    }
  }
  
  // 새 메시지 추가
  static Future<void> addMessage(ChatMessage message) async {
    try {
      final messages = await loadChatHistory();
      messages.add(message);
      await saveChatHistory(messages);
    } catch (e) {
      print('Chat Storage Add Error: $e');
    }
  }
  
  // 최근 N개 메시지만 유지 (메모리 절약)
  static Future<void> keepRecentMessages(int maxCount) async {
    try {
      final messages = await loadChatHistory();
      if (messages.length > maxCount) {
        final recentMessages = messages.skip(messages.length - maxCount).toList();
        await saveChatHistory(recentMessages);
      }
    } catch (e) {
      print('Chat Storage Keep Recent Error: $e');
    }
  }
}
