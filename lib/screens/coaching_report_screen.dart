import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter/services.dart';
import '../components/bottom_navigation_bar.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CoachingReportScreen extends StatefulWidget {
  const CoachingReportScreen({super.key});

  @override
  State<CoachingReportScreen> createState() => _CoachingReportScreenState();
}

class _CoachingReportScreenState extends State<CoachingReportScreen> {
  bool _isGenerating = false;
  Map<String, dynamic>? _aiInsights;
  
  Future<void> _generateAIInsights() async {
    setState(() {
      _isGenerating = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      
      final response = await ApiService().get('/coaching/insights/$userId');
      
      if (response['result'] == 'success') {
        setState(() {
          _aiInsights = response['insights'];
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI 인사이트가 생성되었습니다.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: ${response['msg']}')),
          );
        }
      }
    } catch (e) {
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
  
  void _navigateToInsightsDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AIInsightsDetailScreen(insights: _aiInsights!),
      ),
    );
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
                  description: '아동의 루틴 적응도, 시간대별 집중력, 감정 패턴을 AI가 분석하여 요약된 인사이트를 제공합니다. 주/월간 추이 그래프와 핵심 지표로 한눈에 확인',
                  color: Colors.purple,
                  legendItems: [
                    LegendItem(color: Colors.green, label: '루틴 이행률'),
                    LegendItem(color: Colors.orange, label: '감정 상태'),
                    LegendItem(color: Colors.blue, label: '수면 패턴'),
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
                    ActionButton(icon: Ionicons.document_outline, label: 'PDF 내보내기'),
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
                  if (_aiInsights != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToInsightsDetail(),
                      icon: const Icon(Ionicons.arrow_forward_outline, size: 16),
                      label: const Text('상세 보기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Ionicons.heart_outline, 
                    color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _aiInsights!['custom_coaching_phrase'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // 루틴 적응도
          if (_aiInsights!['adaptation_rate'] != null) ...[
            _buildMainAdaptationRateBar(_aiInsights!['adaptation_rate']),
            const SizedBox(height: 16),
          ],
          
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
        
        // 간단한 막대 그래프로 표시 (꺾은선은 복잡함)
        Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: labels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final value = numericValues.length > index ? numericValues[index] : 0.0;
              
              return _buildWeeklyChartBar(value, label, adjustedMaxValue);
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWeeklyChartBar(double value, String label, double maxValue) {
    // 높이 비율 계산 (최소 10% 높이 보장)
    final heightFactor = value > 0 
        ? (value / maxValue).clamp(0.1, 1.0)
        : 0.0;
    
    return Expanded(
      child: GestureDetector(
        onTap: value > 0 ? () => _showBarDetails(label, value) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: FractionallySizedBox(
                  heightFactor: heightFactor,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.purple[600]!,
                          Colors.purple[400]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: value > 0
                        ? Center(
                            child: Text(
                              '${value.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[value > 0 ? 800 : 400],
                  fontWeight: value > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
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
  
  Widget _buildMainAdaptationRateBar(String? adaptationRate) {
    if (adaptationRate == null) return const SizedBox.shrink();
    
    // adaptation_rate에서 숫자만 추출
    final regex = RegExp(r'(\d+(?:\.\d+)?)%');
    final match = regex.firstMatch(adaptationRate);
    double rate = 0.0;
    
    if (match != null) {
      rate = double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '루틴 적응도',
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
              '${rate.toInt()}/100',
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
class _AIInsightsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> insights;
  
  const _AIInsightsDetailScreen({required this.insights});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'AI 인사이트 상세',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.share_outline),
            onPressed: () => _shareInsightsAsText(context),
            tooltip: '텍스트로 공유',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 요약 인사이트
            if (insights['summary_insight'] != null)
              _buildSectionCard(
                title: '요약 인사이트',
                icon: Ionicons.information_circle_outline,
                iconColor: Colors.blue,
                child: Text(
                  insights['summary_insight'],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 맞춤 코칭 문구
            if (insights['custom_coaching_phrase'] != null)
              _buildSectionCard(
                title: '맞춤 코칭 문구',
                icon: Ionicons.heart_outline,
                iconColor: Colors.red,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    insights['custom_coaching_phrase'],
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 루틴 적응도
            if (insights['adaptation_rate'] != null)
              _buildSectionCard(
                title: '루틴 적응도',
                icon: Ionicons.stats_chart_outline,
                iconColor: Colors.purple,
                child: _buildAdaptationRateBar(insights['adaptation_rate']),
              ),
            
            const SizedBox(height: 16),
            
            // 코칭 인사이트
            if (insights['coaching_insights'] != null) ...[
              const SizedBox(height: 8),
              const Text(
                '코칭 인사이트',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              
              ..._buildDetailedInsights(insights['coaching_insights']),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
  
  List<Widget> _buildDetailedInsights(Map<String, dynamic> coachingInsights) {
    final List<Widget> widgets = [];
    
    // 잘하고 있는 점
    if (coachingInsights['strengths'] != null && coachingInsights['strengths'].isNotEmpty) {
      widgets.add(_buildDetailedInsightCard(
        title: '잘하고 있는 점',
        icon: Ionicons.thumbs_up_outline,
        iconColor: Colors.green,
        items: List<String>.from(coachingInsights['strengths']),
        backgroundColor: Colors.green[50]!,
      ));
      widgets.add(const SizedBox(height: 16));
    }
    
    // 개선할 점
    if (coachingInsights['improvements'] != null && coachingInsights['improvements'].isNotEmpty) {
      widgets.add(_buildDetailedInsightCard(
        title: '개선할 점',
        icon: Ionicons.search_outline,
        iconColor: Colors.orange,
        items: List<String>.from(coachingInsights['improvements']),
        backgroundColor: Colors.orange[50]!,
      ));
      widgets.add(const SizedBox(height: 16));
    }
    
    // 코칭 제안
    if (coachingInsights['suggestions'] != null && coachingInsights['suggestions'].isNotEmpty) {
      widgets.add(_buildDetailedInsightCard(
        title: '코칭 제안',
        icon: Ionicons.bulb_outline,
        iconColor: Colors.blue,
        items: List<String>.from(coachingInsights['suggestions']),
        backgroundColor: Colors.blue[50]!,
      ));
    }
    
    return widgets;
  }
  
  Widget _buildDetailedInsightCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildAdaptationRateBar(String? adaptationRate) {
    if (adaptationRate == null) return const SizedBox.shrink();
    
    // adaptation_rate에서 숫자만 추출 (예: "민수의 1주일간 루틴 적응도 75%" -> 75)
    final regex = RegExp(r'(\d+)%');
    final match = regex.firstMatch(adaptationRate);
    double rate = 0.0;
    
    if (match != null) {
      rate = double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 퍼센트 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$rate%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
              Text(
                '${rate.toInt()}/100',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 진행 바
          Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              FractionallySizedBox(
                widthFactor: rate / 100,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple[400]!,
                        Colors.purple[600]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _shareInsightsAsText(BuildContext context) {
    final StringBuffer text = StringBuffer();
    
    text.writeln('📊 AI 코칭 인사이트 리포트');
    text.writeln('=' * 50);
    text.writeln();
    
    // 요약 인사이트
    if (insights['summary_insight'] != null) {
      text.writeln('📌 요약 인사이트');
      text.writeln('-' * 50);
      text.writeln(insights['summary_insight']);
      text.writeln();
    }
    
    // 맞춤 코칭 문구
    if (insights['custom_coaching_phrase'] != null) {
      text.writeln('❤️ 맞춤 코칭 문구');
      text.writeln('-' * 50);
      text.writeln(insights['custom_coaching_phrase']);
      text.writeln();
    }
    
    // 루틴 적응도
    if (insights['adaptation_rate'] != null) {
      text.writeln('📈 루틴 적응도');
      text.writeln('-' * 50);
      text.writeln(insights['adaptation_rate']);
      text.writeln();
    }
    
    // 코칭 인사이트
    if (insights['coaching_insights'] != null) {
      final coachingInsights = insights['coaching_insights'] as Map<String, dynamic>;
      
      // 잘하고 있는 점
      if (coachingInsights['strengths'] != null && 
          (coachingInsights['strengths'] as List).isNotEmpty) {
        text.writeln('✅ 잘하고 있는 점');
        text.writeln('-' * 50);
        for (int i = 0; i < (coachingInsights['strengths'] as List).length; i++) {
          text.writeln('${i + 1}. ${coachingInsights['strengths'][i]}');
        }
        text.writeln();
      }
      
      // 개선할 점
      if (coachingInsights['improvements'] != null && 
          (coachingInsights['improvements'] as List).isNotEmpty) {
        text.writeln('🔍 개선할 점');
        text.writeln('-' * 50);
        for (int i = 0; i < (coachingInsights['improvements'] as List).length; i++) {
          text.writeln('${i + 1}. ${coachingInsights['improvements'][i]}');
        }
        text.writeln();
      }
      
      // 코칭 제안
      if (coachingInsights['suggestions'] != null && 
          (coachingInsights['suggestions'] as List).isNotEmpty) {
        text.writeln('💡 코칭 제안');
        text.writeln('-' * 50);
        for (int i = 0; i < (coachingInsights['suggestions'] as List).length; i++) {
          text.writeln('${i + 1}. ${coachingInsights['suggestions'][i]}');
        }
        text.writeln();
      }
    }
    
    text.writeln('=' * 50);
    text.writeln('ROUTY - ADHD 아동 루틴 관리 앱');
    
    final textToShare = text.toString();
    
    // 클립보드에 복사
    Clipboard.setData(ClipboardData(text: textToShare));
    
    // 사용자에게 알림
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('텍스트가 클립보드에 복사되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
