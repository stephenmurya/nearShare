import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:near_share/features/auth/presentation/pages/login_page.dart';
import 'package:near_share/features/auth/presentation/pages/phone_input_page.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isLoadingGoogle = false;
  bool _isLoadingGuest = false;

  Future<bool?> _showSwitchAccountDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Account already registered',
            style: GoogleFonts.interTight(),
          ),
          content: Text(
            'This account is already registered. Would you like to switch accounts? '
            '(Note: Guest data will not be merged).',
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
                'Switch',
                style: GoogleFonts.interTight(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Welcome to \nNearShare',
                style: theme.textTheme.headlineLarge?.copyWith(height: 1.1),
              ),
              const SizedBox(height: 12),
              Text(
                'Rent anything from your neighbors, easily and securely.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),

              // Primary Action: Continue with Google
              ElevatedButton(
                onPressed: _isLoadingGoogle || _isLoadingGuest
                    ? null
                    : () async {
                        setState(() => _isLoadingGoogle = true);
                        try {
                          final authCredential =
                              await authProvider.getGoogleCredential();
                          if (authCredential == null) {
                            setState(() => _isLoadingGoogle = false);
                            return;
                          }
                          final userCredential =
                              await authProvider.upgradeWithCredential(
                            authCredential,
                          );
                          if (userCredential != null && mounted) {
                            if (userCredential.additionalUserInfo?.isNewUser ??
                                false) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PhoneInputPage(),
                                ),
                              );
                            }
                          }
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'credential-already-in-use') {
                            final shouldSwitch =
                                await _showSwitchAccountDialog();
                            if (shouldSwitch == true && mounted) {
                              await authProvider.signOut();
                              final authCredential =
                                  await authProvider.getGoogleCredential();
                              if (authCredential != null) {
                                await authProvider.signInWithCredential(
                                  authCredential,
                                );
                              }
                            }
                            return;
                          }
                          if (mounted) {
                            String message = 'Google Sign-In failed';
                            if (e.code ==
                                'account-exists-with-different-credential') {
                              message =
                                  'An account already exists with this email. Please log in with your password.';
                            } else if (e.code == 'invalid-credential') {
                              message =
                                  'The credential is no longer valid or has expired.';
                            } else {
                              message = e.message ?? e.code;
                            }
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoadingGoogle = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _isLoadingGoogle
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(IconsaxPlusLinear.global, size: 20),
                          SizedBox(width: 12),
                          Text('Continue with Google'),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              // Secondary Action: Login with Email
              OutlinedButton(
                onPressed: _isLoadingGoogle || _isLoadingGuest
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                child: const Text('Login with Email'),
              ),
              const SizedBox(height: 24),

              // Tertiary (Icon Row): Phone and Apple (Visuals only)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialIconButton(IconsaxPlusLinear.call, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PhoneInputPage(),
                      ),
                    );
                  }),
                  const SizedBox(width: 20),
                  _socialIconButton(IconsaxPlusLinear.mobile, () {}),
                ],
              ),
              const SizedBox(height: 32),

              // Guest Link
              Center(
                child: TextButton(
                  onPressed: _isLoadingGoogle || _isLoadingGuest
                      ? null
                      : () async {
                          setState(() => _isLoadingGuest = true);
                          await authProvider.signInAsGuest();
                          if (mounted) setState(() => _isLoadingGuest = false);
                        },
                  child: _isLoadingGuest
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Continue as Guest',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialIconButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: _isLoadingGoogle || _isLoadingGuest ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 24, color: Colors.black),
      ),
    );
  }
}
