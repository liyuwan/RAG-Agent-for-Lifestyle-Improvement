import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:rag_flutter_app/services/api_service.dart';

class VoiceChatScreen extends StatefulWidget {
  final Function(Map<String, String>)? onNewMessage;

  const VoiceChatScreen({super.key, this.onNewMessage});

  @override
  _VoiceChatScreenState createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  late ApiService _apiService;
  late AnimationController _animationController;

  bool _isListening = false;
  String _transcription = "";
  String _response = "";
  String _displayText = "Tap the mic to start speaking...";
  final List<Map<String, String>> _conversation = [];

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _apiService = ApiService(baseUrl: 'http://127.0.0.1:5000');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 1.0,
      upperBound: 1.2,
    )..repeat(reverse: true);

    _initializeSpeech();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speechToText.initialize();
    if (!available) {
      setState(() {
        _displayText = "Speech recognition is not available.";
      });
    }
  }

  void _startListening() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _displayText = "Listening...";
      });

      await _speechToText.listen(onResult: (result) {
        setState(() {
          _transcription = result.recognizedWords;
          _displayText = _transcription;
        });
      });
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });

      if (_transcription.isNotEmpty) {
        _addToConversation("user", _transcription);
        _getResponseFromApi(_transcription);
      } else {
        setState(() {
          _displayText = "No speech detected.";
        });
      }
    }
  }

  Future<void> _getResponseFromApi(String query) async {
    setState(() {
      _displayText = "Processing...";
    });

    try {
      String apiResponse = await _apiService.getResponseFromApi(query);
      setState(() {
        _response = apiResponse;
        _displayText = _response;
      });

      _addToConversation("bot", apiResponse);
      await _speak(apiResponse);
    } catch (e) {
      setState(() {
        _displayText = "Error: $e";
      });
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _addToConversation(String sender, String text) {
    final message = {"sender": sender, "text": text};
    setState(() {
      _conversation.add(message);
    });
    widget.onNewMessage?.call(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Voice Chat"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _conversation),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [],
              ),
              child: ClipOval(
              child: Image.asset(
                'assets/robot.jpg',
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _displayText,
                style: const TextStyle(fontSize: 17),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _animationController.value : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.8),
                                  spreadRadius: 15,
                                  blurRadius: 30,
                                ),
                              ]
                            : [],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: _isListening ? Colors.red : const Color(0xFF66B2B2),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
