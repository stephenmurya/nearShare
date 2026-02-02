import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:near_share/core/theme/app_theme.dart';

class FloatingNavbar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isScrolling; // To trigger shrink on scroll

  const FloatingNavbar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isScrolling = false,
  });

  @override
  State<FloatingNavbar> createState() => _FloatingNavbarState();
}

class _FloatingNavbarState extends State<FloatingNavbar> {
  bool _isExpanded = false;
  Timer? _shrinkTimer;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Iconsax.home, 'label': 'NearShare'},
    {'icon': Iconsax.box, 'label': 'Rentals'},
    {'icon': Iconsax.bag, 'label': 'Items'},
    {'icon': Iconsax.setting_2, 'label': 'Settings'},
  ];

  @override
  void didUpdateWidget(covariant FloatingNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScrolling && _isExpanded) {
      _shrink();
    }
  }

  void _expand() {
    if (_isExpanded) {
      _resetShrinkTimer();
      return;
    }
    setState(() {
      _isExpanded = true;
    });
    _resetShrinkTimer();
  }

  void _shrink() {
    if (!_isExpanded) return;
    setState(() {
      _isExpanded = false;
    });
    _shrinkTimer?.cancel();
  }

  void _resetShrinkTimer() {
    _shrinkTimer?.cancel();
    _shrinkTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isExpanded) {
        _shrink();
      }
    });
  }

  @override
  void dispose() {
    _shrinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Dimensions
    final double collapsedWidth = 220.0;
    final double expandedWidth = screenWidth - 40; // 20px padding on each side
    final double height = _isExpanded ? 75.0 : 60.0;

    return GestureDetector(
      onTap: _expand, // Expand on tap if not already
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        width: _isExpanded ? expandedWidth : collapsedWidth,
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.6) // Darker background for pop
              : Colors.white.withOpacity(0.8), // Whiter background for contrast
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Stronger shadow
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = widget.selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    _expand(); // Ensure expanded on interaction
                    widget.onItemSelected(index);
                  },
                  child: Container(
                    color: Colors.transparent, // Hit test target
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with glow indicator
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow
                            if (isSelected)
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryBlue.withOpacity(0.4),
                                ),
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 5,
                                      sigmaY: 5,
                                    ),
                                    child: const SizedBox(),
                                  ),
                                ),
                              ),
                            Icon(
                              item['icon'],
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                              size: 24,
                            ),
                          ],
                        ),

                        // Animated Label
                        if (_isExpanded)
                          Flexible(
                            // Prevents overflow during animation start
                            child: AnimatedOpacity(
                              opacity: _isExpanded ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  item['label'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : theme.colorScheme.onSurface,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
