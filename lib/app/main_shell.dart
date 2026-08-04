import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/explore/presentation/explore_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    ExploreScreen(),
    _CreatePlaceholderScreen(),
    PublicProfileScreen(),
  ];

  void _onDestinationSelected(int index) {
    if (index == 2) {
      context.push('/projects/create');
      return;
    }

    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _TchakaBottomNavigation(
        currentIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
class _TchakaBottomNavigation extends StatelessWidget {
  const _TchakaBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        12,
        0,
        12,
        10,
      ),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(
            alpha: 0.96,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withValues(
              alpha: 0.12,
            ),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
              color: Colors.black.withValues(
                alpha: 0.28,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavigationItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
                selected: currentIndex == 0,
                onTap: () =>
                    onDestinationSelected(0),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Explorer',
                selected: currentIndex == 1,
                onTap: () =>
                    onDestinationSelected(1),
              ),
            ),
            Expanded(
              child: _CreateNavigationItem(
                onTap: () =>
                    onDestinationSelected(2),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                selected: currentIndex == 3,
                onTap: () =>
                    onDestinationSelected(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final activeColor = colorScheme.primary;
    final inactiveColor =
        colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 220,
            ),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 7,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? activeColor.withValues(
                      alpha: 0.10,
                    )
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  transitionBuilder:
                      (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    selected
                        ? activeIcon
                        : icon,
                    key: ValueKey<bool>(selected),
                    size: selected ? 25 : 23,
                    color: selected
                        ? activeColor
                        : inactiveColor,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  curve: Curves.easeOut,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? activeColor
                            : inactiveColor,
                      ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateNavigationItem extends StatelessWidget {
  const _CreateNavigationItem({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Créer un projet',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedScale(
              scale: 1,
              duration: const Duration(
                milliseconds: 180,
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary
                          .withValues(alpha: 0.30),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 31,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _CreatePlaceholderScreen
    extends StatelessWidget {
  const _CreatePlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
