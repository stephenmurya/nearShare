import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:near_share/features/auth/presentation/widgets/auth_guard_sheet.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:near_share/features/home/presentation/pages/saved_items_page.dart';
import 'package:near_share/features/home/presentation/pages/my_products_page.dart';
import 'package:near_share/features/home/presentation/pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:near_share/features/home/models/product.dart';

import 'package:near_share/features/home/presentation/widgets/floating_navbar.dart';
import 'package:near_share/features/chat/presentation/pages/chat_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  bool _isScrolling = false;

  final List<String> _titles = [
    'NearShare',
    'My Rentals',
    'Chat',
    'My Items',
    'Settings',
  ];

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(child: Text('My Rentals')),
        );
      case 2:
        return const ChatPage();
      case 3:
        return MyProductsPage();
      case 4:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(child: Text('App Settings')),
        );
      default:
        return const HomePage();
    }
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (!_isScrolling) {
        setState(() {
          _isScrolling = true;
        });
        // Reset scrolling state after a short delay so expansion can work again if needed immediately
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isScrolling = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    // Using Stack to float the navbar over the content
    return Scaffold(
      extendBody: true, // Content goes behind the navbar
      appBar: _selectedIndex != 0
          ? AppBar(
              title: Text(
                _titles[_selectedIndex],
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 22,
                ),
              ),
              centerTitle: false,
              actions: [
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? const Icon(IconsaxPlusLinear.user, size: 18)
                            : null,
                      ),
                    ),
                  ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // Content Layer with Scroll Listener
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _onScroll(notification);
              return false;
            },
            child: _getBody(),
          ),

          // Floating Navbar Layer
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: FloatingNavbar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    final currentUser =
                        fb_auth.FirebaseAuth.instance.currentUser;
                    final isGuest =
                        currentUser == null || currentUser.isAnonymous;
                    if (index == 3 && isGuest) {
                      showAuthGuardSheet(
                        context,
                        title: 'Sign in to start listing',
                        message:
                            'Sign in to start listing your gear and manage your rentals.',
                      );
                      return;
                    }
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  isScrolling: _isScrolling,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _pushMockDataToFirestore(BuildContext context) async {
    try {
      final rawJson = await rootBundle.loadString('assets/mock_db.json');
      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      final productsJson = (data['products'] as List<dynamic>? ?? []);

      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('products');

      for (final item in productsJson) {
        final product = Product.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        final docRef = product.id.isNotEmpty
            ? collection.doc(product.id)
            : collection.doc();
        batch.set(docRef, {
          ...product.toFirestoreMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Success: ${productsJson.length} products uploaded',
              style: GoogleFonts.interTight(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload failed. Please try again.',
              style: GoogleFonts.interTight(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _clearAllProducts(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Are you sure?',
            style: GoogleFonts.interTight(),
          ),
          content: Text(
            'This will wipe the live marketplace.',
            style: GoogleFonts.interTight(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.interTight(),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: GoogleFonts.interTight(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    const batchLimit = 450;
    final collection = FirebaseFirestore.instance.collection('products');
    final snapshot = await collection.get();

    for (var i = 0; i < snapshot.docs.length; i += batchLimit) {
      final batch = FirebaseFirestore.instance.batch();
      final slice = snapshot.docs.skip(i).take(batchLimit);
      for (final doc in slice) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Marketplace cleared.',
            style: GoogleFonts.interTight(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final isAdmin =
        fb_auth.FirebaseAuth.instance.currentUser?.email ==
        'stephenmurya@gmail.com';
    final isGuest = user == null || user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            IconsaxPlusLinear.arrow_left_1,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? const Icon(IconsaxPlusLinear.user, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Guest',
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text(
                    user?.email ?? 'guest@nearshare.app',
                    style: GoogleFonts.interTight(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isGuest) ...[
              const SizedBox(height: 24),
              Text(
                'Sign in to begin to post your items for rent, and to be able to rent out items.',
                style: GoogleFonts.interTight(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 40),

            ListTile(
              leading: const Icon(IconsaxPlusLinear.heart),
              title: Text(
                'Saved Items',
                style: GoogleFonts.interTight(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              trailing: const Icon(IconsaxPlusLinear.arrow_right_3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedItemsPage(),
                  ),
                );
              },
            ),
            Divider(color: theme.colorScheme.outlineVariant),

            if (isAdmin) ...[
              const SizedBox(height: 24),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Developer Tools',
                  style: GoogleFonts.interTight(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton(
                    onPressed: () => _pushMockDataToFirestore(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      'Push Mock Data to Firestore',
                      style: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _clearAllProducts(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      'Clear All Firestore Products',
                      style: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isGuest) {
                    authProvider.signOut();
                  } else {
                    authProvider.signOut();
                  }
                  Navigator.of(context).pop();
                },
                child: Text(
                  isGuest ? 'Sign In' : 'Sign Out',
                  style: GoogleFonts.interTight(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
