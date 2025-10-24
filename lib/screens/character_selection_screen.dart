import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import '../constants/app_colors.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  
  // 캐릭터 데이터
  final List<CharacterData> _characters = [
    CharacterData(
      id: 1,
      name: '루티',
      description: '활발하고 에너지가 넘치는 캐릭터',
      emoji: '🤖',
      color: AppColors.primary,
      personality: '활발함',
      age: '5세',
    ),
    CharacterData(
      id: 2,
      name: '미니',
      description: '조용하고 차분한 성격의 캐릭터',
      emoji: '🧸',
      color: Colors.pink,
      personality: '차분함',
      age: '4세',
    ),
    CharacterData(
      id: 3,
      name: '스마트',
      description: '똑똑하고 호기심이 많은 캐릭터',
      emoji: '🎓',
      color: Colors.blue,
      personality: '똑똑함',
      age: '6세',
    ),
    CharacterData(
      id: 4,
      name: '체리',
      description: '사랑스럽고 귀여운 캐릭터',
      emoji: '🍒',
      color: Colors.red,
      personality: '사랑스러움',
      age: '3세',
    ),
    CharacterData(
      id: 5,
      name: '스타',
      description: '밝고 긍정적인 에너지의 캐릭터',
      emoji: '⭐',
      color: Colors.amber,
      personality: '긍정적',
      age: '7세',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: _currentIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(
                Ionicons.people_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '캐릭터 선택',
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
          statusBarColor: Color(0xFFF9FAFB),
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              
              // 안내 텍스트
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '나와 함께할 캐릭터를 선택해주세요!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 10),
            
              // 캐릭터 카드들
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                //padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 400,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _characters.length,
                  itemBuilder: (context, index) {
                    return _buildCharacterCard(_characters[index], index);
                  },
                ),
              ),
              
              //const SizedBox(height: 30),
              
              // 선택된 캐릭터 정보
              _buildSelectedCharacterInfo(),
              
              const SizedBox(height: 30),
              
              // 선택 버튼
              _buildSelectionButton(),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
    );
  }

  Widget _buildCharacterCard(CharacterData character, int index) {
    final isSelected = index == _currentIndex;
    final offset = (index - _currentIndex).abs();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isSelected ? 15 : 20 + (offset * 10),
      ),
      child: Transform.scale(
        scale: isSelected ? 1.0 : 0.9 - (offset * 0.1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.05),
                blurRadius: isSelected ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // 배경 그라데이션
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        character.color.withValues(alpha: 0.1),
                        character.color.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                
                // 블러 효과 (선택되지 않은 카드)
                if (!isSelected)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                
                // 캐릭터 내용
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 캐릭터 이모지
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: character.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: character.color,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            character.emoji,
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 캐릭터 이름
                      Text(
                        character.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.grey,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 캐릭터 설명
                      Text(
                        character.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.grey[700] : Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // 캐릭터 특성
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildCharacterTrait(
                              icon: Ionicons.heart_outline,
                              label: character.personality,
                              color: character.color,
                              isSelected: isSelected,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCharacterTrait(
                              icon: Ionicons.calendar_outline,
                              label: character.age,
                              color: character.color,
                              isSelected: isSelected,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                
                // 선택 표시
                if (isSelected)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: character.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Ionicons.checkmark,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterTrait({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Flexible( 
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCharacterInfo() {
    final selectedCharacter = _characters[_currentIndex];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
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
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: selectedCharacter.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    selectedCharacter.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '선택된 캐릭터: ${selectedCharacter.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedCharacter.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: _characters[_currentIndex].color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _characters[_currentIndex].color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleCharacterSelection,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _characters[_currentIndex].emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              '이 캐릭터와 함께하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCharacterSelection() {
    final selectedCharacter = _characters[_currentIndex];
    
    // 선택된 캐릭터 정보를 다이얼로그로 표시
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Text(selectedCharacter.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(selectedCharacter.name),
            ],
          ),
          content: Text('${selectedCharacter.name}와 함께하는 여정을 시작하시겠습니까?'),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('시작하기'),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 캐릭터 선택 완료 처리
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${selectedCharacter.name}와 함께하는 여정을 시작합니다!'),
                    backgroundColor: selectedCharacter.color,
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class CharacterData {
  final int id;
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final String personality;
  final String age;

  CharacterData({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.personality,
    required this.age,
  });
}
