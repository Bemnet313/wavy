import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/wavy_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late CardSwiperController _swiperController;

  @override
  void initState() {
    super.initState();
    _swiperController = CardSwiperController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedState = ref.read(feedProvider);
      if (feedState.items.isEmpty && !feedState.isLoading) {
        ref.read(feedProvider.notifier).loadFeed();
      }
    });
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final feedState = ref.watch(feedProvider);
    final hasSeenTutorial = ref.watch(preferencesProvider).hasSeenTutorial;

    final items = [...feedState.items];
    if (!hasSeenTutorial && items.isNotEmpty && !items.any((i) => i.id == 'tutorial')) {
      items.insert(0, const WavyItem(
        id: 'tutorial',
        title: 'Tutorial',
        price: 0,
        size: 'INFO',
        condition: 'TUTORIAL',
        images: [],
        sellerId: 'system',
        tagId: 'tut',
        category: 'System',
        createdAt: '',
      ));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Image.asset(
                    'assets/wavy_logo_new.png',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => const _FilterModal(),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: GlassDecoration.dark(opacity: 0.1),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: WavyTheme.neonCyan,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Swipe deck
            Expanded(
              child: feedState.isLoading 
                ? _buildShimmerFeed()
                : feedState.error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(feedState.error!, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => ref.read(feedProvider.notifier).loadFeed(), 
                            child: const Text('RETRY')
                          ),
                        ],
                      ),
                    )
                  : items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.done_all_rounded,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.instance.tr('feed_no_more'),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                              ),
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: () => ref.read(feedProvider.notifier).loadFeed(),
                                style: TextButton.styleFrom(
                                  foregroundColor: WavyTheme.neonMagenta,
                                  side: const BorderSide(color: WavyTheme.neonMagenta),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text('RELOAD FEED'),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: RefreshIndicator(
                            color: WavyTheme.neonCyan,
                            backgroundColor: Colors.black,
                            onRefresh: () async {
                              await ref.read(feedProvider.notifier).loadFeed();
                            },
                            child: CardSwiper(
                              controller: _swiperController,
                              initialIndex: feedState.currentIndex,
                              cardsCount: items.length,
                              numberOfCardsDisplayed: items.length.clamp(1, 3),
                              backCardOffset: const Offset(0, -38),
                              scale: 0.92,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 24),
                          onSwipe: (prevIndex, currentIndex, direction) async {
                            final item = items[prevIndex];
                            if (item.id == 'tutorial') {
                              ref.read(preferencesProvider.notifier).markTutorialSeen();
                            } else {
                              if (direction == CardSwiperDirection.right) {
                                try {
                                  await ref.read(savedProvider.notifier).addItem(item);
                                } catch (e) {
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: const BorderSide(color: WavyTheme.neonCyan, width: 2),
                                        ),
                                        title: Text(
                                          'LIMIT REACHED',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        content: Text(
                                          'Remove items from your list, it\'s full. Limit is 50 saved.',
                                          style: GoogleFonts.spaceGrotesk(color: Colors.white70),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text(
                                              'OK',
                                              style: GoogleFonts.spaceGrotesk(color: WavyTheme.neonCyan),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }
                              }
                              if (currentIndex != null) {
                                ref.read(feedProvider.notifier).setCurrentIndex(currentIndex);
                              }
                              ref.read(feedProvider.notifier).setCanUndo(true);
                            }
                            return true;
                          },

                          onEnd: () {
                            // This will trigger the empty state view
                            ref.read(feedProvider.notifier).loadFeed();
                          },
                          cardBuilder: (context, index, percentThresholdX,
                              percentThresholdY) {
                            final item = items[index];
                            if (item.id == 'tutorial') {
                              return _TutorialCard(locale: locale);
                            }
                            return GestureDetector(
                              onTap: () => context.push('/item/${item.id}'),
                              child: WavyCard(item: item, locale: locale),
                            );
                          },
                        ),
                          ),
                        ),
            ),

            // Action buttons
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.u_turn_left_rounded,
                      color: feedState.canUndo ? Colors.white : Colors.white24,
                      borderColor: feedState.canUndo ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      size: 64,
                      onTap: feedState.canUndo ? () async {
                        _swiperController.undo();
                        ref.read(feedProvider.notifier).setCanUndo(false);
                      } : () {},
                    ),
                    _ActionButton(
                      icon: Icons.info_outline_rounded,
                      color: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.2),
                      size: 64,
                      onTap: () {
                        if (items.isNotEmpty) {
                          context.push('/item/${items.first.id}');
                        }
                      },
                    ),
                    _ActionButton(
                      icon: Icons.favorite_rounded,
                      color: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.2),
                      size: 64,
                      onTap: () =>
                          _swiperController.swipe(CardSwiperDirection.right),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerFeed() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(WavyTheme.radiusXl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(WavyTheme.radiusXl),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title placeholder
              Container(
                height: 16,
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              // Price placeholder
              Container(
                height: 12,
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color? borderColor;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.borderColor,
    required this.size,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isLit = false;

  void _handleTap() {
    if (widget.onTap == () {}) return; // Handle disabled state silently
    
    setState(() => _isLit = true);
    widget.onTap();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isLit = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.color == Colors.white24;

    return GestureDetector(
      onTap: isDisabled ? null : _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isLit ? Colors.white : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: _isLit ? Colors.white : (widget.borderColor ?? widget.color.withValues(alpha: 0.5)),
            width: 1.5,
          ),
          boxShadow: [
            if (_isLit)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.4),
                blurRadius: 20,
              ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: _isLit ? Colors.black : widget.color,
          size: 28,
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final String locale;
  const _TutorialCard({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(WavyTheme.radiusXl),
        border: Border.all(color: WavyTheme.neonMagenta, width: 2),
        boxShadow: [
          BoxShadow(
            color: WavyTheme.neonMagenta.withValues(alpha: 0.2),
            blurRadius: 40,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swipe_rounded, color: WavyTheme.neonMagenta, size: 100),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.instance.tr('feed_swipe_right'),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.instance.tr('feed_swipe_left'),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterModal extends ConsumerStatefulWidget {
  const _FilterModal();

  @override
  ConsumerState<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends ConsumerState<_FilterModal> {
  String? _selectedGender;
  Set<String> _selectedSizes = {};
  String? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 25000);
  bool _isPriceFiltered = false;
  bool _isCleared = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from current feedState filters
    final feedState = ref.read(feedProvider);
    _selectedGender = feedState.gender;
    _selectedSizes = Set.from(feedState.sizes ?? []);
    _selectedCategory = feedState.category;
    if (feedState.minPrice != null || feedState.maxPrice != null) {
      _isPriceFiltered = true;
      _priceRange = RangeValues(
        (feedState.minPrice ?? 0).toDouble(),
        (feedState.maxPrice ?? 25000).toDouble(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FILTERS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('GENDER', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.6), fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Men', 'Women'].map((gender) => ChoiceChip(
                label: Text(gender, style: GoogleFonts.spaceGrotesk(color: _selectedGender == gender ? Colors.black : Colors.white)),
                selected: _selectedGender == gender,
                onSelected: (selected) {
                  setState(() {
                    _isCleared = false;
                    _selectedGender = selected ? gender : null;
                  });
                },
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                selectedColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Text('SIZES', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.6), fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['XS', 'S', 'M', 'L', 'XL', 'XXL'].map((size) => ChoiceChip(
                label: Text(size, style: GoogleFonts.spaceGrotesk(color: _selectedSizes.contains(size) ? Colors.black : Colors.white)),
                selected: _selectedSizes.contains(size),
                onSelected: (selected) {
                  setState(() {
                    _isCleared = false;
                    if (selected) { _selectedSizes.add(size); } else { _selectedSizes.remove(size); }
                  });
                },
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                selectedColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Text('CATEGORY', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.6), fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Clothes', 'Shoes'].map((cat) => ChoiceChip(
                label: Text(cat, style: GoogleFonts.spaceGrotesk(color: _selectedCategory == cat ? Colors.black : Colors.white)),
                selected: _selectedCategory == cat,
                onSelected: (selected) {
                  setState(() {
                    _isCleared = false;
                    _selectedCategory = selected ? cat : null;
                  });
                },
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                selectedColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PRICE RANGE', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.6), fontSize: 10, letterSpacing: 1.5)),
                if (_isPriceFiltered)
                  Text(
                    '${_priceRange.start.toInt()} – ${_priceRange.end.toInt()} ETB',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 25000,
                    divisions: 50,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withValues(alpha: 0.15),
                    onChanged: (values) {
                      setState(() {
                        _isCleared = false;
                        _isPriceFiltered = true;
                        _priceRange = values;
                      });
                    },
                  ),
                ),
                if (_isPriceFiltered)
                  GestureDetector(
                    onTap: () => setState(() {
                      _isPriceFiltered = false;
                      _priceRange = const RangeValues(0, 25000);
                    }),
                    child: const Icon(Icons.close, color: Colors.white54, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedGender = null;
                        _selectedSizes = {};
                        _selectedCategory = null;
                        _isPriceFiltered = false;
                        _priceRange = const RangeValues(0, 25000);
                        _isCleared = true;
                      });
                    },
                    child: Text('CLEAR ALL', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (_isCleared) {
                        ref.read(feedProvider.notifier).loadFeed(clearFilters: true);
                      } else {
                        ref.read(feedProvider.notifier).loadFeed(
                          gender: _selectedGender,
                          category: _selectedCategory,
                          sizes: _selectedSizes.isEmpty ? null : _selectedSizes.toList(),
                          minPrice: _isPriceFiltered ? _priceRange.start.toInt() : null,
                          maxPrice: _isPriceFiltered ? _priceRange.end.toInt() : null,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text('APPLY FILTERS', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
