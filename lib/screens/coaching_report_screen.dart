import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../components/bottom_navigation_bar.dart';
import '../services/api_service.dart';
import '../services/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';

class CoachingReportScreen extends StatefulWidget {
  const CoachingReportScreen({super.key});

  @override
  State<CoachingReportScreen> createState() => _CoachingReportScreenState();
}

class _CoachingReportScreenState extends State<CoachingReportScreen> {
  bool _isGenerating = false;
  Map<String, dynamic>? _aiInsights;
  bool _isLoadingFromCache = false;
  
  @override
  void initState() {
    super.initState();
    _loadSavedInsights();
  }
  
  // SharedPreferences에서 저장된 인사이트 로드
  Future<void> _loadSavedInsights() async {
    setState(() {
      _isLoadingFromCache = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedInsightsJson = prefs.getString('ai_insights_cache');
      
      if (savedInsightsJson != null) {
        final insights = json.decode(savedInsightsJson) as Map<String, dynamic>;
        print('📦 캐시된 인사이트 로드됨');
        print('📦 캐시된 adaptation_rate: ${insights['adaptation_rate']}');
        print('📦 캐시된 completed_routines: ${insights['completed_routines']}');
        print('📦 캐시된 total_routines: ${insights['total_routines']}');
        
        // 캐시된 데이터에 completed_routines나 total_routines가 없으면 기본값 설정
        if (insights['completed_routines'] == null || insights['total_routines'] == null) {
          // adaptation_rate에서 계산하여 역산
          dynamic adaptationRate = insights['adaptation_rate'];
          double rate = 0.0;
          
          if (adaptationRate is int) {
            rate = adaptationRate.toDouble();
          } else if (adaptationRate is double) {
            rate = adaptationRate;
          } else if (adaptationRate is String) {
            final regex = RegExp(r'(\d+(?:\.\d+)?)');
            final match = regex.firstMatch(adaptationRate);
            if (match != null) {
              rate = double.tryParse(match.group(1) ?? '0') ?? 0.0;
            }
          }
          
          if (rate > 0) {
            // 대략적인 값으로 설정 (정확한 값은 재생성 시 갱신)
            insights['completed_routines'] = (rate * 10).toInt();
            insights['total_routines'] = 10;
            print('📦 역산된 루틴 수: ${insights['completed_routines']}/${insights['total_routines']}');
          }
        }
        
        setState(() {
          _aiInsights = insights;
        });
      } else {
        print('📦 캐시된 인사이트 없음');
      }
    } catch (e) {
      print('저장된 인사이트 로드 중 오류: $e');
    } finally {
      setState(() {
        _isLoadingFromCache = false;
      });
    }
  }
  
  // SharedPreferences에 인사이트 저장
  Future<void> _saveInsights(Map<String, dynamic> insights) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // completed_routines와 total_routines가 포함된 전체 insights 저장
      await prefs.setString('ai_insights_cache', json.encode(insights));
      print('💾 인사이트 저장 완료 (포함: adaptation_rate, completed_routines, total_routines)');
    } catch (e) {
      print('인사이트 저장 중 오류: $e');
    }
  }
  
  Future<void> _generateAIInsights() async {
    setState(() {
      _isGenerating = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      
      if (userId == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다.')),
          );
        }
        return;
      }
      
      // 1. AI 인사이트 생성
      print('🚀 AI 인사이트 생성 요청 시작 - User ID: $userId');
      final response = await ApiService().get('/coaching/insights/$userId');
      
      print('📥 API 응답 수신: ${response.toString()}');
      
      if (response['result'] == 'success') {
        final insights = response['insights'];
        final stats = response['stats'];
        
        // 백엔드에서 받은 completion_rate를 adaptation_rate로 설정
        if (stats != null && stats['completion_rate'] != null) {
          final completionRate = stats['completion_rate'] as double;
          insights['adaptation_rate'] = '${completionRate.toStringAsFixed(1)}%';
          insights['completed_routines'] = stats['completed_routines'];
          insights['total_routines'] = stats['total_routines'];
          print('✅ 프론트에서 계산된 adaptation_rate: ${insights['adaptation_rate']}');
          print('📊 성공한 루틴: ${stats['completed_routines']}/${stats['total_routines']}');
        }
        
        // 디버깅: adaptation_rate 값 확인
        print('🔍 adaptation_rate 값: ${insights['adaptation_rate']}');
        print('🔍 insights 전체 키: ${insights.keys}');
        
        setState(() {
          _aiInsights = insights;
        });
        
        // 2. 생성된 인사이트를 로컬 캐시에 저장
        await _saveInsights(insights);
        
        // 3. 생성된 인사이트를 데이터베이스에 자동 저장
        try {
          final saveResponse = await ApiService().post(
            '/coaching/report',
            {
              'summary_insight': insights['summary_insight'] ?? '',
              'custom_coaching_phrase': insights['custom_coaching_phrase'] ?? '',
              'adaptation_rate': insights['adaptation_rate'] ?? '0%',
              'strengths': insights['coaching_insights']?['strengths'] ?? [],
              'improvements': insights['coaching_insights']?['improvements'] ?? [],
              'suggestions': insights['coaching_insights']?['suggestions'] ?? [],
              'weekly_patterns': insights['weekly_patterns'] ?? {},
              'weekly_chart': insights['weekly_chart'] ?? {},
            },
          );
          
          if (saveResponse['result'] == 'success' && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI 인사이트가 생성되고 저장되었습니다.'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (mounted) {
            // 저장 실패 시 경고 메시지 (인사이트는 이미 생성되었음)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('AI 인사이트는 생성되었지만 저장에 실패했습니다: ${saveResponse['msg']}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (saveError) {
          // 저장 중 오류 발생 시에도 인사이트는 사용 가능
          print('리포트 저장 중 오류 발생: $saveError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI 인사이트가 생성되었습니다. (저장 실패)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        print('❌ API 응답 실패: ${response['msg']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: ${response['msg']}')),
          );
        }
      }
    } catch (e) {
      print('❌ AI 인사이트 생성 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  Future<void> _exportToPDF() async {
    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // PDF 생성
      final pdfBytes = await PDFService.generateCoachingReportPDF();
      
      // 다이얼로그 닫기
      if (mounted) Navigator.pop(context);
      
      // PDF 미리보기 및 출력
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF가 생성되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 다이얼로그 닫기
      if (mounted) Navigator.pop(context);
      
      print('❌ PDF 생성 실패: $e');
      
      // 에러 메시지 추출
      String errorMessage = e.toString();
      if (errorMessage.contains('데이터가 없어 pdf를 생성할 수 없습니다')) {
        // 데이터 없음 팝업 표시
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('알림'),
              content: const Text('데이터가 없어 pdf를 생성할 수 없습니다.\n먼저 "AI 요약 생성" 버튼을 눌러 리포트를 생성해주세요.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      } else {
        // 기타 오류
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF 생성 중 오류가 발생했습니다: $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          '코칭 리포트',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 주요 기능 섹션
            _buildMainFeaturesSection(),
            
          const SizedBox(height: 20),
          
          // AI 대화 기능 섹션
          //_buildAIConversationSection(),
          
          const SizedBox(height: 20),
          
          // 리포트 샘플 UI 섹션
          _buildReportSampleSection(),
            
            const SizedBox(height: 100), // 하단 네비게이션 바 공간
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 5),
    );
  }

  Widget _buildMainFeaturesSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주요 기능 2 - 부모용 코칭 리포트',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // 기능 카드들
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icon: Ionicons.analytics_outline,
                  title: '요약 인사이트',
                  description: '아동의 루틴 이행력 및 패턴을 AI가 분석하여 요약된 인사이트를 제공합니다. 주간 추이 그래프와 핵심 지표로 한눈에 확인',
                  color: Colors.purple,
                  legendItems: [
                    LegendItem(color: Colors.green, label: '루틴 이행률')
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icon: Ionicons.chatbubbles_outline,
                  title: '맞춤 코칭 문구',
                  description: 'AI가 분석한 데이터를 기반으로 부모와 교사를 위한 실행 가능한 코칭 문구를 자동 생성합니다.',
                  color: Colors.purple,
                  exampleText: '코칭 예시: "민진이는 아침 루틴에는 잘 적응했지만, 저녁 루틴 지속력이 낮아요. 다음 주는 자기 전 이야기 루틴을 10분으로 늘려보는 게 좋아요."',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icon: Ionicons.share_social_outline,
                  title: '공유 기능',
                  description: '부모와 교사 간의 원활한 소통을 위해 맞춤형 권한 설정으로 리포트를 안전하게 공유할 수 있습니다.',
                  color: Colors.green,
                  actionButtons: [
                    ActionButton(icon: Ionicons.people_outline, label: '부모 뷰'),
                    ActionButton(icon: Ionicons.notifications_outline, label: '알림 설정'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    List<LegendItem>? legendItems,
    String? exampleText,
    List<ActionButton>? actionButtons,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          
          if (legendItems != null) ...[
            const SizedBox(height: 12),
            Row(
              children: legendItems.map((item) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
          
          if (exampleText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Ionicons.sparkles_outline, color: Colors.purple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exampleText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (actionButtons != null) ...[
            const SizedBox(height: 12),
            Row(
              children: actionButtons.map((button) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(button.icon, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        button.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  

  Widget _buildAIFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
    required Color color,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 기능 목록
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildReportSampleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '리포트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateAIInsights,
                    icon: _isGenerating 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Ionicons.sparkles_outline, size: 16),
                    label: Text(_isGenerating ? '생성 중...' : 'AI 요약 생성'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _aiInsights == null ? null : _exportToPDF,
                    icon: const Icon(Ionicons.document_text_outline, size: 16),
                    label: const Text('PDF로 내보내기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // AI 인사이트가 있을 때 표시
          if (_aiInsights != null) ...[
            _buildAIInsightsSection(),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAIInsightsSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Ionicons.sparkles, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI 인사이트',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 요약 인사이트
          if (_aiInsights!['summary_insight'] != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Ionicons.information_circle_outline, 
                    color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _aiInsights!['summary_insight'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // 맞춤 코칭 문구
          if (_aiInsights!['custom_coaching_phrase'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple[50]!,
                    Colors.purple[100]!.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '맞춤 코칭 문구',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Ionicons.chatbubble_ellipses_outline,
                        color: Colors.purple[700],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _aiInsights!['custom_coaching_phrase'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // 루틴 적응도
          Builder(
            builder: (context) {
              final adaptationRate = _aiInsights!['adaptation_rate'];
              final completedRoutines = _aiInsights!['completed_routines'];
              final totalRoutines = _aiInsights!['total_routines'];
              
              print('🎯 UI 렌더링: adaptation_rate = $adaptationRate');
              
              if (adaptationRate != null) {
                return Column(
                  children: [
                    _buildMainAdaptationRateBar(adaptationRate, completedRoutines, totalRoutines),
                    const SizedBox(height: 16),
                  ],
                );
              } else {
                print('⚠️ adaptation_rate가 null입니다. 모든 insights 키: ${_aiInsights!.keys}');
                return const SizedBox.shrink();
              }
            },
          ),
          
          // 주간 차트 (꺾은선 그래프)
          if (_aiInsights!['weekly_chart'] != null) ...[
            const SizedBox(height: 16),
            _buildWeeklyChart(_aiInsights!['weekly_chart']),
          ],
          
          // 코칭 인사이트
          if (_aiInsights!['coaching_insights'] != null) ...[
            const SizedBox(height: 16),
            ..._buildCoachingInsightsList(_aiInsights!['coaching_insights']),
          ],
        ],
      ),
    );
  }
  
  Widget _buildWeeklyChart(Map<String, dynamic> chartData) {
    final labels = (chartData['labels'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final values = (chartData['values_percent'] as List?)?.cast<dynamic>() ?? [];
    
    if (labels.isEmpty || values.isEmpty) return const SizedBox.shrink();
    
    // 값들을 숫자로 변환
    final List<double> numericValues = values.map((v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }).toList();
    
    // 최대값 찾기 (100%가 아닌 실제 데이터의 최대값)
    final maxValue = numericValues.isNotEmpty ? numericValues.reduce((a, b) => a > b ? a : b) : 100.0;
    // 최소 높이를 위해 최대값에 여유를 둠
    final adjustedMaxValue = maxValue < 20 ? maxValue * 1.5 : maxValue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주간 루틴 이행률',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // 꺾은선 그래프로 표시
        Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: LineChartPainter(
                    values: numericValues,
                    labels: labels,
                    maxValue: adjustedMaxValue,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: labels.asMap().entries.map((entry) {
                  final label = entry.value;
                  return Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black87,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _showBarDetails(String day, double percentage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$day요일 루틴 완료율'),
        content: Text('${percentage.toStringAsFixed(1)}%의 루틴을 완료했습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildCoachingInsightsList(Map<String, dynamic> insights) {
    final List<Widget> widgets = [];
    
    // 잘하고 있는 점
    if (insights['strengths'] != null && insights['strengths'].isNotEmpty) {
      widgets.add(_buildInsightSection(
        icon: Ionicons.thumbs_up_outline,
        title: '잘하고 있는 점',
        items: List<String>.from(insights['strengths']),
        color: Colors.green,
      ));
      widgets.add(const SizedBox(height: 16));
    }
    
    // 개선할 점
    if (insights['improvements'] != null && insights['improvements'].isNotEmpty) {
      widgets.add(_buildInsightSection(
        icon: Ionicons.search_outline,
        title: '개선할 점',
        items: List<String>.from(insights['improvements']),
        color: Colors.orange,
      ));
      widgets.add(const SizedBox(height: 16));
    }
    
    // 코칭 제안
    if (insights['suggestions'] != null && insights['suggestions'].isNotEmpty) {
      widgets.add(_buildInsightSection(
        icon: Ionicons.bulb_outline,
        title: '코칭 제안',
        items: List<String>.from(insights['suggestions']),
        color: Colors.blue,
      ));
    }
    
    return widgets;
  }
  
  Widget _buildMainAdaptationRateBar(dynamic adaptationRate, dynamic completedRoutines, dynamic totalRoutines) {
    if (adaptationRate == null) return const SizedBox.shrink();
    
    // 실제 루틴 수치 계산
    double completed = 0.0;
    double total = 1.0;
    
    if (completedRoutines != null) {
      if (completedRoutines is int) {
        completed = completedRoutines.toDouble();
      } else if (completedRoutines is double) {
        completed = completedRoutines;
      } else if (completedRoutines is String) {
        completed = double.tryParse(completedRoutines) ?? 0.0;
      }
    }
    
    if (totalRoutines != null) {
      if (totalRoutines is int) {
        total = totalRoutines.toDouble();
      } else if (totalRoutines is double) {
        total = totalRoutines;
      } else if (totalRoutines is String) {
        total = double.tryParse(totalRoutines) ?? 1.0;
      }
    }
    
    // completed와 total로부터 실제 비율 계산
    double calculatedRate = 0.0;
    if (total > 0) {
      calculatedRate = (completed / total) * 100.0;
    }
    
    // adaptation_rate가 있으면 그 값을 우선 사용
    double rate = calculatedRate;
    if (adaptationRate != null) {
      final rateString = adaptationRate.toString();
      final regex = RegExp(r'(\d+(?:\.\d+)?)');
      final match = regex.firstMatch(rateString);
      if (match != null) {
        rate = double.tryParse(match.group(1) ?? '0') ?? calculatedRate;
      }
    }
    
    print('🔍 rate 계산: completed=$completed, total=$total, calculatedRate=$calculatedRate, finalRate=$rate');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '루틴 이행률',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        
        // 퍼센트와 비율 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            Text(
              '$completed/$total',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 진행 바
        Stack(
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            FractionallySizedBox(
              widthFactor: rate / 100,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple[400]!,
                      Colors.purple[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildInsightSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }
}

class LegendItem {
  final Color color;
  final String label;

  LegendItem({required this.color, required this.label});
}

class ActionButton {
  final IconData icon;
  final String label;

  ActionButton({required this.icon, required this.label});
}

// AI 인사이트 상세 보기 화면
// 꺾은선 그래프를 그리는 CustomPainter
class LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxValue;

  LineChartPainter({
    required this.values,
    required this.labels,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final path = Path();
    final points = <Offset>[];
    
    // 전체 너비를 균등하게 분배 (요일과 점이 정확히 정렬되도록)
    final availableWidth = size.width;
    final itemWidth = availableWidth / values.length;
    final centerOffset = itemWidth / 2; // 각 구간의 중앙 지점

    // 데이터 포인트 생성 - 각 구간의 중앙에 위치
    for (int i = 0; i < values.length; i++) {
      final x = (i * itemWidth) + centerOffset;
      final y = size.height - (values[i] / maxValue) * size.height;
      points.add(Offset(x, y));
    }

    // 부드러운 곡선 경로 생성 - 모든 점을 지나가도록
    if (points.length == 1) {
      path.moveTo(points[0].dx, points[0].dy);
    } else if (points.length == 2) {
      path.moveTo(points[0].dx, points[0].dy);
      path.lineTo(points[1].dx, points[1].dy);
    } else {
      // Cubic spline을 사용하여 모든 점을 지나가는 부드러운 곡선 생성
      path.moveTo(points[0].dx, points[0].dy);
      
      for (int i = 0; i < points.length - 1; i++) {
        if (i == 0) {
          // 첫 번째 구간
          final xc = (points[i].dx + points[i + 1].dx) / 2;
          final yc = (points[i].dy + points[i + 1].dy) / 2;
          path.quadraticBezierTo(points[i].dx, points[i].dy, xc, yc);
        } else if (i == points.length - 2) {
          // 마지막 구간
          final xc = (points[i].dx + points[i + 1].dx) / 2;
          final yc = (points[i].dy + points[i + 1].dy) / 2;
          path.quadraticBezierTo(points[i].dx, points[i].dy, points[i + 1].dx, points[i + 1].dy);
        } else {
          // 중간 구간
          final xc = (points[i].dx + points[i + 1].dx) / 2;
          final yc = (points[i].dy + points[i + 1].dy) / 2;
          
          // 각 점을 지나가도록 제어점 조정
          final cp1x = points[i].dx;
          final cp1y = points[i].dy;
          final cp2x = xc;
          final cp2y = yc;
          
          path.cubicTo(cp1x, cp1y, cp2x, cp2y, points[i + 1].dx, points[i + 1].dy);
        }
      }
    }

    // 영역 채우기 (그라디언트)
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.purple[100]!.withOpacity(0.3),
          Colors.purple[50]!.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, gradientPaint);

    // 선 그리기
    final linePaint = Paint()
      ..color = Colors.purple[200]!
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // 캡슐형 마커 그리기
    final markerPaint = Paint()
      ..color = Colors.purple[400]!
      ..style = PaintingStyle.fill;

    for (final point in points) {
      final capsule = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: point,
          width: 8,
          height: 16,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(capsule, markerPaint);
    }

    // 값 텍스트 표시
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < points.length && i < values.length; i++) {
      textPainter.text = TextSpan(
        text: '${values[i].toStringAsFixed(0)}%',
        style: const TextStyle(
          fontSize: 9,
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          points[i].dx - textPainter.width / 2,
          points[i].dy - textPainter.height - 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.labels != labels;
  }
}
