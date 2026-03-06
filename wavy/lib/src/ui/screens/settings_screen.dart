import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = AppLocalizations.instance.tr;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          tr('settings_title'),
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
          _buildDisabledTile(
            icon: Icons.currency_exchange_rounded, 
            label: tr('settings_currency'), 
            trailingText: 'ETB',
          ),
          _buildDisabledTile(
            icon: Icons.dark_mode_rounded, 
            label: tr('settings_theme'), 
            trailingText: tr('settings_theme_dark'),
          ),
          _buildDisabledTile(
            icon: Icons.straighten_rounded, 
            label: tr('settings_measurements'), 
            trailingText: 'CM',
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledTile({required IconData icon, required String label, required String trailingText}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(icon, color: Colors.white54),
      title: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
      ),
      trailing: Text(
        trailingText,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white54,
          fontWeight: FontWeight.w600,
        ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
      ),
    );
  }
}
