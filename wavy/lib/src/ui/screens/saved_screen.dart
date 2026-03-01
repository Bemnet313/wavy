import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final savedItems = ref.watch(savedProvider);

    // If nothing has been swiped/saved yet, show seeded dummy saved items
    final items = savedItems.isEmpty ? DummyData.savedItems : savedItems;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text(
                    (locale == 'am' ? 'የተቀመጡ' : 'SAVED').toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20, // slightly smaller to match feed aesthetic
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                (locale == 'am'
                    ? '${items.length} ዕቃዎች ተቀምጠዋል'
                    : '${items.length} ITEMS ARCHIVED').toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 1,
                ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            (locale == 'am'
                                ? 'ገና ምንም አልተቀመጠም'
                                : 'ARCHIVE EMPTY').toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.4),
                              letterSpacing: 2,
                            ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _SavedItemCard(
                          item: item,
                          locale: locale,
                          onTap: () => context.push('/item/${item.id}'),
                          onRemove: () {
                            ref.read(savedProvider.notifier).removeItem(item.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedItemCard extends StatelessWidget {
  final WavyItem item;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedItemCard({
    required this.item,
    required this.locale,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final title = (locale == 'am' && item.titleAm != null) ? item.titleAm! : item.title;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                    child: item.images.isNotEmpty
                        ? (item.images.first.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: item.images.first,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: Colors.black12),
                                errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.white24),
                              )
                            : Image.asset(
                                item.images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.white24),
                              ))
                        : Container(color: Colors.black26),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.price} ETB',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'BY @${item.sellerId.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

