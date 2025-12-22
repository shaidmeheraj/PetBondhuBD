import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime time;
  const _ChatMessage({required this.text, required this.fromUser, required this.time});
}

class _ChatBotApi {
  static Uri _endpoint() {
    // Use Android emulator loopback if needed.
    final host = kIsWeb
        ? '127.0.0.1'
        : (Platform.isAndroid ? '10.0.2.2' : '127.0.0.1');
    return Uri.parse('http://$host:8000/chat');
  }

  static Future<String> send(String userMessage, {Duration timeout = const Duration(seconds: 20)}) async {
    final url = _endpoint();
    try {
      final response = await http
          .post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode({"text": userMessage}))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['reply'] ?? '').toString();
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } on Exception catch (e) {
      return 'Failed to connect: $e';
    }
  }
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  final List<String> _suggestions = const [
    'Pet nutrition tips',
    'Vaccination schedule for puppies',
    'Common diseases in cats',
    'Best food for senior dogs',
    'Find nearby vets',
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? override]) async {
    final text = (override ?? _textCtrl.text).trim();
    if (text.isEmpty || _isSending) return;
    _textCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true, time: DateTime.now()));
      _isSending = true;
    });
    _scrollToBottomSoon();

    final reply = await _ChatBotApi.send(text);
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, fromUser: false, time: DateTime.now()));
      _isSending = false;
    });
    _scrollToBottomSoon();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _clearChat() {
    setState(() => _messages.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetBondhu Chatbot'),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.delete_sweep),
            onPressed: _messages.isEmpty ? null : _clearChat,
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isSending && index == _messages.length) {
                    return const _TypingIndicator();
                  }
                  final m = _messages[index];
                  return _MessageBubble(message: m);
                },
              ),
            ),

            // Suggestions
            if (_messages.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Try asking:', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions
                      .map((s) => ActionChip(
                            label: Text(s),
                            onPressed: () => _sendMessage(s),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Input
            _InputBar(
              controller: _textCtrl,
              focusNode: _focusNode,
              enabled: !_isSending,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final align = message.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = message.fromUser ? const Color(0xFF6A00F4) : Colors.white;
    final fg = message.fromUser ? Colors.white : Colors.black87;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: message.fromUser ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: message.fromUser ? const Radius.circular(4) : const Radius.circular(18),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: message.fromUser ? null : Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(message.fromUser ? 0.1 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: message.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Bot icon & label for bot messages
              if (!message.fromUser) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A00F4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.smart_toy, size: 14, color: Color(0xFF6A00F4)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PetBondhu AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6A00F4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // Message content with markdown bold support
              message.fromUser
                  ? Text(message.text, style: TextStyle(color: fg, fontSize: 15, height: 1.4))
                  : _buildRichText(message.text, fg),
              const SizedBox(height: 6),
              // Timestamp
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 10,
                    color: message.fromUser ? Colors.white60 : Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _fmtTime(message.time),
                    style: TextStyle(
                      color: message.fromUser ? Colors.white60 : Colors.black38,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Parse markdown-style **bold** text and render as rich text
  Widget _buildRichText(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(fontSize: 15, height: 1.5, color: baseColor),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.bold, color: baseColor),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(fontSize: 15, height: 1.5, color: baseColor),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  String _fmtTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(animation: _animation, delay: 0),
            const SizedBox(width: 4),
            _Dot(animation: _animation, delay: 0.15),
            const SizedBox(width: 4),
            _Dot(animation: _animation, delay: 0.3),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Animation<double> animation;
  final double delay; // 0..1
  const _Dot({required this.animation, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final v = (animation.value + delay) % 1.0;
        final scale = 0.6 + (v < 0.5 ? v : 1 - v) * 0.8;
        return Transform.scale(
          scale: scale,
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.shade600, shape: BoxShape.circle)),
        );
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final Future<void> Function([String?]) onSend;

  const _InputBar({required this.controller, required this.focusNode, required this.enabled, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.grey.shade300));
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                enabled: enabled,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border.copyWith(borderSide: const BorderSide(color: Color(0xFF6A00F4))),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              width: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  backgroundColor: const Color(0xFF6A00F4),
                ),
                onPressed: enabled ? () => onSend() : null,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

