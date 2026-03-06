import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.attachItemId != null) {
      _loadAttachedItem();
    }
    _scrollController.addListener(_onScroll);
    _loadParticipantInfo();
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
          _otherName,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
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
          if (_otherUserId != null)
            IconButton(
              onPressed: () => context.push('/seller/$_otherUserId'),
              icon: const Icon(Icons.person_rounded, size: 20),
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
                );
              },
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
