import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class ChatParticipant {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String timestamp;
  final String itemThumbnail;
  final String role; // 'BUYER' or 'SELLER'

  const ChatParticipant({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timestamp,
    required this.itemThumbnail,
    required this.role,
  });
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const List<ChatParticipant> dummyChats = [
    ChatParticipant(
      id: 'chat_1',
      name: 'Sara Hailu',
      avatarUrl: 'https://i.pravatar.cc/150?u=sara',
      lastMessage: 'Is the price negotiable?',
      timestamp: '12:45 PM',
      itemThumbnail: 'assets/images/dummy/item_2.jpg',
      role: 'SELLER',
    ),
    ChatParticipant(
      id: 'chat_2',
      name: 'Yonas Tadesse',
      avatarUrl: 'https://i.pravatar.cc/150?u=yonas',
      lastMessage: 'I can pick it up tomorrow.',
      timestamp: 'Yesterday',
      itemThumbnail: 'assets/images/dummy/item_7.jpg',
      role: 'SELLER',
    ),
    ChatParticipant(
      id: 'chat_3',
      name: 'Abebe Kebe',
      avatarUrl: 'https://i.pravatar.cc/150?u=abebe',
      lastMessage: 'Available in size L?',
      timestamp: '2 days ago',
      itemThumbnail: 'assets/images/dummy/item_12.jpg',
      role: 'BUYER',
    ),
    ChatParticipant(
      id: 'chat_4',
      name: 'Meron Bekele',
      avatarUrl: 'https://i.pravatar.cc/150?u=meron',
      lastMessage: 'Sent you the location.',
      timestamp: '3 days ago',
      itemThumbnail: 'assets/images/dummy/item_1.jpg',
      role: 'SELLER',
    ),
  ];

  void _logEvent(String eventName, Map<String, dynamic> params) {
    debugPrint('WavyLogger: $eventName $params');
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: dummyChats.length,
        separatorBuilder: (context, index) => const Divider(
          color: WavyTheme.accentBorder,
          height: 1,
          indent: 80,
        ),
        itemBuilder: (context, index) {
          final chat = dummyChats[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            onTap: () => context.push('/chat/${chat.id}'),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: WavyTheme.surfaceDark,
                  backgroundImage: NetworkImage(chat.avatarUrl),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      chat.role,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    chat.name.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  chat.timestamp,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: WavyTheme.textDarkSecondary,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: WavyTheme.textDarkSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: chat.itemThumbnail.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: chat.itemThumbnail,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          chat.itemThumbnail,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.white10, width: 32, height: 32),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
