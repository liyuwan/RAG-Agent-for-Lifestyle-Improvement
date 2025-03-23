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
  String _displayText = "Tap the mic to speak...";
  final List<Map<String, String>> _conversation = [];
  String _currentChunk = ""; // Tracks the currently displayed chunk of text

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _apiService = ApiService(baseUrl: 'http://127.0.0.1:5000');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _initializeSpeech();

    // Ensure the initial display text is set
    setState(() {
      _displayText = "Tap the mic to start speaking...";
    });
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
        _displayText = "Listening..."; // Show "Listening..." initially
      });
      _animationController.repeat();

      await _speechToText.listen(onResult: (result) {
        // Only update transcription if still listening
        if (_isListening) {
          setState(() {
            _transcription = result.recognizedWords;
            _displayText = _transcription; // Update display text with the user's speech
          });
        }
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
        setState(() {
          _displayText = "Processing..."; // Show "Processing..." while waiting for the response
        });
        await _getResponseFromApi(_transcription); // Wait for the response
      } else {
        setState(() {
          _displayText = "No speech detected.";
        });
      }
      _animationController.stop();
      _animationController.reset();
    }
  }

  Future<void> _getResponseFromApi(String query) async {
    // Step 1: Show "Processing..." immediately
    setState(() {
      _displayText = "Processing..."; // Show "Processing..." while waiting for the response
    });

    // Step 2: Allow the UI to update before making the API call
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Step 3: Fetch the response from the API
      String apiResponse = await _apiService.getResponseFromApi(query);

      // Step 4: Update the response and display text
      setState(() {
        _response = apiResponse;
        _displayText = _response; // Update display text with the response
      });

      // Add the response to the conversation and speak it
      _addToConversation("bot", apiResponse);
      await _speak(apiResponse);
    } catch (e) {
      // Step 5: Handle errors and update the display text
      setState(() {
        _displayText = "Error: $e";
      });
    }
  }

  Future<void> _speak(String text) async {
    String sanitizedText = _removeEmojis(text); // Remove emojis from the text
    List<String> chunks = _splitTextIntoChunks(sanitizedText, 200); // Split text into chunks of 200 characters
    for (String chunk in chunks) {
      setState(() {
        _currentChunk = chunk; // Update the displayed chunk dynamically
      });
      await _flutterTts.speak(chunk);
      await _flutterTts.awaitSpeakCompletion(true); // Wait for the current chunk to finish
    }
    setState(() {
      _currentChunk = ""; // Clear the current chunk after speaking
      _displayText = "Tap the mic to speak"; // Reset the display text
    });
  }

  void _addToConversation(String sender, String text) {
    final message = {"sender": sender, "text": text};
    setState(() {
      _conversation.add(message);
    });
    widget.onNewMessage?.call(message);
  }

  List<String> _splitTextIntoChunks(String text, int chunkSize) {
    List<String> chunks = [];
    int index = 0;

    while (index < text.length) {
      // Find the nearest space before the chunk limit
      int end = (index + chunkSize).clamp(0, text.length);
      int spaceIndex = text.lastIndexOf(' ', end);

      // Split at the space if found within the chunk window
      if (spaceIndex != -1 && spaceIndex > index) {
        chunks.add(text.substring(index, spaceIndex));
        index = spaceIndex + 1; // Skip the space
      } 
      // Fallback: Split at chunk size (avoids infinite loops)
      else {
        chunks.add(text.substring(index, end));
        index = end;
      }
    }

    return chunks;
  }

  String _removeEmojis(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|' // Emoticons
      r'[\u{1F300}-\u{1F5FF}]|' // Miscellaneous Symbols and Pictographs
      r'[\u{1F680}-\u{1F6FF}]|' // Transport and Map Symbols
      r'[\u{1F700}-\u{1F77F}]|' // Alchemical Symbols
      r'[\u{1F780}-\u{1F7FF}]|' // Geometric Shapes Extended
      r'[\u{1F800}-\u{1F8FF}]|' // Supplemental Arrows-C
      r'[\u{1F900}-\u{1F9FF}]|' // Supplemental Symbols and Pictographs
      r'[\u{1FA00}-\u{1FA6F}]|' // Chess Symbols
      r'[\u{1FA70}-\u{1FAFF}]|' // Symbols and Pictographs Extended-A
      r'[\u{2600}-\u{26FF}]|'   // Miscellaneous Symbols
      r'[\u{2700}-\u{27BF}]',   // Dingbats
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Voice Chat"),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Robot Image
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _isListening ? Colors.redAccent.withOpacity(0.5)
                        : const Color(0xFF66B2B2).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                    offset: const Offset(0, 10),
                  ),
                ],
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

            // Display Text (App State or Current Chunk)
            Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 200, // Fixed height for the text container
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Text(
                  _currentChunk.isNotEmpty
                      ? _currentChunk // Show the current chunk being read
                      : _displayText, // Fallback to _displayText if no chunk is being read
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Mic Button
            GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening)
                    ...List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final progress = (_animationController.value + index * 0.33) % 1.0;
                          final scale = 1.0 + progress;
                          final opacity = 1.0 - progress;
                          
                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withOpacity(0.2),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _isListening ? Colors.red : const Color(0xFF66B2B2),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
