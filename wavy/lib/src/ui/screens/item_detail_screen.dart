import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _showSellerInfo = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  WavyItem? _item;
  Seller? _seller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final item = await api.getItem(widget.itemId);
      final sellerResponse = await api.getSeller(item.sellerId);

      if (mounted) {
        setState(() {
          _item = item;
          _seller = sellerResponse;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startChat() async {
    final currentUserId = ref.read(authProvider).fbUser?.uid;
    if (currentUserId == null || _item == null) return;

    try {
      final conversationId = await ref.read(apiServiceProvider).startOrGetConversation([
        currentUserId,
        _item!.sellerId,
      ]);

      if (mounted) {
        context.push('/chat/$conversationId?attachItemId=${_item!.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start chat: $e')),
        );
      }
    }
  }

  void _logEvent(String eventName, Map<String, dynamic> params) {
    debugPrint('WavyLogger: $eventName $params');
  }

  void _showShareModal(BuildContext context, String itemId) {
    _logEvent('share_opened', {'item_id': itemId});
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareBottomSheet(itemId: itemId, onLog: _logEvent),
    );
  }

  void _openGallery(BuildContext context, WavyItem item, int initialIndex) {
    _logEvent('item_image_viewed', {'item_id': item.id, 'image_index': initialIndex});
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => _FullScreenGallery(
          images: item.images,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: WavyTheme.neonCyan)),
      );
    }

    if (_error != null || _item == null || _seller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(_error ?? 'ITEM NOT FOUND', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _loadData, child: const Text('RETRY')),
            ],
          ),
        ),
      );
    }

    final item = _item!;
    final seller = _seller!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // ─── Image Header ────────────────────────────────
          SliverAppBar(
            expandedHeight: 450,
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
            actions: [
              GestureDetector(
                onTap: () {
                  ref.read(savedProvider.notifier).addItem(item);
                },
                child: Container(
                  margin: const EdgeInsets.all(10),
                  width: 40,
                  height: 40,
                  decoration: GlassDecoration.dark(opacity: 0.2),
                  child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20),
                ),
              ),
              GestureDetector(
                onTap: () => _showShareModal(context, item.id),
                child: Container(
                  margin: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
                  width: 40,
                  height: 40,
                  decoration: GlassDecoration.dark(opacity: 0.2),
                  child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.images.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemCount: item.images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _openGallery(context, item, index),
                          child: (item.images[index].startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: item.images[index],
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  item.images[index],
                                  fit: BoxFit.cover,
                                )),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: Icon(Icons.image_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                    ),
                  // Pure black gradient fade at bottom
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black,
                            ],
                            stops: const [0.6, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Image indicator (dots)
                  if (item.images.length > 1)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            item.images.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Item Details ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    (locale == 'am' ? (item.titleAm ?? item.title) : item.title).toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                  ),
                  const SizedBox(height: 12),
                  
                  // Price (Neon Cyan tag style)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: WavyTheme.neonCyan,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: WavyTheme.neonCyan.withValues(alpha: 0.3),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Text(
                          '${item.price} ${item.currency}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Meta badges (Clean minimalist glass)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetaBadge(icon: Icons.straighten_rounded, label: item.size),
                      _MetaBadge(icon: Icons.auto_awesome_rounded, label: item.condition),
                      _MetaBadge(icon: Icons.radar_rounded, label: item.category),
                      _MetaBadge(
                        icon: Icons.trending_up_rounded,
                        label: '${item.swipeCount} VIEWS',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Seller minimalist section
                  Text(
                    'CURATED BY',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      _logEvent('seller_profile_opened', {'seller_id': seller.id});
                      context.push('/seller/${seller.id}');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: GlassDecoration.dark(opacity: 0.05),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: ClipOval(
                              child: seller.avatarUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: seller.avatarUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Text(
                                        seller.name[0],
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      seller.name.toUpperCase(),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                                    ),
                                    if (seller.verified) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.verified_rounded,
                                              color: Colors.white, size: 16),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${seller.rating} RATING · ${seller.totalSales} DROPS',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Phone reveal (Neon success box)
                  if (_showSellerInfo) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_rounded, color: Colors.white),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  seller.phone,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filled(
                            onPressed: () {},
                            icon: const Icon(Icons.call_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  if (!_showSellerInfo)
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _showSellerInfo = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          (locale == 'am' ? 'እፈልጋለሁ!' : 'GET THE FIT'),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 64,
                            child: OutlinedButton(
                              onPressed: () {}, // dialer logic
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text(
                                (locale == 'am' ? 'ደውል' : 'CALL SELLER'),
                                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 64,
                            child: ElevatedButton(
                              onPressed: () {
                                _logEvent('seller_message_tapped', {'seller_id': seller.id, 'item_id': item.id});
                                _startChat();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                              child: Text(
                                (locale == 'am' ? 'መልዕክት' : 'MESSAGE'),
                                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: GlassDecoration.dark(opacity: 0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
          ),
        ],
      ),
    );
  }
}

class _ShareBottomSheet extends StatelessWidget {
  final String itemId;
  final Function(String, Map<String, dynamic>) onLog;

  const _ShareBottomSheet({required this.itemId, required this.onLog});

  @override
  Widget build(BuildContext context) {
    final shareUrl = 'https://wavy.app/item/$itemId';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SHARE THIS ITEM',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ShareIcon(icon: Icons.camera_alt_outlined, name: 'Instagram', onTap: () => _tapApp('Instagram', context)),
                _ShareIcon(icon: Icons.telegram_rounded, name: 'Telegram', onTap: () => _tapApp('Telegram', context)),
                _ShareIcon(icon: Icons.facebook_rounded, name: 'Facebook', onTap: () => _tapApp('Facebook', context)),
                _ShareIcon(icon: Icons.message_rounded, name: 'WhatsApp', onTap: () => _tapApp('WhatsApp', context)),
                _ShareIcon(icon: Icons.snapchat_rounded, name: 'Snapchat', onTap: () => _tapApp('Snapchat', context)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shareUrl,
                    style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    onLog('share_copy_link', {'item_id': itemId});
                    // Clipboard logic (mocked)
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('LINK COPIED TO CLIPBOARD'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.white,
                      ),
                    );
                  },
                  child: Text(
                    'COPY',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _tapApp(String name, BuildContext context) {
    onLog('share_app_tapped', {'item_id': itemId, 'app_name': name});
    Navigator.pop(context);
  }
}

class _ShareIcon extends StatefulWidget {
  final IconData icon;
  final String name;
  final VoidCallback onTap;

  const _ShareIcon({required this.icon, required this.name, required this.onTap});

  @override
  State<_ShareIcon> createState() => _ShareIconState();
}

class _ShareIconState extends State<_ShareIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPressed ? Colors.white : Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(widget.icon, color: _isPressed ? Colors.black : Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              widget.name.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final img = widget.images[index];
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: img.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        )
                      : Image.asset(
                          img,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                ),
              );
            },
          ),
          // Top Bar (Back Button)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Bottom Indicator (Counter)
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
