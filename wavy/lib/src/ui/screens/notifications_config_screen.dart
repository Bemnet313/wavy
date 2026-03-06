import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class NotificationsConfigScreen extends ConsumerStatefulWidget {
  const NotificationsConfigScreen({super.key});

  @override
  ConsumerState<NotificationsConfigScreen> createState() => _NotificationsConfigScreenState();
}

class _NotificationsConfigScreenState extends ConsumerState<NotificationsConfigScreen> {
  bool pushEnabled = true;
  bool messagesEnabled = true;
  bool promoEnabled = false;

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.instance.tr;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          tr('notif_title'),
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildToggle(
            label: tr('notif_push'),
            value: pushEnabled,
            onChanged: (v) => setState(() => pushEnabled = v),
          ),
          _buildToggle(
            label: tr('notif_dm'),
            value: messagesEnabled,
            onChanged: pushEnabled ? (v) => setState(() => messagesEnabled = v) : null,
          ),
          _buildToggle(
            label: tr('notif_promos'),
            value: promoEnabled,
            onChanged: pushEnabled ? (v) => setState(() => promoEnabled = v) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({required String label, required bool value, void Function(bool)? onChanged}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: onChanged == null ? Colors.white38 : Colors.white,
          fontWeight: FontWeight.bold,
        ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: WavyTheme.neonCyan.withValues(alpha: 0.5),
      ),
    );
  }
}
