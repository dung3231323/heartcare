import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'home_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> messages = [
    {"isUser": true, "text": "Hello DeepSeek, how are you today?"},
    {"isUser": false, "text": "Hello, I'm fine, how can I help you?"},
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isSending = false;

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() {
      messages.add({"isUser": true, "text": text});
      _controller.clear();
      isSending = true;
    });

    scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://ec2-13-211-132-6.ap-southeast-2.compute.amazonaws.com:8000/chat'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"message": text},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['response'] ?? "Không có phản hồi.";

        setState(() {
          messages.add({"isUser": false, "text": reply});
        });
        scrollToBottom();
      } else {
        setState(() {
          messages.add({
            "isUser": false,
            "text": "Lỗi ${response.statusCode} khi gọi API."
          });
        });
        scrollToBottom();
      }
    } catch (e) {
      setState(() {
        messages.add({"isUser": false, "text": "Đã xảy ra lỗi kết nối API."});
      });
      scrollToBottom();
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  void scrollToBottom() {
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

  Widget buildMessageBubble(Map<String, dynamic> message) {
    return Align(
      alignment: message['isUser']
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message['isUser']
              ? Colors.deepPurple
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message['isUser']) ...[
              const Icon(Icons.android, size: 20, color: Colors.deepPurple),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: MarkdownBody(
                data: message['text'],
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    color: message['isUser'] ? Colors.white : Colors.black87,
                  ),
                  h1: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: message['isUser'] ? Colors.white : Colors.black),
                  h2: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: message['isUser'] ? Colors.white : Colors.black),
                  h3: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: message['isUser'] ? Colors.white : Colors.black),
                  code: TextStyle(
                      fontFamily: 'monospace',
                      color: message['isUser']
                          ? Colors.amber[200]
                          : Colors.deepPurple),
                  codeblockDecoration: BoxDecoration(
                    color: message['isUser']
                        ? Colors.deepPurple[300]
                        : const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          },
        ),
        title: Row(
          children: const [
            Text(
              "Deepseek",
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.android, color: Colors.deepPurple),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_vert, color: Colors.black),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: const [
                SizedBox(width: 72),
                CircleAvatar(radius: 4, backgroundColor: Colors.green),
                SizedBox(width: 6),
                Text("Online", style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessageBubble(messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, -1),
                  blurRadius: 4,
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => sendMessage(),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      hintText: "Viết tin nhắn của bạn...",
                      hintStyle: const TextStyle(color: Colors.black45),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.mic, color: Colors.deepPurple),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.deepPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
