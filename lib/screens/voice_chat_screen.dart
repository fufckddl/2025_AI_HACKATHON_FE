import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import 'character_selection_screen.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  bool _isListening = false;
  List<Map<String, dynamic>> _conversationHistory = [];

  // 타이핑 애니메이션 관련 변수
  String _typingText = '';
  bool _isTyping = false;
  Timer? _typingTimer;
  int _typingIndex = 0;

  // Speech to Text 관련 변수들
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  String _lastWords = '';
  String _currentWords = '';
  String _selectedLocale = '';

  // 스크롤 컨트롤러 추가
  late ScrollController _scrollController;

  // 실시간 대화 관련 변수들
  Timer? _silenceTimer;
  bool _isWaitingForResponse = false;
  bool _isProcessingResponse = false;

  // 자동 재녹음 제어: 사용자가 녹음 버튼을 눌러 활성화했는지 여부
  bool _shouldAutoListen = false;

  // 재시작 관련 (fallback만 유지, 주 흐름은 silence timer 기반)
  int _restartAttempts = 0;
  final int _maxRestartAttempts = 3;
  bool _isRestarting = false;

  late AnimationController _characterAnimationController;
  late AnimationController _micAnimationController;
  late AnimationController _talkingAnimationController;
  late Animation<double> _characterBounceAnimation;
  late Animation<double> _micPulseAnimation;
  late Animation<double> _talkingPulseAnimation;

  // 선택된 캐릭터 정보
  String? _selectedCharacterId;
  String? _selectedCharacterName;
  String? _selectedCharacterImage;

  @override
  void initState() {
    super.initState();

    // 스크롤 컨트롤러 초기화
    _scrollController = ScrollController();

    // 선택된 캐릭터 로드
    _loadSelectedCharacter();

    // Speech to Text 초기화
    _speech = stt.SpeechToText();
    _initSpeech();

    // 캐릭터 애니메이션 컨트롤러
    _characterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 마이크 애니메이션 컨트롤러
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 대화 애니메이션 컨트롤러 (AI가 말할 때 박스 크기 변화)
    _talkingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 캐릭터 바운스 애니메이션
    _characterBounceAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _characterAnimationController,
      curve: Curves.elasticInOut,
    ));

    // 마이크 펄스 애니메이션
    _micPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _micAnimationController,
      curve: Curves.easeInOut,
    ));

    // 대화 펄스 애니메이션 (1.0 -> 1.08 -> 1.0)
    _talkingPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _talkingAnimationController,
      curve: Curves.easeInOut,
    ));

    // 캐릭터 애니메이션 상태 리스너 추가
    _characterAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _characterAnimationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _characterAnimationController.reset();
      }
    });
  }

  @override
  void dispose() {
    // 타이머 정리
    _silenceTimer?.cancel();
    _typingTimer?.cancel();

    // Speech to Text 안전 정리 (예외 무시)
    try {
      if (_speech.isListening) {
        _speech.stop();
      }
    } catch (_) {}
    try {
      _speech.cancel();
    } catch (_) {}

    _characterAnimationController.dispose();
    _micAnimationController.dispose();
    _talkingAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 선택된 캐릭터 로드 (DB에서 가져오기)
  Future<void> _loadSelectedCharacter() async {
    try {
      // 사용자 ID 가져오기
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId == null) {
        print('❌ 사용자 ID가 없습니다.');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCharacterNotSelectedDialog();
          });
        }
        return;
      }
      
      print('🔍 사용자 정보 조회 중... (userId: $userId)');
      
      // DB에서 사용자 정보 조회
      final response = await ApiService().get('/home/$userId');
      
      if (response['result'] == 'success' && response['data'] != null) {
        final userData = response['data'];
        final characterId = userData['character_id'];
        
        print('🔍 DB에서 조회된 character_id: $characterId');
        
        if (characterId == null || characterId.toString().isEmpty) {
          // 캐릭터가 선택되지 않은 경우
          print('⚠️ 캐릭터가 선택되지 않음 - 팝업 표시 예정');
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('📢 캐릭터 미선택 팝업 표시');
              _showCharacterNotSelectedDialog();
            });
          }
          return;
        }

        // 캐릭터 정보 로드
        final characterIdStr = characterId.toString();
        setState(() {
          _selectedCharacterId = characterIdStr;
        });

        // 캐릭터 ID에 따라 이름과 이미지 설정
        _setCharacterInfo(characterIdStr);
        
        print('✅ 선택된 캐릭터 ID: $characterIdStr');
        
        // 초기 메시지 추가
        if (mounted) {
          _addBotMessage('안녕하세요! 무엇을 도와드릴까요?');
        }
      } else {
        print('❌ 사용자 정보 조회 실패: ${response['msg']}');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCharacterNotSelectedDialog();
          });
        }
      }
    } catch (e) {
      print('❌ 캐릭터 로드 실패: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCharacterNotSelectedDialog();
        });
      }
    }
  }

  // 캐릭터 ID에 따라 정보 설정
  void _setCharacterInfo(String characterId) {
    switch (characterId) {
      case '1':
        _selectedCharacterName = '루티';
        _selectedCharacterImage = 'images/bear.png';
        break;
      case '2':
        _selectedCharacterName = '미니';
        _selectedCharacterImage = '🧸';
        break;
      case '3':
        _selectedCharacterName = '스마트';
        _selectedCharacterImage = '🎓';
        break;
      case '4':
        _selectedCharacterName = '체리';
        _selectedCharacterImage = '🍒';
        break;
      case '5':
        _selectedCharacterName = '스타';
        _selectedCharacterImage = '⭐';
        break;
      default:
        _selectedCharacterName = '루티';
        _selectedCharacterImage = 'images/bear.png';
    }
  }

  // 캐릭터 미선택 다이얼로그 표시
  void _showCharacterNotSelectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                '캐릭터를 선택해주세요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '음성 대화를 사용하려면 먼저 캐릭터를 선택해야 합니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context); // 음성 대화 화면 닫기
              },
              child: const Text(
                '나중에',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CharacterSelectionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                '캐릭터 선택하러 가기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Speech to Text 초기화
  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (error) {
          print('음성 인식 오류: ${error.errorMsg}');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('음성 인식 오류: ${error.errorMsg}'),
              backgroundColor: Colors.red,
            ),
          );
          if (mounted) {
            setState(() {
              _speechEnabled = false;
            });
          }
        },
        onStatus: (status) {
          // status 이벤트는 보조적 정보. 의도치 않은 notListening이 발생하면 fallback 처리.
          print('음성 인식 상태: $status (현재 텍스트: "$_currentWords", 처리중: $_isProcessingResponse, 듣기중: $_isListening)');
          if (!mounted) return;
          
          // notListening 상태가 되어도 _isListening을 false로 설정하지 않음
          // 우리가 직접 _stopListening()을 호출할 때만 _isListening을 false로 설정
          if (status == 'notListening' && _isListening && !_isProcessingResponse) {
            // fallback: 짧은 지연 후 한 번만 재시도
            if (!_isRestarting) {
              print('fallback 재시작 시도');
              _attemptFallbackRestart();
            }
          }
        },
      );

      // 초기화 성공 시에만 로케일 확인
      if (_speechEnabled) {
        final locales = await _speech.locales();
        if (locales.isNotEmpty) {
          final koreanLocale = locales.firstWhere(
            (locale) => locale.localeId.startsWith('ko'),
            orElse: () => locales.first,
          );
          _selectedLocale = koreanLocale.localeId;
          print('선택된 로케일: $_selectedLocale');
        }
      }

      print('음성 인식 초기화: $_speechEnabled');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('음성 인식 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('음성 인식 초기화에 실패했습니다. 마이크 권한을 확인해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _speechEnabled = false;
        });
      }
    }
  }

  void _addBotMessage(String message) {
    if (!mounted) return;
    
    // 타이핑 애니메이션 시작
    _startTypingAnimation(message);
  }

  // 타이핑 애니메이션 시작
  void _startTypingAnimation(String fullText) {
    _typingTimer?.cancel();
    _typingText = '';
    _typingIndex = 0;
    _isTyping = true;

    // 먼저 빈 메시지를 추가
    _conversationHistory.add({
      'type': 'bot',
      'message': '',
      'timestamp': DateTime.now(),
      'isTyping': true,
    });

    // 타이핑 애니메이션 시작
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_typingIndex < fullText.length) {
        setState(() {
          _typingText = fullText.substring(0, _typingIndex + 1);
          // 마지막 메시지 업데이트
          _conversationHistory[_conversationHistory.length - 1] = {
            'type': 'bot',
            'message': _typingText,
            'timestamp': _conversationHistory[_conversationHistory.length - 1]['timestamp'],
            'isTyping': true,
          };
          _typingIndex++;
        });
        _scrollToEnd();
      } else {
        // 타이핑 완료
        timer.cancel();
        setState(() {
          _isTyping = false;
          // 타이핑 완료된 메시지로 업데이트
          _conversationHistory[_conversationHistory.length - 1] = {
            'type': 'bot',
            'message': fullText,
            'timestamp': _conversationHistory[_conversationHistory.length - 1]['timestamp'],
          };
        });
        
        // 타이핑 완료 시 펄스 애니메이션 중지
        if (_talkingAnimationController.isAnimating) {
          _talkingAnimationController.stop();
          _talkingAnimationController.reset();
        }
      }
    });
  }

  void _addUserMessage(String message) {
    if (!mounted) return;
    setState(() {
      _conversationHistory.add({
        'type': 'user',
        'message': message,
        'timestamp': DateTime.now(),
      });
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
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

  // 침묵 타이머 시작 (요구: 사용자가 3초 이상 반응 없으면 녹음 종료)
  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    print('침묵 타이머 시작 (3초)');
    _silenceTimer = Timer(const Duration(seconds: 3), () {
      print('침묵 타이머 만료 - 현재 텍스트: "$_currentWords", 처리중: $_isProcessingResponse, 듣기중: $_isListening');
      if (_isListening && _currentWords.isNotEmpty && !_isProcessingResponse) {
        print('사용자 음성 처리 시작');
        _processUserSpeech();
      } else if (_isListening && _currentWords.isEmpty && !_isProcessingResponse) {
        // 사용자가 3초 동안 전혀 말하지 않았을 경우 녹음 종료
        print('침묵으로 인한 녹음 종료');
        _stopListening();
      } else {
        print('침묵 타이머 조건 불만족 - 듣기중: $_isListening, 텍스트있음: ${_currentWords.isNotEmpty}, 처리중: $_isProcessingResponse');
      }
    });
  }

  // 침묵 타이머 취소
  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
  }

  // STT 결과를 JSON 형태로 변환
  String _convertSTTToJson(String recognizedText) {
    final sttData = {
      'timestamp': DateTime.now().toIso8601String(),
      'text': recognizedText,
      'language': _selectedLocale,
      'confidence': 'high', // 실제 STT 결과에서는 confidence 값 제공 시 사용
      'session_id': _selectedCharacterId ?? 'unknown',
      'metadata': {
        'character_id': _selectedCharacterId,
        'character_name': _selectedCharacterName,
        'is_listening': _isListening,
        'speech_enabled': _speechEnabled,
      }
    };
    
    // JSON 문자열로 변환 (indent 옵션으로 보기 좋게)
    final jsonString = jsonEncode(sttData);
    // 들여쓰기 추가 (단순 format)
    return _formatJson(jsonString);
  }
  
  // JSON 포맷팅 (들여쓰기 추가)
  String _formatJson(String jsonString) {
    final buffer = StringBuffer();
    int indent = 0;
    bool inString = false;
    
    for (int i = 0; i < jsonString.length; i++) {
      final char = jsonString[i];
      
      if (char == '"' && (i == 0 || jsonString[i - 1] != '\\')) {
        inString = !inString;
      }
      
      if (!inString) {
        if (char == '{' || char == '[') {
          buffer.writeln('${'  ' * indent}$char');
          indent++;
        } else if (char == '}' || char == ']') {
          indent--;
          buffer.writeln('${'  ' * indent}$char');
        } else if (char == ',') {
          buffer.writeln(',');
        } else if (char != ' ' && char != '\n') {
          buffer.write(char);
        }
      } else {
        buffer.write(char);
      }
    }
    
    return buffer.toString();
  }

  // 사용자 음성 처리 (비동기 흐름: stop -> add user msg -> AI 응답 -> 재녹음)
  Future<void> _processUserSpeech() async {
    print('_processUserSpeech 호출됨 - 처리중: $_isProcessingResponse, 텍스트: "$_currentWords", 마지막텍스트: "$_lastWords"');
    if (_isProcessingResponse) {
      print('이미 처리 중이므로 리턴');
      return;
    }
    if (_currentWords.isEmpty || _currentWords == _lastWords) {
      print('텍스트가 비어있거나 마지막 텍스트와 같으므로 리턴');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isProcessingResponse = true;
      _isWaitingForResponse = true;
    });

    // 멈춰야 할 경우(녹음 중지) 먼저 stop
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      print('stop 실패 (processUserSpeech): $e');
    }

    // 사용자 음성 텍스트 확정
    _lastWords = _currentWords;
    final capturedText = _currentWords;
    print('사용자 메시지 추가: "$capturedText"');

    // STT 결과를 JSON 형태로 변환 및 출력
    final sttJson = _convertSTTToJson(capturedText);
    print('📝 STT 결과 (JSON):\n$sttJson');

    // 클리어 현재 텍스트 (UI는 user message 추가 후 비움)
    if (!mounted) return;
    _addUserMessage(capturedText);
    print('사용자 메시지 추가 완료');

    // AI 응답 생성(실제 연동 시 여기에 API 호출)
    print('AI 응답 생성 시작');
    await _generateBotResponseAsync(capturedText);
    print('AI 응답 생성 완료');

    // AI 응답 종료
    if (!mounted) return;
    setState(() {
      _isProcessingResponse = false;
      _isWaitingForResponse = false;
      _currentWords = '';
    });

    // 자동 재녹음: 사용자가 녹음 버튼으로 활성화했으면 재시작
    if (_shouldAutoListen) {
      // 타이핑이 완료될 때까지 대기
      while (_isTyping && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // 짧은 대기 후 재녹음 재개
      await Future.delayed(const Duration(milliseconds: 300));
      if (_shouldAutoListen && mounted) {
        _startListening();
      }
    }
  }

  // 간단한 fallback 재시작 시도 (지수 백오프)
  void _attemptFallbackRestart() {
    if (_isRestarting) return;
    if (!_isListening || _isProcessingResponse) return;
    _isRestarting = true;
    _restartAttempts++;
    final delayMs = 500 * (1 << (_restartAttempts - 1));
    Future.delayed(Duration(milliseconds: delayMs), () async {
      if (!_isListening || _isProcessingResponse) {
        _isRestarting = false;
        return;
      }
      try {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 150));
        await _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            
            // 실시간 STT 결과를 JSON으로 변환 및 출력
            if (result.recognizedWords.isNotEmpty) {
              final sttJson = _convertSTTToJson(result.recognizedWords);
              print('📝 실시간 STT 결과 (JSON - fallback):\n$sttJson');
            }
            
            setState(() {
              _currentWords = result.recognizedWords;
            });
            if (result.recognizedWords.isNotEmpty && !_isProcessingResponse) {
              _startSilenceTimer();
            }
          },
          localeId: _selectedLocale.isNotEmpty ? _selectedLocale : null,
          listenFor: const Duration(minutes: 30),
          pauseFor: const Duration(seconds: 10),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
          onSoundLevelChange: (level) {
            if (!mounted) return;
            if (level > 0.01 && !_isProcessingResponse) {
              _startSilenceTimer();
            }
          },
        );
        // 성공
        _restartAttempts = 0;
      } catch (e) {
        print('fallback restart 실패: $e');
        if (_restartAttempts >= _maxRestartAttempts) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('음성 인식이 불안정합니다. 다시 시도해 주세요.'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() {
              _isListening = false;
            });
          }
        }
      } finally {
        _isRestarting = false;
      }
    });
  }

  // 녹음 시작 (사용자가 버튼을 눌러 수동으로 시작)
  void _startListening() async {
    if (!_speechEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('음성 인식이 지원되지 않습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 사용자 의도: 자동 반복 흐름 활성화
    _shouldAutoListen = true;

    if (!mounted) return;
    print('_startListening: _isListening을 true로 설정');
    setState(() {
      _isListening = true;
      _currentWords = '';
      _isWaitingForResponse = false;
    });
    print('_startListening: setState 완료, _isListening: $_isListening');

    print('음성 인식 시작');

    try {
      final localeArg = _selectedLocale.isNotEmpty ? _selectedLocale : null;

      // listen 호출 (결과는 onResult로 처리)
      if (localeArg != null) {
        await _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            print('onResult: 인식된 텍스트: "${result.recognizedWords}", _isListening: $_isListening');
            
            // 실시간 STT 결과를 JSON으로 변환 및 출력
            if (result.recognizedWords.isNotEmpty) {
              final sttJson = _convertSTTToJson(result.recognizedWords);
              print('📝 실시간 STT 결과 (JSON):\n$sttJson');
            }
            
            // 실시간 업데이트
            setState(() {
              _currentWords = result.recognizedWords;
            });

            // 텍스트가 들어오면 silence 타이머 재시작
            if (result.recognizedWords.isNotEmpty && !_isProcessingResponse) {
              print('onResult: 침묵 타이머 재시작');
              _startSilenceTimer();
            }
          },
          localeId: localeArg,
          listenFor: const Duration(minutes: 30),
          pauseFor: const Duration(seconds: 10),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          onSoundLevelChange: (level) {
            if (!mounted) return;
            if (level > 0.01 && !_isProcessingResponse) {
              _startSilenceTimer();
            }
          },
        );
      } else {
        await _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            print('onResult (no locale): 인식된 텍스트: "${result.recognizedWords}", _isListening: $_isListening');
            
            // 실시간 STT 결과를 JSON으로 변환 및 출력
            if (result.recognizedWords.isNotEmpty) {
              final sttJson = _convertSTTToJson(result.recognizedWords);
              print('📝 실시간 STT 결과 (JSON):\n$sttJson');
            }
            
            setState(() {
              _currentWords = result.recognizedWords;
            });
            if (result.recognizedWords.isNotEmpty && !_isProcessingResponse) {
              print('onResult (no locale): 침묵 타이머 재시작');
              _startSilenceTimer();
            }
          },
          listenFor: const Duration(minutes: 30),
          pauseFor: const Duration(seconds: 10),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          onSoundLevelChange: (level) {
            if (!mounted) return;
            if (level > 0.01 && !_isProcessingResponse) {
              _startSilenceTimer();
            }
          },
        );
      }

      // listen 호출 후 상태 확인 (실패 시에만 롤백)
      print('listen 호출 완료, _speech.isListening: ${_speech.isListening}');
      // _isListening은 이미 true로 설정되어 있으므로 그대로 유지
      // 실패한 경우에만 롤백
    } catch (e) {
      print('음성 인식 시작 실패: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('음성 인식 시작에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 녹음 중지 (사용자가 버튼을 눌러 중지 or 타이머에 의해 중지)
  void _stopListening() async {
    // disable auto-restart when user explicitly stops
    _shouldAutoListen = false;

    if (!_isListening) return;

    if (!mounted) return;
    setState(() {
      _isListening = false;
    });

    // 침묵 타이머 취소
    _cancelSilenceTimer();

    try {
      await _speech.stop();
    } catch (e) {
      print('음성 인식 중지 실패: $e');
    }

    // 현재 인식된 텍스트가 있으면 처리 (비동기 흐름으로 이어짐)
    if (_currentWords.isNotEmpty && _currentWords != _lastWords) {
      await _processUserSpeech();
    }
  }

  // AI 응답 생성 (동기식으로 기다리는 모사 함수)
  Future<void> _generateBotResponseAsync(String userMessage) async {
    // 대화 애니메이션 시작 (AI가 말하고 있다는 신호)
    if (!_talkingAnimationController.isAnimating) {
      _talkingAnimationController.repeat(reverse: true);
    } else {
      // 이미 애니메이션이 실행 중이면 다시 시작
      _talkingAnimationController.repeat(reverse: true);
    }
    
    // 실제 AI 호출 자리. 여기선 시뮬레이션으로 1초 대기 후 응답 추가.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _generateBotResponse(userMessage);
    
    // 타이핑 애니메이션이 완료될 때까지 펄스 애니메이션 유지 (타이핑 완료 시 중지됨)
  }

  void _generateBotResponse(String userMessage) {
    String botResponse = '';

    final lower = userMessage.toLowerCase();
    if (lower.contains('안녕') || lower.contains('hello')) {
      botResponse = '안녕하세요! 루티입니다. 무엇을 도와드릴까요?';
    } else if (lower.contains('운동') || lower.contains('루틴')) {
      botResponse =
          '오늘은 아침 운동과 저녁 스트레칭을 추천드려요. 어떤 운동을 하고 싶으신가요?';
    } else if (lower.contains('시간') || lower.contains('언제')) {
      botResponse = '지금은 ${DateTime.now().hour}시 ${DateTime.now().minute}분입니다.';
    } else if (lower.contains('날씨')) {
      botResponse = '오늘 날씨는 맑습니다. 운동하기 좋은 날이에요!';
    } else if (lower.contains('감사') || lower.contains('고마워')) {
      botResponse = '천만에요! 언제든지 도와드릴게요.';
    } else {
      botResponse =
          '죄송해요. 아직 그 질문에 대한 답변을 드릴 수 없어요. 다른 질문을 해주세요!\n죄송해요. 아직 그 질문에 대한 답변을 드릴 수 없어요. 다른 질문을 해주세요!\n죄송해요. 아직 그 질문에 대한 답변을 드릴 수 없어요. 다른 질문을 해주세요!\n죄송해요. 아직 그 질문에 대한 답변을 드릴 수 없어요. 다른 질문을 해주세요!';
    }

    _addBotMessage(botResponse);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              '음성 대화',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 20,
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
      body: Column(
        children: [
          // 캐릭터 영역
          Expanded(
            flex: 3,
            child: _buildCharacterArea(),
          ),

          // 대화 기록 영역
          Expanded(
            flex: 2,
            child: _buildConversationArea(),
          ),

          // 마이크 버튼 영역
          _buildMicButtonArea(),
        ],
      ),
    );
  }

  Widget _buildCharacterArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 캐릭터 이미지 (AI가 말할 때 펄스 효과)
          AnimatedBuilder(
            animation: Listenable.merge([_characterBounceAnimation, _talkingPulseAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _isProcessingResponse || _isWaitingForResponse || _isTyping
                    ? _talkingPulseAnimation.value 
                    : 1.0,
                child: Transform.translate(
                  offset: Offset(0, _characterBounceAnimation.value),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(97),
                      child: _selectedCharacterImage != null && _selectedCharacterImage!.startsWith('images/')
                          ? Image.asset(
                              _selectedCharacterImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    _selectedCharacterImage ?? '🌱',
                                    style: const TextStyle(fontSize: 80),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                _selectedCharacterImage ?? '🌱',
                                style: const TextStyle(fontSize: 80),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // 캐릭터 이름
          Text(
            _selectedCharacterName ?? '미정',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          // 상태 메시지
          Text(
            _isProcessingResponse
                ? '응답 생성 중...'
                : _isWaitingForResponse
                    ? 'AI가 답변하고 있어요...'
                    : _isListening
                        ? (_currentWords.isEmpty ? '연속 음성 인식 중...' : '인식 중: $_currentWords')
                        : '대화를 기다리고 있어요',
            style: TextStyle(
              fontSize: 16,
              color: _isProcessingResponse || _isWaitingForResponse
                  ? Colors.blue
                  : _isListening
                      ? Colors.green
                      : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Ionicons.chatbubble_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '대화 기록',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (_conversationHistory.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      if (!mounted) return;
                      setState(() {
                        _conversationHistory.clear();
                      });
                    },
                    child: const Text(
                      '지우기',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 대화 목록
          Expanded(
            child: _conversationHistory.isEmpty && _currentWords.isEmpty
                ? const Center(
                    child: Text(
                      '아직 대화가 없습니다.\n마이크 버튼을 눌러 대화를 시작해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversationHistory.length + (_currentWords.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _conversationHistory.length) {
                        final message = _conversationHistory[index];
                        return _buildMessageBubble(message);
                      } else {
                        // 실시간 인식 중인 텍스트 표시
                        return _buildCurrentWordsBubble();
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isBot = message['type'] == 'bot';
    final messageText = message['message'] as String;
    final timestamp = message['timestamp'] as DateTime;
    final isTyping = message['isTyping'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _selectedCharacterImage != null && _selectedCharacterImage!.startsWith('images/')
                    ? Image.asset(
                        _selectedCharacterImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _selectedCharacterImage ?? '🌱',
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          _selectedCharacterImage ?? '🌱',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? Colors.grey[100] : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        messageText,
                        style: TextStyle(
                          color: isBot ? Colors.black87 : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      // 타이핑 중일 때 커서 표시
                      if (isTyping)
                        Container(
                          width: 2,
                          height: 16,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: BoxDecoration(
                            color: isBot ? Colors.black87 : Colors.white,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isBot ? Colors.grey[600] : Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Ionicons.person, color: AppColors.primary, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentWordsBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentWords.isEmpty ? '듣고 있어요...' : _currentWords,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Ionicons.mic, color: Colors.orange, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButtonArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 마이크 버튼
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isListening ? Colors.red : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : AppColors.primary)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Ionicons.stop : Ionicons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 상태 텍스트
          Text(
            _isProcessingResponse
                ? '응답 생성 중...'
                : _isWaitingForResponse
                    ? 'AI가 답변하고 있어요...'
                    : _isListening
                        ? (_currentWords.isEmpty ? '연속 음성 인식 중...' : '인식 중: $_currentWords')
                        : '마이크를 눌러 대화를 시작하세요',
            style: TextStyle(
              fontSize: 16,
              color: _isProcessingResponse || _isWaitingForResponse
                  ? Colors.blue
                  : _isListening
                      ? Colors.green
                      : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/*
변경요약:
1. 침묵 타이머를 5초로 설정하여 사용자가 5초 이상 반응 없으면 녹음 종료 및 처리하도록 변경.
2. 녹음-처리-응답-재녹음 흐름을 명확화: _processUserSpeech()에서 stop() → 사용자 메시지 추가 → AI 응답 대기 → 응답 종료 후 자동 재녹음(_shouldAutoListen true일 때).
3. onStatus의 자동 재시작 루프 제거. fallback 재시작은 _attemptFallbackRestart()로 제한된 재시도만 수행.
4. 사용자가 버튼으로 중지하면 _shouldAutoListen=false로 자동 재녹음 차단.
5. 마이크 애니메이션 시작/중지 동기화 및 모든 비동기 콜백에서 mounted 검사 추가.
*/
