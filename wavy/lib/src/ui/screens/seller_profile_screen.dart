import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class SellerProfileScreen extends ConsumerWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  void _logEvent(String eventName, Map<String, dynamic> params) {
    debugPrint('WavyLogger: $eventName $params');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final seller = DummyData.getSellerById(sellerId);
    final listings = DummyData.feedItems
        .where((item) => item.sellerId == sellerId)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // ─── Header Section ────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.black,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: GlassDecoration.dark(opacity: 0.2),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: seller.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: seller.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Center(
                                child: Text(
                                  seller.name[0],
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name & Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          seller.name.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                        ),
                        if (seller.verified) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Phone (Masked)
                    Text(
                      seller.phone.substring(0, 7) + 'XXXX',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Address
                    Text(
                      seller.address.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.4),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Actions ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: locale == 'am' ? 'መልዕክት' : 'MESSAGE',
                      onTap: () {
                        _logEvent('seller_message_tapped', {'seller_id': sellerId, 'item_id': null});
                        context.push('/chat/$sellerId');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.phone_outlined,
                      label: locale == 'am' ? 'ደውል' : 'CALL',
                      onTap: () {
                        _logEvent('seller_call_tapped', {'seller_id': sellerId});
                        // logic for dialer
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Listings Section Header ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text(
                (locale == 'am' ? 'ዝርዝሮች' : 'LISTINGS').toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
              ),
            ),
          ),

          // ─── Listings Grid ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = listings.isNotEmpty ? listings[index] : DummyData.feedItems[index % 5];
                  return GestureDetector(
                    onTap: () {
                      _logEvent('seller_listing_opened', {'seller_id': sellerId, 'item_id': item.id});
                      context.push('/item/${item.id}');
                    },
                    child: Container(
                      decoration: GlassDecoration.dark(opacity: 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              child: item.images.isNotEmpty
                                  ? (item.images.first.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: item.images.first,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        )
                                      : Image.asset(
                                          item.images.first,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ))
                                  : Container(color: Colors.white10),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.price} ETB',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: WavyTheme.neonCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: listings.isNotEmpty ? listings.length : 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
            ),
          ],
        ),
      ),
    );
  }
}
