import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/wavy_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  List<WavyItem> _items = [];
  bool _isLoading = true;
  String? _error;
  bool _canUndo = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed({String? gender, String? category, List<String>? sizes}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await ref.read(apiServiceProvider).getFeed(
        gender: gender,
        category: category,
        sizes: sizes,
      );
      
      final hasSeenTutorial = ref.read(preferencesProvider).hasSeenTutorial;
      if (!hasSeenTutorial) {
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

      if (mounted) {
        setState(() {
          _items = items;
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

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

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
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: WavyTheme.neonCyan))
                : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(_error!, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 24),
                          ElevatedButton(onPressed: _loadFeed, child: const Text('RETRY')),
                        ],
                      ),
                    )
                  : _items.isEmpty
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
                                locale == 'am'
                                    ? 'ሁሉንም አይተዋል!'
                                    : "ALL CAUGHT UP",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                              ),
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: _loadFeed,
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
                          child: CardSwiper(
                            controller: _swiperController,
                            cardsCount: _items.length,
                            numberOfCardsDisplayed: _items.length.clamp(1, 3),
                            backCardOffset: const Offset(0, -38),
                            scale: 0.92,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 24),
                        onSwipe: (prevIndex, currentIndex, direction) {
                          final item = _items[prevIndex];
                          if (item.id == 'tutorial') {
                            ref.read(preferencesProvider.notifier).markTutorialSeen();
                          } else {
                            if (direction == CardSwiperDirection.right) {
                              ref.read(savedProvider.notifier).addItem(item);
                            }
                            setState(() => _canUndo = true);
                          }
                          return true;
                        },

                        onEnd: () {
                          setState(() {
                            _items = [];
                          });
                        },
                        cardBuilder: (context, index, percentThresholdX,
                            percentThresholdY) {
                          final item = _items[index];
                          if (item.id == 'tutorial') {
                            return const _TutorialCard();
                          }
                          return GestureDetector(
                            onTap: () => context.push('/item/${item.id}'),
                            child: WavyCard(item: item, locale: locale),
                          );
                        },
                      ),
                    ),
            ),

            // Action buttons
            if (_items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.u_turn_left_rounded,
                      color: _canUndo ? Colors.white : Colors.white24,
                      borderColor: _canUndo ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      size: 64,
                      onTap: _canUndo ? () async {
                        _swiperController.undo();
                        setState(() => _canUndo = false);
                      } : () {},
                    ),
                    _ActionButton(
                      icon: Icons.info_outline_rounded,
                      color: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.2),
                      size: 64,
                      onTap: () {
                        if (_items.isNotEmpty) {
                          context.push('/item/${_items.first.id}');
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
  const _TutorialCard();

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
              'SWIPE RIGHT TO SAVE',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SWIPE LEFT TO PASS',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
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
  String _selectedGender = 'Women';
  final Set<String> _selectedSizes = {'M'};
  String _selectedCategory = 'Clothes';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Gender',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Men', 'Women'].map((gender) => ChoiceChip(
              label: Text(
                gender,
                style: GoogleFonts.spaceGrotesk(color: _selectedGender == gender ? Colors.black : Colors.white),
              ),
              selected: _selectedGender == gender,
              onSelected: (selected) {
                if (selected) setState(() => _selectedGender = gender);
              },
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Sizes',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['S', 'M', 'L', 'XL', 'XXL'].map((size) => ChoiceChip(
              label: Text(
                size,
                style: GoogleFonts.spaceGrotesk(color: _selectedSizes.contains(size) ? Colors.black : Colors.white),
              ),
              selected: _selectedSizes.contains(size),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSizes.add(size);
                  } else {
                    _selectedSizes.remove(size);
                  }
                });
              },
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Category',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Clothes', 'Shoes'].map((cat) => ChoiceChip(
              label: Text(
                cat,
                style: GoogleFonts.spaceGrotesk(color: _selectedCategory == cat ? Colors.black : Colors.white),
              ),
              selected: _selectedCategory == cat,
              onSelected: (selected) {
                if (selected) setState(() => _selectedCategory = cat);
              },
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedGender = 'Men';
                      _selectedSizes.clear();
                      _selectedCategory = 'Clothes';
                    });
                  },
                  child: Text(
                    'CLEAR',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    // Log event
                    debugPrint('apply_filters: payload={gender: $_selectedGender, sizes: ${_selectedSizes.toList()}, category: $_selectedCategory}');
                    
                    // Close modal
                    Navigator.pop(context);
                    
                    // Trigger refresh in feed
                    (context as Element).findAncestorStateOfType<_FeedScreenState>()?._loadFeed(
                      gender: _selectedGender,
                      category: _selectedCategory,
                      sizes: _selectedSizes.toList(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'APPLY FILTERS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
