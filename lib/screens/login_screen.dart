import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/glass_button.dart';
import 'package:onegate/services/pin_service.dart';
import 'package:onegate/screens/pin_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      // Check for PIN or force setup
      bool hasPin = await PinService.hasPin();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PinScreen(isSetup: !hasPin),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
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
          // Background Gradient Blobs
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
                    size: 80,
                    color: AppColors.brightTealBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "OneGate",
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.brightTealBlue,
                    ),
                  ),
                  Text(
                    "Secure Access & Storage",
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 40),

                  // Login Form
                  GlassCard(
                    child: Column(
                      children: [
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
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : GlassButton(
                                text: "Login",
                                onPressed: _login,
                              ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Register",
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
