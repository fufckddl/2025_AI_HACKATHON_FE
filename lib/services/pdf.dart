import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class PDFService {
  static Future<Uint8List> generateCoachingReportPDF() async {
    // NotoSansKR 폰트 로드
    final fontData = await rootBundle.load("assets/fonts/NotoSansKR-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    
    // 사용자 ID 가져오기
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId == null) {
      throw Exception('사용자 ID를 찾을 수 없습니다.');
    }
    
    try {
      // 백엔드에서 코칭 리포트 데이터 가져오기
      final reportData = await _fetchCoachingReport(userId);
      
      // 데이터가 없을 경우 예외 발생
      if (reportData == null) {
        throw Exception('데이터가 없어 pdf를 생성할 수 없습니다.');
      }
      
      // OpenAI를 활용하여 향상된 리포트 내용 생성
      final enhancedContent = await _generateEnhancedContent(reportData);
      
      // PDF 문서 생성
      final pdf = pw.Document();
      
      // 첫 페이지: 커버
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildCoverPage(enhancedContent, ttf);
          },
        ),
      );
      
      // 두 번째 페이지: 요약
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildSummaryPage(enhancedContent, reportData, ttf);
          },
        ),
      );
      
      // 세 번째 페이지: 상세 분석
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildAnalysisPage(enhancedContent, reportData, ttf);
          },
        ),
      );
      
      return pdf.save();
    } catch (e) {
      throw Exception('PDF 생성 실패: $e');
    }
  }
  
  static Future<Map<String, dynamic>?> _fetchCoachingReport(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 먼저 SharedPreferences의 캐시에서 데이터 가져오기
      final cachedInsights = prefs.getString('ai_insights_cache');
      if (cachedInsights != null) {
        print('📦 PDF 생성: 캐시된 데이터 사용');
        return jsonDecode(cachedInsights) as Map<String, dynamic>;
      }
      
      // 캐시가 없으면 API에서 가져오기
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('토큰을 찾을 수 없습니다.');
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/coaching/report/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success' && data['report'] != null) {
          print('📦 PDF 생성: API에서 데이터 가져옴');
          return data['report'];
        }
      }
      
      print('📦 PDF 생성: 데이터 없음');
      return null;
    } catch (e) {
      print('리포트 조회 오류: $e');
      return null;
    }
  }
  
  static Future<Map<String, dynamic>> _generateEnhancedContent(Map<String, dynamic> reportData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // AppConstants의 userTokenKey 사용
      final token = prefs.getString('user_token');
      
      if (token == null || token.isEmpty) {
        print('⚠️ 토큰이 없어 원본 데이터 사용');
        return {};
      }
      
      // OpenAI를 위한 프롬프트 작성
      final prompt = _buildReportPrompt(reportData);
      
      // OpenAI API 호출
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/ai/generate-pdf-report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'prompt': prompt,
          'report_data': reportData,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ OpenAI 리포트 생성 성공');
        return data['generated_report'] ?? {};
      }
      
      // OpenAI 호출 실패시 원본 데이터 반환
      print('⚠️ OpenAI 호출 실패 (${response.statusCode}), 원본 데이터 사용');
      return {};
    } catch (e) {
      print('OpenAI 향상 실패: $e');
      return {};
    }
  }
  
  static String _buildReportPrompt(Map<String, dynamic> reportData) {
    return '''
당신은 ADHD 아동을 위한 루틴 관리 전문가입니다. 아래 제공된 데이터를 분석하여 부모와 교사가 사용할 수 있는 전문적인 코칭 리포트를 작성해주세요.

## 제공된 데이터:
- 요약 인사이트: ${reportData['summary_insight'] ?? '없음'}
- 맞춤 코칭 문구: ${reportData['custom_coaching_phrase'] ?? '없음'}
- 루틴 적응도: ${reportData['adaptation_rate'] ?? '없음'}
- 강점: ${reportData['strengths'] ?? '없음'}
- 개선점: ${reportData['improvements'] ?? '없음'}
- 제안사항: ${reportData['suggestions'] ?? '없음'}

## 리포트 작성 지침:
1. 데이터를 분석하여 아동의 루틴 이행 패턴을 파악하세요
2. 긍정적인 성과를 강조하되, 현실적인 개선 방안을 제시하세요
3. 부모와 교사가 실행 가능한 구체적인 조언을 제공하세요
4. 전문적이면서도 따뜻한 톤으로 작성하세요
5. 특수문자나 이모지는 사용하지 마세요
6. 한국어로만 작성하세요

## 출력 형식 (JSON):
{
  "executive_summary": "전체 리포트를 종합적으로 요약하는 3-5문장",
  "detailed_analysis": "주간 패턴, 습관 변화, 일일 루틴 이행 추이 등을 포함한 상세 분석 (최소 200자 이상)",
  "key_achievements": [
    "이번 주에 달성한 주요 성과 1",
    "이번 주에 달성한 주요 성과 2",
    "이번 주에 달성한 주요 성과 3",
    "이번 주에 달성한 주요 성과 4"
  ],
  "areas_for_improvement": [
    "개선이 필요한 영역 1 (구체적인 설명 포함)",
    "개선이 필요한 영역 2 (구체적인 설명 포함)",
    "개선이 필요한 영역 3 (구체적인 설명 포함)"
  ],
  "recommendations": [
    "부모/교사가 실행할 수 있는 구체적인 권장사항 1 (실행 방법 포함)",
    "부모/교사가 실행할 수 있는 구체적인 권장사항 2 (실행 방법 포함)",
    "부모/교사가 실행할 수 있는 구체적인 권장사항 3 (실행 방법 포함)",
    "부모/교사가 실행할 수 있는 구체적인 권장사항 4 (실행 방법 포함)",
    "부모/교사가 실행할 수 있는 구체적인 권장사항 5 (실행 방법 포함)"
  ],
  "behavioral_patterns": "아동의 행동 패턴, 루틴 이행 시간대, 선호하는 활동 등을 분석한 내용 (최소 150자 이상)",
  "motivation_strategies": [
    "아동의 동기를 유지할 수 있는 전략 1",
    "아동의 동기를 유지할 수 있는 전략 2",
    "아동의 동기를 유지할 수 있는 전략 3"
  ],
  "next_steps": "다음 주 계획, 목표, 추천 루틴 조정 방안을 포함한 구체적인 실행 계획 (최소 200자 이상)",
  "family_involvement": "가족이 함께 할 수 있는 활동 및 루틴 개선 방안 (최소 100자 이상)"
}
''';
  }
  
  static pw.Widget _buildCoverPage(Map<String, dynamic> enhancedContent, pw.Font ttf) {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          '루틴 관리 코칭 리포트',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          DateTime.now().toString().split(' ')[0],
          style: pw.TextStyle(
            font: ttf,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildSummaryPage(
    Map<String, dynamic> enhancedContent,
    Map<String, dynamic> reportData,
    pw.Font ttf,
  ) {
    // OpenAI가 생성한 콘텐츠가 있으면 우선 사용
    final executiveSummary = enhancedContent['executive_summary'];
    final customCoachingPhrase = enhancedContent['custom_coaching_phrase'] ?? reportData['custom_coaching_phrase'];
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '요약 인사이트',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            executiveSummary ?? reportData['summary_insight'] ?? '요약 데이터가 없습니다.',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 12,
            ),
          ),
        ),
        pw.SizedBox(height: 30),
        pw.Text(
          '맞춤 코칭 문구',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            customCoachingPhrase ?? '코칭 문구가 없습니다.',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildAnalysisPage(
    Map<String, dynamic> enhancedContent,
    Map<String, dynamic> reportData,
    pw.Font ttf,
  ) {
    // OpenAI가 생성한 콘텐츠 우선 사용
    final detailedAnalysis = enhancedContent['detailed_analysis'];
    final behavioralPatterns = enhancedContent['behavioral_patterns'];
    final keyAchievements = List<String>.from(enhancedContent['key_achievements'] ?? reportData['strengths'] ?? []);
    final areasForImprovement = List<String>.from(enhancedContent['areas_for_improvement'] ?? reportData['improvements'] ?? []);
    final recommendations = List<String>.from(enhancedContent['recommendations'] ?? reportData['suggestions'] ?? []);
    final motivationStrategies = List<String>.from(enhancedContent['motivation_strategies'] ?? []);
    final nextSteps = enhancedContent['next_steps'];
    final familyInvolvement = enhancedContent['family_involvement'];
    
    // 기존 데이터 (fallback)
    final List<String> strengths = List<String>.from(reportData['strengths'] ?? []);
    final List<String> improvements = List<String>.from(reportData['improvements'] ?? []);
    final List<String> suggestions = List<String>.from(reportData['suggestions'] ?? []);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '상세 분석',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 20),
        
        // OpenAI가 생성한 상세 분석이 있으면 표시
        if (detailedAnalysis != null) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              detailedAnalysis,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
        ],
        
        // 주요 성과 표시 (OpenAI 또는 기존 데이터)
        if (keyAchievements.isNotEmpty) ...[
          pw.Text(
            '주요 성과',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...keyAchievements.map((item) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.green,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    item,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          )),
          pw.SizedBox(height: 20),
        ],
        
        // 개선 영역 표시 (OpenAI 또는 기존 데이터)
        if (areasForImprovement.isNotEmpty) ...[
          pw.Text(
            '개선 영역',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...areasForImprovement.map((item) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.orange,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    item,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          )),
          pw.SizedBox(height: 20),
        ],
        
        // OpenAI가 생성한 권장사항이 있으면 우선 표시
        if (recommendations.isNotEmpty) ...[
          pw.Text(
            '권장사항',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...recommendations.map((item) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    item,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          )),
          pw.SizedBox(height: 20),
        ] else if (suggestions.isNotEmpty) ...[
          // 기존 제안사항 표시 (fallback)
          pw.Text(
            '코칭 제안',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...suggestions.map((item) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    item,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          )),
          pw.SizedBox(height: 20),
        ],
        
        // 행동 패턴 분석 표시
        if (behavioralPatterns != null) ...[
          pw.Text(
            '행동 패턴 분석',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              behavioralPatterns,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
        ],
        
        // 동기 유지 전략 표시
        if (motivationStrategies.isNotEmpty) ...[
          pw.Text(
            '동기 유지 전략',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...motivationStrategies.map((item) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    item,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          )),
          pw.SizedBox(height: 20),
        ],
        
        // 다음 단계 표시
        if (nextSteps != null) ...[
          pw.Text(
            '다음 단계',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.purple50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              nextSteps,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
        ],
        
        // 가족 참여 방안 표시
        if (familyInvolvement != null) ...[
          pw.Text(
            '가족 참여 방안',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              familyInvolvement,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
