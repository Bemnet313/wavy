import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/sell')) return 0;
    if (location.startsWith('/saved')) return 1;
    if (location.startsWith('/messages')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 2; // Default to Feed (/feed)
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _currentIndex(context);
    final unreadCount = ref.watch(unreadConversationCountProvider).valueOrNull ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: Text(
              'EXIT WAVY?',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  'EXIT',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: SafeArea(
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.add_box_outlined,
                    label: 'SELL',
                    isActive: index == 0,
                    onTap: () => context.go('/sell/new'),
                  ),
                  _NavItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'SAVED',
                    isActive: index == 1,
                    onTap: () => context.go('/saved'),
                  ),
                  _CenterButton(
                    icon: Icons.whatshot_rounded,
                    isActive: index == 2,
                    onTap: () => context.go('/feed'),
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'MESSAGES',
                    isActive: index == 3,
                    onTap: () => context.go('/messages'),
                    showBadge: unreadCount > 0,
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'PROFILE',
                    isActive: index == 4,
                    onTap: () => context.go('/profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool showBadge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
                ),
                if (showBadge)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 7,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
                letterSpacing: 1.0,
              ).copyWith(fontFamilyFallback: const ['Noto Sans Ethiopic']),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _CenterButton({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.black,
          size: 28,
        ),
      ),
    );
  }
}
