import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final savedItems = ref.watch(savedProvider);

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: WavyTheme.neonCyan)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Profile avatar (Minimal White Border)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.name?[0] ?? 'B',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                (user.name ?? 'Wavy User').toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
              ),
              const SizedBox(height: 4),
              Text(
                user.phone,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      (locale == 'am' ? 'ተረጋግጧል' : 'VERIFIED').toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Quick stats (Futuristic Minimalism)
              Row(
                children: [
                  _QuickStat(
                    value: '${savedItems.length}',
                    label: locale == 'am' ? 'የተቀመጡ' : 'SAVED',
                    icon: Icons.favorite_rounded,
                  ),
                  _QuickStat(
                    value: '0', // In future: fetch listings count
                    label: locale == 'am' ? 'ዝርዝሮች' : 'LISTS',
                    icon: Icons.grid_view_rounded,
                  ),
                  _QuickStat(
                    value: '16',
                    label: locale == 'am' ? 'ቀናት ሰንሰለት' : 'DAYS STREAK',
                    icon: Icons.local_fire_department_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Menu items (Minimalist Glass)
              _ProfileMenuItem(
                icon: Icons.store_rounded,
                label: locale == 'am' ? 'የሻጭ ዳሽቦርድ' : 'SELLER DASHBOARD',
                subtitle: locale == 'am' ? 'ዝርዝሮችን ያስተዳድሩ' : 'MANAGE YOUR DROPS',
                onTap: () => context.push('/seller/${user.id}'),
              ),
              _ProfileMenuItem(
                icon: Icons.language_rounded,
                label: locale == 'am' ? 'ቋንቋ' : 'LANGUAGE',
                subtitle: locale == 'am' ? 'ENGLISH' : 'አማርኛ',
                trailing: Switch.adaptive(
                  value: locale == 'am',
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white.withValues(alpha: 0.2),
                  inactiveThumbColor: Colors.white.withValues(alpha: 0.4),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                  onChanged: (_) {
                    final newLocale = locale == 'am' ? 'en' : 'am';
                    ref.read(localeProvider.notifier).setLocale(newLocale);
                  },
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.tune_rounded,
                label: locale == 'am' ? 'ምርጫዎች' : 'PREFERENCES',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.notifications_rounded,
                label: locale == 'am' ? 'ማሳወቂያዎች' : 'NOTIFICATIONS',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.info_outline_rounded,
                label: locale == 'am' ? 'ስለ ቦንዳ' : 'ABOUT WAVY',
                onTap: () {},
              ),
              const SizedBox(height: 24),

              // Logout button (Neon Magenta Outlined)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    ref.read(onboardingCompleteProvider.notifier).state = false;
                    context.go('/splash');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                        child: Text(
                          (locale == 'am' ? 'ውጣ' : 'TERMINATE SESSION').toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _QuickStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: GlassDecoration.dark(opacity: 0.05),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 10),
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
              label.toUpperCase(),
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

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: GlassDecoration.dark(opacity: 0.05),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 1,
                      ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.2), size: 20),
          ],
        ),
      ),
    );
  }
}
