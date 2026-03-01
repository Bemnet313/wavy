import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../data/dummy_data.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? attachItemId;
  const ChatScreen({super.key, required this.chatId, this.attachItemId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isFirstMessage = true;
  WavyItem? _attachedItem;

  @override
  void initState() {
    super.initState();
    if (widget.attachItemId != null) {
      _attachedItem = DummyData.feedItems.firstWhere(
        (i) => i.id == widget.attachItemId,
        orElse: () => DummyData.feedItems.first,
      );
    }
    // Simulate some history
    _messages.add({
      'text': 'Hey! Is this still available?',
      'isMe': true,
      'time': '12:00 PM',
    });
    _messages.add({
      'text': 'Yes, it is!',
      'isMe': false,
      'time': '12:05 PM',
    });
  }

  void _logEvent(String eventName, Map<String, dynamic> params) {
    debugPrint('WavyLogger: $eventName $params');
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    setState(() {
      if (_attachedItem != null) {
        _messages.add({
          'isItem': true,
          'item': _attachedItem,
          'isMe': true,
          'time': 'NOW',
        });
        _logEvent('chat_message_sent', {'conv_id': widget.chatId, 'item_id': _attachedItem!.id});
        _attachedItem = null;
        _isFirstMessage = false;
      }
      _messages.add({
        'text': _messageController.text,
        'isMe': true,
        'time': 'NOW',
      });
      if (_isFirstMessage) {
        _logEvent('chat_message_sent', {'conv_id': widget.chatId, 'item_id': null});
        _isFirstMessage = false;
      }
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=sara'),
            ),
            const SizedBox(width: 12),
            Text(
              'SARA HAILU',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                
                if (msg['isItem'] == true) {
                  return _ItemContextCard(item: msg['item']);
                }

                return _ChatBubble(
                  text: msg['text'],
                  isMe: msg['isMe'],
                  time: msg['time'],
                );
              },
            ),
          ),
          _buildAttachmentPreview(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    if (_attachedItem == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.05),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              _attachedItem!.images.first,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATTACHING: ${_attachedItem!.title.toUpperCase()}',
                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${_attachedItem!.price} ETB',
                  style: GoogleFonts.spaceGrotesk(color: WavyTheme.neonCyan, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _attachedItem = null),
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: WavyTheme.accentBorder, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'TYPE A MESSAGE...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: WavyTheme.textDarkSecondary,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                  fillColor: WavyTheme.surfaceDark,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              icon: const Icon(Icons.arrow_upward_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  const _ChatBubble({required this.text, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe 
              ? Colors.white.withValues(alpha: 0.85) 
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
          ),
          border: Border.all(
            color: isMe 
                ? Colors.white.withValues(alpha: 0.5) 
                : Colors.white.withValues(alpha: 0.1),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (!isMe)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.02),
                blurRadius: 15,
                spreadRadius: -2,
              )
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.spaceGrotesk(
            color: isMe ? Colors.black87 : Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ItemContextCard extends StatelessWidget {
  final WavyItem item;
  const _ItemContextCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: WavyTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WavyTheme.accentBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/dummy/item_2.jpg', // Placeholder logic for now
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${item.price} ETB',
                  style: GoogleFonts.spaceGrotesk(
                    color: WavyTheme.textDarkSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ID: ${item.id}',
              style: const TextStyle(color: Colors.white38, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }
}
