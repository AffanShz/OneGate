import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/glass_button.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
                  // Logo Placeholder
                  Icon(
                    Icons.security,
                    size: 80,
                    color: AppColors.brightTealBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "SecureVault",
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.brightTealBlue,
                    ),
                  ),
                  Text(
                    "Client-side encrypted notes",
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 40),

                  // Login Form
                  GlassCard(
                    child: Column(
                      children: [
                        const GlassTextField(hintText: "Email"),
                        const SizedBox(height: 16),
                        const GlassTextField(
                          hintText: "Password",
                          isPassword: true,
                        ),
                        const SizedBox(height: 24),
                        GlassButton(
                          text: "Login",
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {},
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
