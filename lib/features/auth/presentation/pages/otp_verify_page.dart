import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

class OTPVerifyPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  const OTPVerifyPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OTPVerifyPage> createState() => _OTPVerifyPageState();
}

class _OTPVerifyPageState extends State<OTPVerifyPage> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  void _verifyOTP(String pin) async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: pin,
      );

      await authProvider.signInWithPhone(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        // Navigate back to root where AuthWrapper will show the Welcome screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verify Code',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00296B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 4-digit code to ${widget.phoneNumber} via WhatsApp.',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 48),

            Center(
              child: Pinput(
                length: 4,
                controller: _pinController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: const Color(0xFF00296B)),
                  ),
                ),
                onCompleted: _verifyOTP,
              ),
            ),

            const SizedBox(height: 48),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Column(
                      children: [
                        Text(
                          "Didn't receive code?",
                          style: GoogleFonts.inter(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Resend Code',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF00296B),
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
}
