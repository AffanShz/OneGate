import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.shadowGrey),
        title: Text("Settings", style: AppTextStyles.heading),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ACCOUNT SECURITY", style: AppTextStyles.label),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "Change Password",
                          style: AppTextStyles.body,
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppColors.shadowGrey,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 40,
                        color: AppColors.brightTealBlue,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CRYPTO EXPLANATION",
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Learn about how your data is protected with advanced encryption techniques. Your keys remain on your device.",
                              style: AppTextStyles.label,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                GlassButton(
                  text: "LOGOUT",
                  isPrimary: false,
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),

                const SizedBox(height: 32),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ACADEMIC INFO", style: AppTextStyles.label),
                      const SizedBox(height: 16),
                      _buildInfoBullet("Classic + Modern Cryptography"),
                      const SizedBox(height: 8),
                      _buildInfoBullet("Client-side Encryption"),
                      const SizedBox(height: 8),
                      _buildInfoBullet("Flutter Liquid Glass UI"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brightTealBlue,
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: AppTextStyles.body),
      ],
    );
  }
}
