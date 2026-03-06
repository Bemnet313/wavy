import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  String _role = ''; // 'buyer', 'seller', or 'both'
  final _ageController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isAgeValid = false;
  bool _isNameValid = false;

  @override
  void dispose() {
    _ageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onAgeChanged(String value) {
    setState(() {
      final age = int.tryParse(value);
      _isAgeValid = (age != null && age >= 13 && age <= 70);
      if (_isAgeValid) {
        ref.read(preferencesProvider.notifier).setAge(age!);
      }
    });
  }

  void _onNameChanged(String value) {
    setState(() {
      _isNameValid = value.trim().length >= 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final locale = ref.watch(localeProvider);
    final tr = AppLocalizations.instance.tr;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/wavy_logo_new.png',
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr('pref_profile_design').toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr('pref_profile_design_subtitle').toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 1,
                      ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                    ),
                    const SizedBox(height: 48),

                    // ─── STEP 1: Buyer / Seller Role ────────
                    _SectionHeader(
                      icon: Icons.person_outline_rounded,
                      title: tr('pref_primary_focus').toUpperCase(),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        _RoleCard(
                          role: 'buyer',
                          icon: Icons.shopping_bag_outlined,
                          title: tr('pref_buy').toUpperCase(),
                          subtitle: tr('pref_acquire').toUpperCase(),
                          isSelected: _role == 'buyer',
                          onTap: () => setState(() => _role = 'buyer'),
                        ),
                        const SizedBox(height: 8),
                        _RoleCard(
                          role: 'seller',
                          icon: Icons.attach_money_rounded,
                          title: tr('pref_sell_role').toUpperCase(),
                          subtitle: tr('pref_list').toUpperCase(),
                          isSelected: _role == 'seller',
                          onTap: () => setState(() => _role = 'seller'),
                        ),
                        const SizedBox(height: 8),
                        _RoleCard(
                          role: 'both',
                          icon: Icons.sync_rounded,
                          title: tr('pref_both').toUpperCase(),
                          subtitle: tr('pref_hybrid').toUpperCase(),
                          isSelected: _role == 'both',
                          onTap: () => setState(() => _role = 'both'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // ─── STEP 2: Gender ────────────
                    _SectionHeader(
                      icon: Icons.wc_rounded,
                      title: tr('pref_gender_title').toUpperCase(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _GenderCard(
                          gender: 'female',
                          title: tr('pref_female').toUpperCase(),
                          icon: Icons.female_rounded,
                          isSelected: prefs.gender == 'female',
                          onTap: () => ref.read(preferencesProvider.notifier).setGender('female'),
                        ),
                        const SizedBox(width: 8),
                        _GenderCard(
                          gender: 'male',
                          title: tr('pref_male').toUpperCase(),
                          icon: Icons.male_rounded,
                          isSelected: prefs.gender == 'male',
                          onTap: () => ref.read(preferencesProvider.notifier).setGender('male'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // ─── STEP 3: Age ─────────────
                    _SectionHeader(
                      icon: Icons.cake_rounded,
                      title: tr('pref_age_title').toUpperCase(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ageController,
                      onChanged: _onAgeChanged,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white, 
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: tr('pref_age_hint'),
                        hintStyle: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.1),
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ─── STEP 4: Full Name ─────────────
                    _SectionHeader(
                      icon: Icons.badge_rounded,
                      title: tr('pref_name_title').toUpperCase(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      onChanged: _onNameChanged,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white, 
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: tr('pref_name_hint'),
                        hintStyle: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.1),
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Fixed bottom button
            Container(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: (_role.isNotEmpty && _isAgeValid && prefs.gender.isNotEmpty && _isNameValid)
                      ? () async {
                          String? errorMessage;
                          try {
                            await ref.read(authProvider.notifier).completeOnboarding(
                              fullName: _nameController.text.trim(),
                              role: _role,
                              gender: prefs.gender,
                              age: int.parse(_ageController.text.trim()),
                              language: locale,
                            );
                          } catch (e) {
                            errorMessage = e.toString();
                          }
                          // Guard ALL BuildContext usage after the await in one clear block
                          if (!mounted) return;
                          if (errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Verification failure: $errorMessage')),
                            );
                          } else {
                            context.go('/feed');
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    tr('pref_launch').toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Helper Widgets ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : WavyTheme.surfaceDark,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.white : WavyTheme.accentBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 20,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white54,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.black : Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: isSelected ? Colors.black45 : WavyTheme.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Colors.black, size: 24),
          ],
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String gender;
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.gender,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : WavyTheme.surfaceDark,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? Colors.white : WavyTheme.accentBorder,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white54,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.black : Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
