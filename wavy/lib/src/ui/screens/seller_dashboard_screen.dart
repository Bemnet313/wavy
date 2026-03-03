import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SellerDashboardScreen extends ConsumerStatefulWidget {
  final String sellerId;
  const SellerDashboardScreen({super.key, required this.sellerId});

  @override
  ConsumerState<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-seed seller info if needed, but sellerProvider handle it
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final listingsAsync = ref.watch(sellerListingsProvider(widget.sellerId));
    
    // We can fetch seller info using a future or just keep it as is if it's static
    // Let's use a FutureBuilder for the seller info for now, or add a sellerInfoProvider
    
    return listingsAsync.when(
      data: (listings) => _buildDashboard(context, listings, locale),
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: WavyTheme.neonCyan)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text('ERROR: $err', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(sellerListingsProvider(widget.sellerId)), 
                child: const Text('RETRY')
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<WavyItem> listings, String locale) {
    return FutureBuilder<Seller?>(
      future: ref.read(apiServiceProvider).getSeller(widget.sellerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: WavyTheme.neonCyan)),
          );
        }
        final seller = snapshot.data;
        if (seller == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: Text('SELLER NOT FOUND', style: TextStyle(color: Colors.white))),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(
              (locale == 'am' ? 'የሻጭ ዳሽቦርድ' : 'SELLER DASHBOARD').toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 16,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.black,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Seller profile card (Dark Theme)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.02),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        seller.name[0],
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              seller.name.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                            ),
                            if (seller.verified) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CURATING FROM ${seller.market.toUpperCase()}',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                        ),
                        Text(
                          '${seller.rating} RATING',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats row (Minimalist)
            Row(
              children: [
                _StatCard(
                  icon: Icons.grid_view_rounded,
                  value: '${listings.length}',
                  label: locale == 'am' ? 'ንቁ' : 'ACTIVE',
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.check_circle_rounded,
                  value: '${seller.totalSales}',
                  label: locale == 'am' ? 'ተሽጧል' : 'SOLD',
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.bolt_rounded,
                  value: '12',
                  label: locale == 'am' ? 'ፍላጎቶች' : 'DROPS',
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Listings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (locale == 'am' ? 'ዝርዝሮች' : 'COLLECTIONS').toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                ),
                Icon(Icons.tune_rounded, color: Colors.white.withValues(alpha: 0.4), size: 18),
              ],
            ),
            const SizedBox(height: 20),
            ...listings.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: GlassDecoration.dark(opacity: 0.05),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: item.images.isNotEmpty
                              ? item.images.first
                              : 'https://picsum.photos/100/100',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.white.withValues(alpha: 0.05),
                            child: Icon(Icons.image_outlined,
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (locale == 'am'
                                  ? (item.titleAm ?? item.title)
                                  : item.title).toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    '${item.price} ETB',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  item.status == 'sold'
                                      ? (locale == 'am' ? 'ተሽጧል' : 'SOLD')
                                      : (locale == 'am' ? 'ንቁ' : 'ACTIVE'),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: item.status == 'sold'
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.4),
                                    letterSpacing: 1,
                                  ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.interestCount}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            (locale == 'am' ? 'ፍላጎት' : 'HITS').toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.3),
                              letterSpacing: 1,
                            ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: GlassDecoration.dark(opacity: 0.05),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 1.5,
              ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
            ),
          ],
        ),
      ),
    );
  }
}

