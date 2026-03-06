import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class SellerProfileScreen extends ConsumerStatefulWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  ConsumerState<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  Seller? _seller;
  List<WavyItem> _listings = [];
  bool _isLoading = true;

  String? _revealedPhone;
  bool _isRevealingPhone = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _revealPhone() async {
    setState(() {
      _isRevealingPhone = true;
    });
    final api = ref.read(apiServiceProvider);
    final phone = await api.getSellerPhone(widget.sellerId);
    if (mounted) {
      setState(() {
        _revealedPhone = phone;
        _isRevealingPhone = false;
      });
    }
  }

  Future<void> _loadData() async {
    final api = ref.read(apiServiceProvider);
    var seller = await api.getSeller(widget.sellerId);

    // Fallback: create a minimal Seller so the profile page doesn't crash
    seller ??= Seller(
      id: widget.sellerId,
      name: 'Wavy User',
      phone: null,
      market: 'Individual Seller',
      address: 'Addis Ababa',
    );

    final listings = await api.getSellerListings(widget.sellerId);
    if (mounted) {
      setState(() {
        _seller = seller;
        _listings = listings;
        _isLoading = false;
      });
    }
  }

  void _logEvent(String eventName, Map<String, dynamic> params) {
    final userId = ref.read(authProvider).fbUser?.uid;
    if (userId != null) {
      ref.read(apiServiceProvider).logEvent(WavyEvent(
        userId: userId,
        itemId: params['item_id'] as String?,
        type: eventName,
        action: eventName,
        timestamp: DateTime.now().toUtc().toIso8601String(),
        metadata: params,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.instance.tr;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_seller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_rounded, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                'SELLER NOT FOUND',
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadData();
                },
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    final seller = _seller!;

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
                        child: seller.avatarUrl != null && (seller.avatarUrl?.isNotEmpty ?? false)
                            ? CachedNetworkImage(
                                imageUrl: seller.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Center(
                                child: Text(
                                  seller.name.isNotEmpty ? seller.name[0] : '?',
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
                    if (_revealedPhone != null)
                      Text(
                        _revealedPhone!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: WavyTheme.neonCyan,
                          letterSpacing: 2,
                        ),
                      )
                    else if (_seller?.phone != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _seller!.phone!.length > 7 ? '${_seller!.phone!.substring(0, 7)}XXXX' : _seller!.phone!,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _isRevealingPhone ? null : _revealPhone,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: _isRevealingPhone
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      tr('cta_reveal'),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Stats Tiles ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _listings.length.toString(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: WavyTheme.neonCyan,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'LISTINGS',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                              const SizedBox(height: 4),
                              Text(
                                seller.market.toUpperCase(),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: tr('cta_message'),
                          onTap: () async {
                            _logEvent('seller_contact_message', {'seller_id': widget.sellerId});
                            final currentUserId = ref.read(authProvider).fbUser?.uid;
                            if (currentUserId == null) return;
                            String? chatError;
                            String? conversationId;
                            try {
                              conversationId = await ref.read(apiServiceProvider)
                                  .startOrGetConversation([currentUserId, widget.sellerId]);
                            } catch (e) {
                              chatError = e.toString();
                            }
                            if (!mounted) return;
                            if (chatError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not start chat: $chatError')),
                              );
                            } else if (conversationId != null) {
                              context.push('/chat/$conversationId');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.call_outlined,
                          label: tr('cta_call_seller'),
                          onTap: () async {
                            _logEvent('seller_contact_call', {'seller_id': widget.sellerId});
                            final phone = seller.phone;
                            if (phone == null || phone.isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Phone number not available')),
                                );
                              }
                              return;
                            }
                            final uri = Uri(scheme: 'tel', path: phone);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      ),
                    ],
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
                tr('seller_listings').toUpperCase(),
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
            sliver: _listings.isEmpty 
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'No listings available yet.',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                )
              : SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _listings[index];
                  return GestureDetector(
                    onTap: () {
                      _logEvent('seller_listing_opened', {'seller_id': widget.sellerId, 'item_id': item.id});
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
                              child: (item.images.isNotEmpty || item.thumbnailUrl != null)
                                  ? CachedNetworkImage(
                                      imageUrl: item.thumbnailUrl ?? item.images.first,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
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
                childCount: _listings.length,
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
              color: Colors.white.withValues(alpha: 0.05),
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
