import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Image.asset('assets/wavy_logo_new.png', fit: BoxFit.contain),
        ),
        title: Text(
          'MESSAGES',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'NO CONVERSATIONS YET',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white30, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(
              color: WavyTheme.accentBorder,
              height: 1,
              indent: 80,
            ),
            itemBuilder: (context, index) {
              return _ConversationTile(chat: conversations[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: WavyTheme.neonCyan)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

/// Smart date formatting:
/// - <24h ago: "2:15 PM"
/// - Same year: "Mar 9"
/// - Older: "Mar 9, 2025"
String _formatSmartDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 24 && date.day == now.day) {
      // Today — show time
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];

    if (date.year == now.year) {
      return '$month ${date.day}';
    }

    return '$month ${date.day}, ${date.year}';
  } catch (_) {
    return '';
  }
}

class _ConversationTile extends ConsumerWidget {
  final ChatConversation chat;

  const _ConversationTile({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authProvider).fbUser?.uid;
    final otherId = chat.participants.firstWhere((p) => p != currentUserId, orElse: () => '');
    
    final profileAsync = otherId.isNotEmpty ? ref.watch(userProfileProvider(otherId)) : const AsyncValue.data(null);
    final otherUser = profileAsync.valueOrNull;
    final sellerName = otherUser?.name ?? 'SELLER';
    final avatarUrl = otherUser?.avatarUrl;
    
    final lastMsg = chat.lastMessage;
    final bool hasUnread = _isUnread(chat, currentUserId);

    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red.withValues(alpha: 0.2),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: WavyTheme.surfaceDark,
              title: Text('DELETE CONVERSATION?',
                  style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 18)),
              content: Text('This action cannot be undone.',
                  style: GoogleFonts.spaceGrotesk(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('CANCEL',
                      style: GoogleFonts.spaceGrotesk(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('DELETE',
                      style: GoogleFonts.spaceGrotesk(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        await ref.read(apiServiceProvider).deleteConversation(chat.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversation deleted')),
          );
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () => context.push('/chat/${chat.id}'),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: WavyTheme.surfaceDark,
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrl,
                    width: 56, height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Icon(Icons.person_rounded, color: Colors.white24, size: 24),
                    errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white24, size: 24),
                  ),
                )
              : const Icon(Icons.person_rounded, color: Colors.white24, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sellerName.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: hasUnread ? FontWeight.w900 : FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
              ),
            ),
            if (hasUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              )
            else
              Text(
                _formatSmartDate(chat.updatedAt),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  color: WavyTheme.textDarkSecondary,
                ),
              ),
          ],
        ),
        subtitle: Text(
          lastMsg?.imageUrl != null && lastMsg!.imageUrl!.isNotEmpty
              ? '📷 Photo'
              : (lastMsg?.text ?? 'No messages yet'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
            color: hasUnread ? Colors.white : WavyTheme.textDarkSecondary,
          ),
        ),
      ),
    );
  }

  bool _isUnread(ChatConversation chat, String? currentUserId) {
    if (currentUserId == null) return false;
    final lastMsg = chat.lastMessage;
    if (lastMsg == null) return false;
    if (lastMsg.senderId == currentUserId) return false;
    
    final lastReadAt = chat.metadata?['last_read_at'];
    if (lastReadAt is Map && lastReadAt[currentUserId] != null) {
      return false;
    }
    return true;
  }
}
