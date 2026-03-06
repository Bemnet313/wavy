import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _ConversationTile extends ConsumerWidget {
  final ChatConversation chat;

  const _ConversationTile({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authProvider).fbUser?.uid;
    final otherId = chat.participants.firstWhere((p) => p != currentUserId, orElse: () => '');
    
    // Fetch profile if we have an ID
    final profileAsync = otherId.isNotEmpty ? ref.watch(userProfileProvider(otherId)) : const AsyncValue.data(null);
    final sellerName = profileAsync.valueOrNull?.name ?? 'SELLER';
    
    final lastMsg = chat.lastMessage;

    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red.withValues(alpha: 0.2),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (direction) async {
        // Actually delete the conversation
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
          child: const Icon(Icons.person_outline_rounded, color: Colors.white24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sellerName.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
              ),
            ),
            Text(
              chat.updatedAt.split('T').first, // Simple date
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                color: WavyTheme.textDarkSecondary,
              ),
            ),
          ],
        ),
        subtitle: Text(
          lastMsg?.text ?? 'No messages yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            color: WavyTheme.textDarkSecondary,
          ),
        ),
      ),
    );
  }
}

