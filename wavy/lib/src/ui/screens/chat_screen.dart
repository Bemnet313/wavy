import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String? attachItemId;
  const ChatScreen({super.key, required this.chatId, this.attachItemId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  WavyItem? _attachedItem;
  bool _isLoadingItem = false;

  @override
  void initState() {
    super.initState();
    if (widget.attachItemId != null) {
      _loadAttachedItem();
    }
  }

  Future<void> _loadAttachedItem() async {
    setState(() => _isLoadingItem = true);
    try {
      final item = await ref.read(apiServiceProvider).getItem(widget.attachItemId!);
      if (mounted) {
        setState(() {
          _attachedItem = item;
          _isLoadingItem = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingItem = false);
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachedItem == null) return;

    final currentUserId = ref.read(authProvider).fbUser?.uid;
    if (currentUserId == null) return;

    final api = ref.read(apiServiceProvider);
    
    // Create message object
    final message = ChatMessage(
      id: '', // Firestore generates ID
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now().toIso8601String(),
      attachedItemId: _attachedItem?.id,
    );

    _messageController.clear();
    setState(() => _attachedItem = null);

    try {
      await api.sendMessage(widget.chatId, message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final currentUserId = ref.read(authProvider).fbUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'CHAT',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                padding: const EdgeInsets.all(20),
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Column(
                    crossAxisAlignment: msg.senderId == currentUserId ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (msg.attachedItemId != null) 
                        _ItemContextCardLoader(itemId: msg.attachedItemId!),
                      _ChatBubble(
                        text: msg.text,
                        isMe: msg.senderId == currentUserId,
                        time: msg.timestamp.split('T').last.substring(0, 5),
                      ),
                    ],
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: WavyTheme.neonCyan)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
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
      color: Colors.white.withValues(alpha: 0.05),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: _attachedItem!.images.isNotEmpty ? _attachedItem!.images.first : '',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.white10),
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
    if (text.isEmpty) return const SizedBox.shrink();
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

class _ItemContextCardLoader extends ConsumerWidget {
  final String itemId;
  const _ItemContextCardLoader({required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<WavyItem>(
      future: ref.read(apiServiceProvider).getItem(itemId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final item = snapshot.data!;
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
                child: CachedNetworkImage(
                  imageUrl: item.images.isNotEmpty ? item.images.first : '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.white10),
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
            ],
          ),
        );
      },
    );
  }
}
