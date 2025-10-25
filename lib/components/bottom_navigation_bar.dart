import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../constants/app_colors.dart';
import '../screens/home.dart';
import '../screens/character_selection_screen.dart';
import '../screens/voice_chat_screen.dart';
import '../screens/chatbot_screen.dart';
import '../routine/list_routine_screen.dart';
import '../info/myInfo.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) { // 캐릭터 탭
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CharacterSelectionScreen(),
              ),
            );
          } else if (index == 1) { // 음성 대화 탭
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VoiceChatScreen(),
              ),
            );
          } else if (index == 2) { // 홈 탭
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          } else if (index == 3) { // 챗봇 탭
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatbotScreen(),
              ),
            );
          } else if (index == 4) { // 루틴 탭
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ListRoutineScreen(),
              ),
            );
          } else if (index == 5) { // 마이페이지 탭
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyInfoScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Ionicons.people_circle_outline),
            label: '캐릭터',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.mic_outline),
            label: '음성대화',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.home_outline),
            activeIcon: Icon(Ionicons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.chatbubble_outline),
            label: '챗봇',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.calendar_outline),
            label: '루틴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.person_outline),
            label: '마이',
          ),
        ],
      ),
    );
  }
}
