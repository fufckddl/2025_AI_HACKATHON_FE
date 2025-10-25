import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../components/bottom_navigation_bar.dart';

class CoachingReportScreen extends StatefulWidget {
  const CoachingReportScreen({super.key});

  @override
  State<CoachingReportScreen> createState() => _CoachingReportScreenState();
}

class _CoachingReportScreenState extends State<CoachingReportScreen> {
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
          _buildAIConversationSection(),
          
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

  Widget _buildAIConversationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI 대화 기능',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // AI 대화 기억 기능
          _buildAIFeatureCard(
            icon: Ionicons.analytics_outline,
            title: 'AI가 이전 대화 내용을 기억하는 기능',
            description: '이 플로우에서 대화 기억 기능이 구현되어 있습니다:',
            features: [
              'state.query 업데이트: "First update of the state.query"와 "Second update of state.query" 노드가 보입니다. 이는 시스템이 대화 상태를 지속적으로 업데이트하고 있음을 의미합니다.',
              '맥락 유지: gpt-4o-mini 모델이 사용되는 모든 단계("Generate Query", "Generate Response", "Regenerate Question" 등)에서 이전 대화 내용이 포함된 state.query를 활용할 수 있습니다.',
              '반복적 개선: "Regenerate Question" → "Loop back to Retriever" 과정을 통해 AI가 이전 대화 맥락을 바탕으로 질문을 재구성하고 더 나은 응답을 생성할 수 있습니다.',
            ],
            color: Colors.purple,
          ),
          
          const SizedBox(height: 12),
          
          // AI 페르소나 설정
          _buildAIFeatureCard(
            icon: Ionicons.person_outline,
            title: 'AI 페르소나/능력 프롬프트 삽입',
            description: '다음과 같은 방법으로 구현할 수 있습니다:',
            features: [
              '시스템 프롬프트 추가: 각 gpt-4o-mini 호출 시 입력에 시스템 프롬프트를 포함',
              '주요 삽입 지점: "Generate Query" 단계, "Generate Response" 단계, "Regenerate Question" 단계',
              '예시 프롬프트: "너는 ADHD 아동을 위한 루틴 관리 AI야. 능력: 루틴 계획, 집중력 향상 도구 제공, 동기부여. 감정: 따뜻하고 격려적이며, 아이의 성취를 축하하는 성격"',
            ],
            color: Colors.blue,
          ),
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
          const Text(
            '리포트 샘플 UI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildWeeklyReportCard(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCoachingInsightsCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyReportCard() {
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
              const Text(
                '민진이 | 2025년10월3주',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '완료율 78%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            '루틴 적응도',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 진행률 바
          LinearProgressIndicator(
            value: 0.78,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          
          const SizedBox(height: 12),
          
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Ionicons.trending_up_outline, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              const Text(
                '이전 주 대비 12% 향상',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildCoachingInsightsCard() {
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
          const Text(
            '코칭 인사이트',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildInsightSection(
            icon: Ionicons.thumbs_up_outline,
            title: '잘하고 있는 점',
            items: [
              '아침 8시 기상 루틴 5일 연속 달성',
              '숙제 전 휴식시간 규칙적 지키기',
            ],
            color: Colors.green,
          ),
          
          const SizedBox(height: 16),
          
          _buildInsightSection(
            icon: Ionicons.search_outline,
            title: '개선할 점',
            items: [
              '금요일 저녁 루틴 이행률 저조',
              '주말 수면시간 불규칙',
            ],
            color: Colors.orange,
          ),
          
          const SizedBox(height: 16),
          
          _buildInsightSection(
            icon: Ionicons.bulb_outline,
            title: '코칭 제안',
            items: [
              '취침 30분 전 책읽기 활동 추가',
              '주말에도 일정한 기상시간 유지하기',
            ],
            color: Colors.blue,
          ),
        ],
      ),
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
