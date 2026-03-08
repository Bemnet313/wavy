import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _forceShowOnboarding = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _forceShowOnboarding = true);
      }
    });
  }

  Future<void> _showAvatarOptions(WavyUser user) async {
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _AvatarOption(
                icon: Icons.camera_alt_rounded,
                label: 'UPLOAD PHOTO',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadAvatar(user);
                },
              ),
              if (hasAvatar) ...[
                const SizedBox(height: 12),
                _AvatarOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'REMOVE PHOTO',
                  isDestructive: true,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _deleteAvatar(user);
                  },
                ),
              ],
              const SizedBox(height: 12),
              _AvatarOption(
                icon: Icons.close_rounded,
                label: 'CANCEL',
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(WavyUser user) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null || !mounted) return;

      setState(() => _isUploadingAvatar = true);
      final api = ref.read(apiServiceProvider);
      final url = await api.uploadAvatar(File(picked.path), user.id);
      ref.read(authProvider.notifier).setUser(user.copyWith(avatarUrl: url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _deleteAvatar(WavyUser user) async {
    setState(() => _isUploadingAvatar = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteAvatar(user.id);
      ref.read(authProvider.notifier).setUser(user.copyWith(clearAvatarUrl: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Remove failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final tr = AppLocalizations.instance.tr;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final savedItems = ref.watch(savedProvider);
    final listingsAsync = user != null ? ref.watch(sellerListingsProvider(user.id)) : const AsyncValue.data(<WavyItem>[]);
    final listingsCountText = listingsAsync.maybeWhen(
      data: (listings) => '${listings.length}',
      loading: () => '...',
      orElse: () => '—',
    );

    if (user == null && (!authState.isLoading || _forceShowOnboarding)) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                'PROFILE NOT COMPLETED',
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/language'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WavyTheme.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('COMPLETE ONBOARDING'),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: WavyTheme.neonCyan)),
      );
    }

    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Profile avatar
              GestureDetector(
                onTap: () => _showAvatarOptions(user),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
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
                      child: ClipOval(
                        child: hasAvatar
                            ? CachedNetworkImage(
                                imageUrl: user.avatarUrl!,
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: Colors.white10,
                                  child: Center(
                                    child: Text(
                                      user.name != null && user.name!.isNotEmpty ? user.name![0] : 'W',
                                      style: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Center(
                                  child: Text(
                                    user.name != null && user.name!.isNotEmpty ? user.name![0] : 'W',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  user.name != null && user.name!.isNotEmpty ? user.name![0] : 'W',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                    if (_isUploadingAvatar)
                      Container(
                        width: 96, height: 96,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                        child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showAvatarOptions(user),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: Colors.white.withValues(alpha: 0.3), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Update photo',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                user.phone.isEmpty ? tr('profile_no_phone') : user.phone,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 40),

              // Quick stats (Futuristic Minimalism)
              Row(
                children: [
                  _QuickStat(
                    value: '${savedItems.length}',
                    label: tr('profile_saved'),
                    icon: Icons.favorite_rounded,
                  ),
                  _QuickStat(
                    value: listingsCountText,
                    label: tr('profile_lists'),
                    icon: Icons.grid_view_rounded,
                    onTap: () => context.push('/my-listings'),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Menu items (Minimalist Glass)

              _ProfileMenuItem(
                icon: Icons.language_rounded,
                label: tr('profile_language'),
                subtitle: locale == 'am' ? tr('profile_language_en') : tr('profile_language_am'),
                trailing: Switch.adaptive(
                  value: locale == 'am',
                  activeThumbColor: Colors.white,
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
                label: tr('profile_preferences'),
                onTap: () => context.push('/settings/preferences'),
              ),
              _ProfileMenuItem(
                icon: Icons.notifications_rounded,
                label: tr('profile_notifications'),
                onTap: () => context.push('/settings/notifications'),
              ),
              _ProfileMenuItem(
                icon: Icons.info_outline_rounded,
                label: tr('profile_about'),
                onTap: () {},
              ),
              const SizedBox(height: 24),

              // Logout button (Neon Magenta Outlined)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        title: Text(
                          'TERMINATE SESSION?',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        content: Text(
                          'You will be signed out and will need to log in again.',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text(
                              'TERMINATE',
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      ref.read(authProvider.notifier).logout();
                      ref.read(onboardingCompleteProvider.notifier).reset();
                      context.go('/splash');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    tr('cta_terminate_session').toUpperCase(),
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
  final VoidCallback? onTap;

  const _QuickStat({
    required this.value,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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

class _AvatarOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _AvatarOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
