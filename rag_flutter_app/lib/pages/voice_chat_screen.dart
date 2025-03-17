import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:rag_flutter_app/services/api_service.dart';

class VoiceChatScreen extends StatefulWidget {
  final Function(Map<String, String>)? onNewMessage; // Callback for new messages

  const VoiceChatScreen({super.key, this.onNewMessage});

  @override
  _VoiceChatScreenState createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  late ApiService _apiService;

  bool _isListening = false;
  String _transcription = "";
  String _response = "";
  String _displayText = "Tap the mic to start speaking...";
  final List<Map<String, String>> _conversation = []; // Store the conversation

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _apiService = ApiService(baseUrl: 'http://127.0.0.1:5000'); // Android : 10.0.2.2 <-> IOS : 127.0.0.1
    _initializeSpeech();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
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
          _displayText = _transcription; // Show live transcription
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
        _addToConversation("user", _transcription); // Add user message
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
        _displayText = _response; // Display API response
      });

      _addToConversation("bot", apiResponse); // Add bot response
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
    _conversation.add(message);
    widget.onNewMessage?.call(message); // Notify ChatPage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40.0), // Adjust the height as needed
        child: AppBar(
          title: const Text("Voice Chat"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _conversation); // Return conversation
            },
          ),
          elevation: 0, // Optional: Remove shadow to make it sleeker
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 0), // Minimize the space by reducing top padding
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image in the middle
                Image.asset(
                  'assets/robot.jpg', // Change this to your image path
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 10), // Space between image and text box

                // Text box below the image
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 150, // Reduced height
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Text(
                      _displayText,
                      style: const TextStyle(fontSize: 17),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 20), // Space between text and mic icon

                // Mic icon at the bottom
                GestureDetector(
                  onTap: () {
                    if (_isListening) {
                      _stopListening();
                    }
                    _startListening();
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: _isListening ? Colors.red : const Color(0xFF66B2B2),
                    child: Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 40,
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
}