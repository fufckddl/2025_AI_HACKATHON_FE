import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class AIChatService {
  static const String _baseUrl = 'https://cloud.flowiseai.com/api/v1/prediction';
  static const String _endpointId = '541c7c9c-023f-4a34-a755-c2f4aaac0b53';
  
  static Future<String> sendMessage(String question, List<ChatMessage> chatHistory) async {
    try {
      // 이전 대화 내용을 맥락으로 포함
      String context = '';
      if (chatHistory.isNotEmpty) {
        // 최근 5개 대화만 맥락으로 포함
        final recentMessages = chatHistory.take(5).toList();
        context = recentMessages.map((msg) => 
          '${msg.isUser ? "사용자" : "AI"}: ${msg.text}'
        ).join('\n');
        context = '이전 대화 맥락:\n$context\n\n현재 질문: ';
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/$_endpointId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': context + question,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? '죄송합니다. 응답을 생성할 수 없습니다.';
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return '죄송합니다. 서버 오류가 발생했습니다.';
      }
    } catch (e) {
      print('AI Chat Service Error: $e');
      return '죄송합니다. 네트워크 오류가 발생했습니다.';
    }
  }

  // 시스템 프롬프트를 포함한 메시지 전송
  static Future<String> sendMessageWithPersona(String question, List<ChatMessage> chatHistory) async {
    try {
      // AI 페르소나 프롬프트 - ADHD 아동 부모를 위한 전문 챗봇
      const String systemPrompt = '''
당신은 'ROUTY' 앱의 전문적인 AI 챗봇입니다. 당신의 주 역할은 ADHD 아동의 부모님께 따뜻한 공감과 신뢰할 수 있는 정보를 제공하고, 앱을 통해 수집된 아이의 루틴 이행 데이터 및 행동 변화를 바탕으로 질문에 답하며 코칭하는 것입니다.

[핵심 원칙]
1. 공감 및 격려: 부모의 노력과 걱정에 진심으로 공감하는 표현을 먼저 사용합니다.
2. 전문성: 모든 답변은 ADHD 아동의 행동/수면 관리, 루틴의 중요성, 독서 치료 등 교육 및 임상적 근거에 기반하여 제공합니다.
3. 데이터 기반 피드백: 질문에 직접적인 답변 대신, **"하지만 ADHD 진단이나 치료는 의료 전문가의 영역입니다"**라는 면책 조항을 명확히 제시해야 합니다.
4. ROUTY 앱 활용 독려: 답변을 통해 ROUTY 앱의 기능(AI 루틴 추천, 코칭 리포트, 보상 시스템) 활용을 자연스럽게 유도합니다.

[ADHD 관련 연구 요약]
- 루틴/과제: 10-15분 단위의 작은 과제와 즉각적 보상이 효과적
- 수면: 충분한 수면(9.5시간)은 작업기억, 계획 능력, 감정 조절에 긍정적 영향을 미침
- 독서: 독서 치료는 주의력 결핍 행동, 과잉행동, 충동성 감소에 효과가 있다는 연구 결과가 있음

[응답 구조]
1. 공감/칭찬: 아이의 긍정적인 변화에 대해 진심으로 칭찬하고 부모님의 노력에 공감
2. 데이터 연결: ROUTY 앱의 데이터와 연결하여 설명
3. 전문가 근거 제시: 연구 결과를 언급하여 긍정적인 변화의 배경을 뒷받침
4. 면책 조항 및 조언: 의료 전문가 상담 필요성 명시 및 ROUTY 앱 활용 조언 제안
''';

      // 이전 대화 내용을 맥락으로 포함
      String context = systemPrompt + '\n\n';
      
      // 시뮬레이션된 아이의 데이터 (실제 앱에서는 ROUTY 앱에서 가져올 데이터)
      const String childData = '''
[아이의 최근 데이터]
- 주간 루틴 이행률: 78% (지난 주 대비 +12%)
- 수면 시간: 평균 9.2시간 (목표 9.5시간)
- 독서 시간: 주 3회, 평균 25분 (이전 주 대비 +15분)
- 집중력 지수: 7.2/10 (이전 주 대비 +0.8)
- 감정 상태: 긍정적 (관심사: 과학, 동물, 게임)
''';
      
      context += childData + '\n\n';
      
      if (chatHistory.isNotEmpty) {
        final recentMessages = chatHistory.take(5).toList();
        context += '이전 대화 맥락:\n';
        context += recentMessages.map((msg) => 
          '${msg.isUser ? "부모님" : "ROUTY AI"}: ${msg.text}'
        ).join('\n');
        context += '\n\n현재 질문: ';
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/$_endpointId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': context + question,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('TimeoutException: API 응답 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? '안녕하세요! 루틴을 도와드릴게요!';
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return '죄송해요. 잠시 문제가 생겼어요. 다시 시도해보세요!';
      }
    } catch (e) {
      print('AI Chat Service Error: $e');
      return '죄송해요. 연결에 문제가 생겼어요. 다시 시도해보세요!';
    }
  }
}
