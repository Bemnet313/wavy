import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String? attachItemId;
  const ChatScreen({super.key, required this.chatId, this.attachItemId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  WavyItem? _attachedItem;
  // ignore: unused_field
  bool _isLoadingItem = false;
  bool _isLoadingMore = false;
  final List<ChatMessage> _loadedMessages = [];
  DocumentSnapshot? _lastDoc;

  // Other participant info
  String _otherName = 'CHAT';
  String? _otherPhone;
  String? _otherUserId;
  String? _otherAvatarUrl;

  // Reply state
  ChatMessage? _replyToMessage;
  bool _isSendingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.attachItemId != null) {
      _loadAttachedItem();
    }
    _scrollController.addListener(_onScroll);
    _loadParticipantInfo();
    // Mark conversation as read when entering
    final userId = ref.read(authProvider).fbUser?.uid;
    if (userId != null) {
      ref.read(apiServiceProvider).markConversationRead(widget.chatId, userId);
    }
  }

  Future<void> _loadParticipantInfo() async {
    try {
      final currentUserId = ref.read(authProvider).fbUser?.uid;
      if (currentUserId == null) return;

      final convDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.chatId)
          .get();
      if (!convDoc.exists) return;

      final participants = List<String>.from(convDoc.data()?['participants'] ?? []);
      final otherId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
      if (otherId.isEmpty) return;

      _otherUserId = otherId;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherId)
          .get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        setState(() {
          _otherName = (data['fullName'] ?? data['name'] ?? 'User').toString().toUpperCase();
          _otherPhone = data['phone'] as String?;
          _otherAvatarUrl = data['avatar_url'] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      if (!_isLoadingMore && _lastDoc != null) {
        _loadMoreMessages();
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    setState(() => _isLoadingMore = true);
    try {
      final additional = await ref.read(apiServiceProvider).loadMoreMessages(widget.chatId, _lastDoc!);
      if (additional.isNotEmpty && mounted) {
        setState(() {
          _loadedMessages.addAll(additional);
          _lastDoc = additional.last.docRef;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
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
    
    // Capture state before clearing
    final attachedItemId = _attachedItem?.id;
    final replyId = _replyToMessage?.id;
    final replyText = _replyToMessage?.text;

    // Clear UI state immediately
    _messageController.clear();
    setState(() {
      _attachedItem = null;
      _replyToMessage = null;
    });

    final message = ChatMessage(
      id: '',
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now().toIso8601String(),
      attachedItemId: attachedItemId,
      replyToId: replyId,
      replyToText: replyText,
    );

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

  Future<void> _sendImage() async {
    final currentUserId = ref.read(authProvider).fbUser?.uid;
    if (currentUserId == null) return;
    final api = ref.read(apiServiceProvider);

    // Check daily limit
    final count = await api.getChatImageCount(widget.chatId, currentUserId);
    if (count >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image limit reached (5 per day per chat)')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1200, maxHeight: 1200);
    if (picked == null || !mounted) return;

    setState(() => _isSendingImage = true);
    try {
      final imageUrl = await api.uploadChatImage(File(picked.path), widget.chatId);
      final message = ChatMessage(
        id: '',
        senderId: currentUserId,
        text: '',
        timestamp: DateTime.now().toIso8601String(),
        imageUrl: imageUrl,
      );
      await api.sendMessage(widget.chatId, message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image send failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  void _showReactionPicker(ChatMessage msg) {
    final currentUserId = ref.read(authProvider).fbUser?.uid;
    if (currentUserId == null) return;
    final api = ref.read(apiServiceProvider);
    const emojis = ['❤️', '👍', '👎', '🔥'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis.map((emoji) {
            final isSelected = msg.reactions?[currentUserId] == emoji;
            return GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
                if (isSelected) {
                  api.removeReaction(widget.chatId, msg.id, currentUserId);
                } else {
                  api.addReaction(widget.chatId, msg.id, currentUserId, emoji);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _toggleHeartReaction(ChatMessage msg) {
    final currentUserId = ref.read(authProvider).fbUser?.uid;
    if (currentUserId == null) return;
    final api = ref.read(apiServiceProvider);
    final currentReaction = msg.reactions?[currentUserId];
    if (currentReaction == '❤️') {
      api.removeReaction(widget.chatId, msg.id, currentUserId);
    } else {
      api.addReaction(widget.chatId, msg.id, currentUserId, '❤️');
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
        title: GestureDetector(
          onTap: _otherUserId != null ? () => context.push('/seller/$_otherUserId') : null,
          child: Row(
            children: [
              if (_otherAvatarUrl != null && _otherAvatarUrl!.isNotEmpty)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: _otherAvatarUrl!,
                    width: 32, height: 32,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Text(
                          _otherName.isNotEmpty ? _otherName[0] : '?',
                          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Icon(Icons.person_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _otherName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_otherPhone != null && _otherPhone!.isNotEmpty)
            IconButton(
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: _otherPhone);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.call_rounded, size: 20),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (_lastDoc == null && messages.isNotEmpty) {
                  _lastDoc = messages.last.docRef;
                }
                
                final allMessages = [...messages];
                for (var old in _loadedMessages) {
                  if (!allMessages.any((m) => m.id == old.id)) {
                    allMessages.add(old);
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  reverse: true,
                  itemCount: allMessages.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == allMessages.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: WavyTheme.neonCyan, strokeWidth: 2),
                        ),
                      );
                    }
                    final msg = allMessages[index];
                    final isMe = msg.senderId == currentUserId;

                    return _SwipeToReply(
                      onReply: () => setState(() => _replyToMessage = msg),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (msg.attachedItemId != null) 
                            _ItemContextCardLoader(itemId: msg.attachedItemId!),
                          GestureDetector(
                            onLongPress: () => _showReactionPicker(msg),
                            onDoubleTap: () => _toggleHeartReaction(msg),
                            child: _ChatBubble(
                              message: msg,
                              isMe: isMe,
                              time: msg.timestamp.split('T').last.substring(0, 5),
                              currentUserId: currentUserId ?? '',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: WavyTheme.neonCyan)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
            ),
          ),
          _buildAttachmentPreview(),
          _buildReplyPreview(),
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

  Widget _buildReplyPreview() {
    if (_replyToMessage == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: const Border(left: BorderSide(color: WavyTheme.neonCyan, width: 3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: WavyTheme.neonCyan, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'REPLYING',
                  style: GoogleFonts.spaceGrotesk(
                    color: WavyTheme.neonCyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  _replyToMessage!.text.isNotEmpty
                      ? _replyToMessage!.text
                      : (_replyToMessage!.imageUrl != null ? '📷 Photo' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _replyToMessage = null),
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
            // Image upload button
            IconButton(
              onPressed: _isSendingImage ? null : _sendImage,
              icon: _isSendingImage
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                    )
                  : Icon(Icons.image_rounded, color: Colors.white.withValues(alpha: 0.4), size: 22),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
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
  final ChatMessage message;
  final bool isMe;
  final String time;
  final String currentUserId;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.time,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = message.text.isNotEmpty;
    final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;
    final hasReactions = message.reactions != null && message.reactions!.isNotEmpty;
    final hasReply = message.replyToText != null && message.replyToText!.isNotEmpty;

    if (!hasText && !hasImage) return const SizedBox.shrink();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reply quote
                if (hasReply)
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: isMe ? Colors.black38 : WavyTheme.neonCyan,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      message.replyToText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: isMe ? Colors.black54 : Colors.white54,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                // Image
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(hasText ? 0 : 14).copyWith(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: message.imageUrl!,
                      width: 220,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 220, height: 160,
                        color: Colors.white10,
                        child: const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 220, height: 100,
                        color: Colors.white10,
                        child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24)),
                      ),
                    ),
                  ),
                // Text
                if (hasText)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      message.text,
                      style: GoogleFonts.spaceGrotesk(
                        color: isMe ? Colors.black87 : Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Reactions
          if (hasReactions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message.reactions!.values.join(' '),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ItemContextCardLoader extends ConsumerWidget {
  final String itemId;
  const _ItemContextCardLoader({required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemProvider(itemId));
    
    return itemAsync.when(
      data: (item) {
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
                  imageUrl: item.thumbnailUrl ?? (item.images.isNotEmpty ? item.images.first : ''),
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
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const _SwipeToReply({required this.child, required this.onReply});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dragOffset = 0;
  static const double _maxDrag = 60;
  static const double _triggerThreshold = 40;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset = (_dragOffset + details.delta.dx).clamp(0, _maxDrag);
        });
      },
      onHorizontalDragEnd: (_) {
        if (_dragOffset >= _triggerThreshold) {
          widget.onReply();
        }
        setState(() => _dragOffset = 0);
      },
      child: Stack(
        children: [
          // Reply icon that appears behind
          if (_dragOffset > 5)
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: (_dragOffset / _triggerThreshold).clamp(0.0, 1.0),
                  child: Icon(
                    Icons.reply_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ),
              ),
            ),
          // The actual message content
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
