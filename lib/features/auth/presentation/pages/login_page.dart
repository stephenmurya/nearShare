import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:near_share/features/auth/presentation/pages/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  AuthProvider? _authProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_authProvider == null) {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _authProvider!.addListener(_onAuthStateChanged);
    }
  }

  void _onAuthStateChanged() {
    if (_authProvider?.user != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // pop is now handled by the listener for robustness
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome Back', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue renting.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),

            // Email Field
            _buildTextField(
              'Email',
              _emailController,
              TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Password Field
            _buildTextField(
              'Password',
              _passwordController,
              TextInputType.visiblePassword,
              isPassword: true,
            ),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : () {},
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Login Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Login'),
            ),

            const SizedBox(height: 20),

            // Register Link
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Register',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    TextInputType type, {
    bool isPassword = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          obscureText: isPassword,
          decoration: InputDecoration(hintText: 'Enter your $label'),
        ),
      ],
    );
  }
}
