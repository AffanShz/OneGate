import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/glass_button.dart';

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );

      if (!mounted) return;

      // Navigate to Home or Login depending on email confirmation requirement
      // For now, assume auto-login or redirect to login to confirm
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Registration successful! Please check email to confirm or login.')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      body: Stack(
        children: [
          // Background Gradient Blobs (Reused from Login)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brightTealBlue.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.rosewood.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.security,
                    size: 60,
                    color: AppColors.brightTealBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Create Account",
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.brightTealBlue,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GlassCard(
                    child: Column(
                      children: [
                        GlassTextField(
                          hintText: "Username",
                          controller: _usernameController,
                        ),
                        const SizedBox(height: 16),
                        GlassTextField(
                          hintText: "Email",
                          controller: _emailController,
                        ),
                        const SizedBox(height: 16),
                        GlassTextField(
                          hintText: "Password",
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 16),
                        GlassTextField(
                          hintText: "Confirm Password",
                          isPassword: true,
                          controller: _confirmPasswordController,
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : GlassButton(
                                text: "Register",
                                onPressed: _register,
                              ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Already have an account? Login",
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.brightTealBlue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
