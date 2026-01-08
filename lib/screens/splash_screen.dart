import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Logic moved to AuthWrapper to prevent race conditions
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white, // Or adapt to theme
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
