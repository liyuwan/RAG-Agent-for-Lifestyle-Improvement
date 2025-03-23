import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import 'voice_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ApiService apiService = ApiService(baseUrl: 'http://127.0.0.1:5000');
  final List<Map<String, dynamic>> _pendingMessages = [];
  final ScrollController _scrollController = ScrollController();
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
    // Schedule initial scroll to bottom after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage() async {
    final query = _controller.text;
    if (query.isEmpty) return;

    setState(() {
      _pendingMessages.add({'sender': 'user', 'text': query, 'isPending': false});
      _pendingMessages.add({'sender': 'bot', 'text': '', 'isPending': true});
    });
    _controller.clear();
    _scrollToBottom(); // Scroll after adding pending messages

    try {
      await apiService.getResponseFromApi(query);
      setState(() {
        _pendingMessages.removeWhere((msg) => msg['sender'] == 'user' && msg['text'] == query);
        _pendingMessages.removeWhere((msg) => msg['sender'] == 'bot' && msg['isPending'] == true);
      });
      _scrollToBottom(); // Scroll after API response
    } catch (e) {
      setState(() {
        _pendingMessages.removeWhere((msg) => msg['isPending'] == true);
        _pendingMessages.add({'sender': 'bot', 'text': 'Error: $e', 'isPending': false});
      });
      _scrollToBottom(); // Scroll on error
    }
  }

  // Function to scroll to the bottom with a retry mechanism
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      if (position.maxScrollExtent > 0) {
        _scrollController.jumpTo(position.maxScrollExtent);
      } else {
        // Retry if maxScrollExtent isn't ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToBottom();
        });
      }
    } else {
      // Retry if controller isn't attached
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scrollToBottom();
      });
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
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI Chat',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 15),
            Image.asset(
              'assets/aiChat.png', // Make sure this path matches your actual asset
              width: 26,
              height: 26,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatHistoryCollection
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _pendingMessages.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                final allMessages = [
                  ...messages.expand((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return [
                      {
                        'sender': 'user',
                        'text': data['user_input'] ?? '',
                        'isPending': false
                      },
                      {
                        'sender': 'bot',
                        'text': data['bot_response'] ?? '',
                        'isPending': false
                      },
                    ];
                  }),
                  ..._pendingMessages,
                ];

                // Trigger scroll after list is built
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final message = allMessages[index];
                    final isUser = message['sender'] == 'user';
                    final isPending = message['isPending'] as bool? ?? false;

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: isUser
                            ? const EdgeInsets.only(
                                left: 30, right: 8, top: 10, bottom: 10)
                            : const EdgeInsets.only(
                                left: 8, right: 30, top: 10, bottom: 10),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFF008080)
                              : Colors.teal[50]?.withOpacity(0.6),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isUser
                                ? const Radius.circular(16)
                                : const Radius.circular(0),
                            bottomRight: isUser
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          const Color(0xFF008080)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
            padding: const EdgeInsets.only(
                left: 10.0, right: 15.0, top: 10.0, bottom: 35.0),
            child: Row(
              children: [
                IconButton(
                  icon: Image.asset(
                    'assets/voice_chat.png',
                    width: 30,
                    height: 30,
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VoiceChatScreen(),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        for (var message in result) {
                          bool alreadyExistsInPending = _pendingMessages.any(
                              (msg) =>
                                  msg['text'] == message['text'] &&
                                  msg['sender'] == message['sender']);

                          bool alreadyExistsInChatHistory = false;

                          // Only add message if not already in pending or chat history
                          if (!alreadyExistsInPending) {
                            _chatHistoryCollection
                                .where('user_input', isEqualTo: message['text'])
                                .get()
                                .then((querySnapshot) {
                              if (querySnapshot.docs.isNotEmpty) {
                                alreadyExistsInChatHistory = true;
                              }

                              // Only add if it's not in Firestore
                              if (!alreadyExistsInChatHistory) {
                                _pendingMessages.add(message);
                              }

                            });
                          }
                        }
                      });
                    }
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

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
