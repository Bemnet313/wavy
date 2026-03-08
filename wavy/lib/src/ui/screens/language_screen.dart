import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                
                // Logo
                Image.asset(
                  'assets/wavy_logo_new.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                
                // Subtitle
                Text(
                  (currentLocale == 'am' 
                    ? 'የተመረጡ ቪንቴጅ ልብሶች።'
                    : 'Curated vintage for the future.').toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    height: 1.6,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.4),
                  ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                ),
                
                const Spacer(flex: 3),

                // Inline Language Toggle (Minimalist Glass)
                Container(
                  height: 56,
                  decoration: GlassDecoration.dark(opacity: 0.05).copyWith(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _LanguageToggle(
                          label: 'EN',
                          isSelected: currentLocale == 'en',
                          onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
                        ),
                      ),
                      Expanded(
                        child: _LanguageToggle(
                          label: 'አማ',
                          isSelected: currentLocale == 'am',
                          onTap: () => ref.read(localeProvider.notifier).setLocale('am'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Continue button (Neon Magenta)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => context.go('/signin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      currentLocale == 'am' ? 'እንጀምር 🌊' : "Let's Go 🌊",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16, 
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Footer
                Text(
                  currentLocale == 'am'
                      ? 'በመቀጠልዎ በውሎቻችን እና ስምምነቶቻችን ይስማማሉ።'
                      : 'By continuing, you agree to our Terms.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.2),
                    letterSpacing: 1,
                  ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.black : Colors.white,
            letterSpacing: 1,
          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
        ),
      ),
    );
  }
}
