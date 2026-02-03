import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:near_share/features/home/presentation/pages/main_scaffold.dart';

class PersonalizedHeader extends StatelessWidget {
  const PersonalizedHeader({super.key});

  String _getGreetingTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getFirstName(String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return 'User';
    }
    return displayName.split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
        child: Row(
          children: [
            // Profile & Greeting Section
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    // Profile Image
                    ClipOval(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: user?.photoURL != null
                            ? Image.network(
                                user!.photoURL!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Iconsax.user,
                                    size: 20,
                                    color: theme.colorScheme.onSurface,
                                  );
                                },
                              )
                            : Icon(
                                Iconsax.user,
                                size: 20,
                                color: theme.colorScheme.onSurface,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Greeting Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getGreetingTime(),
                            style: GoogleFonts.interTight(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getFirstName(user?.displayName),
                            style: GoogleFonts.interTight(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            IconButton(
              onPressed: () {
                // TODO: Implement notification functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')),
                );
              },
              icon: Icon(
                Iconsax.notification,
                color: theme.colorScheme.onSurface,
              ),
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                // TODO: Implement scan functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scan feature coming soon!')),
                );
              },
              icon: Icon(Iconsax.scan, color: theme.colorScheme.onSurface),
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }
}
