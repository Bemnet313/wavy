import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
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
    final seller = await api.getSeller(widget.sellerId);
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
    debugPrint('WavyLogger: $eventName $params');
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

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
          child: Text(
            locale == 'am' ? 'ሻጭ አልተገኘም' : 'SELLER NOT FOUND',
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16),
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
                                      locale == 'am' ? 'አሳይ' : 'REVEAL',
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

          // ─── Stats & Actions ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatItem(
                        label: locale == 'am' ? 'የተሸጡ' : 'SOLD',
                        value: seller.totalSales.toString(),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      _StatItem(
                        label: locale == 'am' ? 'ደረጃ' : 'RATING',
                        value: seller.rating.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        iconColor: WavyTheme.neonCyan,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      _StatItem(
                        label: locale == 'am' ? 'ገበያ' : 'MARKET',
                        value: seller.market,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: locale == 'am' ? 'መልእክት' : 'MESSAGE',
                          onTap: () {
                            _logEvent('seller_contact_message', {'seller_id': widget.sellerId});
                            context.push('/chat/${widget.sellerId}', extra: null);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.call_outlined,
                          label: locale == 'am' ? 'ይደውሉ' : 'CALL',
                          onTap: () {
                            _logEvent('seller_contact_call', {'seller_id': widget.sellerId});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${seller.phone} (Demo)')),
                            );
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
                              child: item.images.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: item.images.first,
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: iconColor),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1,
          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
        ),
      ],
    );
  }
}
