import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import 'voice_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'profile_page.dart';

// Dummy pages
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Page (Dummy)')),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ApiService apiService = ApiService(baseUrl: 'http://127.0.0.1:5000');
  final List<Map<String, dynamic>> _pendingMessages = []; // Local state for pending messages

  // User data variables
  String _heartRate = '';
  String _steps = '';
  String _weight = '';

  // Firestore reference to chat_history
  late CollectionReference _chatHistoryCollection;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _chatHistoryCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('chat_history');
    }
    _getBiometricData();
  }

  // Fetch biometric data from Firestore
  Future<void> _getBiometricData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'No user is logged in';
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _heartRate = userDoc.data()?['heart_rate']?.toString() ?? 'N/A';
          _steps = userDoc.data()?['steps']?.toString() ?? 'N/A';
          _weight = userDoc.data()?['weight']?.toString() ?? 'N/A';
        });
      } else {
        setState(() {
          _heartRate = 'N/A';
          _steps = 'N/A';
          _weight = 'N/A';
        });
      }
    } catch (e) {
      setState(() {
        _heartRate = 'Error';
        _steps = 'Error';
        _weight = 'Error';
      });
      debugPrint('Error fetching biometric data: $e');
    }
  }

  Future<void> _sendMessage() async {
    final query = _controller.text;
    if (query.isEmpty) return;

    // 1) Immediately add the user message + a pending bot message to local state
    setState(() {
      _pendingMessages.add({
        'sender': 'user',
        'text': query,
        'isPending': false,
      });
      _pendingMessages.add({
        'sender': 'bot',
        'text': '',
        'isPending': true, // loading spinner
      });
    });

    _controller.clear();

    try {
      // 2) Call the Flask API
      await apiService.getResponseFromApi(query);

      // 3) If the server call was successful, remove both the user and the bot
      //    pending messages from local state so we don't show them twice
      setState(() {
        // Remove the user message that matches this query
        _pendingMessages.removeWhere((msg) =>
            msg['sender'] == 'user' && msg['text'] == query);

        // Remove the pending bot message (the spinner)
        _pendingMessages.removeWhere((msg) =>
            msg['sender'] == 'bot' && (msg['isPending'] == true));
      });

      // Firestore will have the final user_input/bot_response,
      // so the StreamBuilder will now display them from Firestore only.

    } catch (e) {
      // 4) On error, remove the pending bot spinner and add an error message
      setState(() {
        _pendingMessages.removeWhere((msg) => msg['isPending'] == true);
        _pendingMessages.add({
          'sender': 'bot',
          'text': 'Error: $e',
          'isPending': false,
        });
      });
      debugPrint('Error sending message: $e');
    }
  }
    
  
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text('Please log in to use the chat')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 20),
            const SizedBox(width: 4),
            Text(_heartRate, style: const TextStyle(fontSize: 12, color: Colors.black)),
            const SizedBox(width: 50),
            Icon(Icons.directions_walk, color: Colors.blue, size: 20),
            const SizedBox(width: 4),
            Text(_steps, style: const TextStyle(fontSize: 12, color: Colors.black)),
            const SizedBox(width: 50),
            Icon(Icons.scale, color: Colors.green, size: 20),
            const SizedBox(width: 4),
            Text('$_weight kg', style: const TextStyle(fontSize: 12, color: Colors.black)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'Profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                  break;
                case 'Settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                  break;
                case 'Logout':
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Profile', 'Settings', 'Logout'}.map((String choice) {
                IconData icon;
                Color iconColor = const Color(0xFF008080);
                switch (choice) {
                  case 'Profile':
                    icon = Icons.account_circle;
                    break;
                  case 'Settings':
                    icon = Icons.settings;
                    break;
                  case 'Logout':
                    icon = Icons.exit_to_app;
                    iconColor = Colors.red;
                    break;
                  default:
                    icon = Icons.help;
                }

                return PopupMenuItem<String>(
                  value: choice,
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10.0,
                              spreadRadius: 1.0,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          radius: 20,
                          child: Icon(icon, color: iconColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            color: Colors.transparent,
            elevation: 0,
            offset: const Offset(30, 30),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatHistoryCollection.orderBy('timestamp', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting && _pendingMessages.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                // Combine Firestore messages with pending messages
                final allMessages = [
                  // Convert Firestore messages to the same format
                  ...messages.expand((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return [
                      {'sender': 'user', 'text': data['user_input'] ?? '', 'isPending': false},
                      {'sender': 'bot', 'text': data['bot_response'] ?? '', 'isPending': false},
                    ];
                  }),
                  // Add pending messages
                  ..._pendingMessages,
                ];

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final message = allMessages[index];
                    final isUser = message['sender'] == 'user';
                    final isPending = message['isPending'] as bool? ?? false;

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: isUser
                            ? const EdgeInsets.only(left: 30, right: 8, top: 10, bottom: 10)
                            : const EdgeInsets.only(left: 8, right: 30, top: 10, bottom: 10),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFF008080)
                              : const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft:
                                isUser ? const Radius.circular(16) : const Radius.circular(0),
                            bottomRight:
                                isUser ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                        ),
                        child: isPending
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF008080)),
                                    ),
                                  ),
                                  const SizedBox(width: 8), // Spacing between animation and text
                                  Text(
                                    'Generating...',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                message['text'] ?? '',
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black,
                                  fontSize: 16,
                                ),
                                softWrap: true,
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 15.0, top: 10.0, bottom: 35.0),
            child: Row(
              children: [
                IconButton(
                  icon: Image.asset(
                    'assets/voice_chat.png',
                    width: 30,
                    height: 30,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VoiceChatScreen(
                          onNewMessage: (message) async {
                            setState(() {
                              _pendingMessages.add({
                                'sender': 'user',
                                'text': message['text']!,
                                'isPending': false,
                              });
                              _pendingMessages.add({
                                'sender': 'bot',
                                'text': '',
                                'isPending': true,
                              });
                            });
                            try {
                              await apiService.getResponseFromApi(message['text']!);
                              setState(() {
                                _pendingMessages.removeWhere((msg) => msg['isPending'] == true);
                              });
                            } catch (e) {
                              setState(() {
                                _pendingMessages.removeWhere((msg) => msg['isPending'] == true);
                                _pendingMessages.add({
                                  'sender': 'bot',
                                  'text': 'Error: $e',
                                  'isPending': false,
                                });
                              });
                              debugPrint('Error sending voice message: $e');
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask something.....',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                CircleAvatar(
                  backgroundColor: const Color(0xFF008080),
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}