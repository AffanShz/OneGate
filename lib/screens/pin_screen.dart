import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onegate/services/pin_service.dart';
import 'package:onegate/screens/home_screen.dart';
import '../core/constants.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup; // true = Create PIN, false = Enter PIN

  const PinScreen({super.key, this.isSetup = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _enteredPin = '';
  String _confirmPin = ''; // Only for setup mode
  bool _isConfirming = false; // Only for setup mode
  String _message = 'Enter your 4-digit PIN';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    if (widget.isSetup) {
      _message = 'Create a 4-digit PIN';
    }
  }

  void _onDigitPress(String digit) {
    setState(() {
      if (_enteredPin.length < 4) {
        _enteredPin += digit;
        _isError = false;
        if (_enteredPin.length == 4) {
          _handlePinComplete();
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      }
    });
  }

  Future<void> _handlePinComplete() async {
    if (widget.isSetup) {
      // Setup Mode
      if (!_isConfirming) {
        // First entry done, switch to confirm
        setState(() {
          _confirmPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
          _message = 'Confirm your PIN';
        });
      } else {
        // Confirmation entry done
        if (_enteredPin == _confirmPin) {
          await PinService.savePin(_enteredPin);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HomeScreen(secretKey: _enteredPin),
              ),
            );
          }
        } else {
          // Mismatch
          setState(() {
            _enteredPin = '';
            _confirmPin = '';
            _isConfirming = false;
            _message = 'PINs did not match. Try again.';
            _isError = true;
          });
        }
      }
    } else {
      // Login Mode
      bool isValid = await PinService.verifyPin(_enteredPin);
      if (isValid) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeScreen(secretKey: _enteredPin),
            ),
          );
        }
      } else {
        setState(() {
          _enteredPin = '';
          _message = 'Incorrect PIN. Try again.';
          _isError = true;
        });
      }
    }
  }

  Widget _buildDigitButton(String digit) {
    return GestureDetector(
      onTap: () => _onDigitPress(digit),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter:
              ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glass blur effect
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1), // Frosted glass color
              border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5), // Glass border
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowGrey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                digit,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.shadowGrey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.porcelain,
      body: Stack(
        children: [
          // Background Orbs (Enhanced)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brightTealBlue.withOpacity(0.4),
                    AppColors.brightTealBlue.withOpacity(0.0),
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
                    AppColors.rosewood.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock Icon in Glass Start
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brightTealBlue.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: AppColors.brightTealBlue,
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  _message,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _isError ? AppColors.rosewood : AppColors.shadowGrey,
                  ),
                ),

                const SizedBox(height: 40),

                // PIN Dots (Glass Spheres)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    bool filled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? AppColors.brightTealBlue
                            : Colors.transparent,
                        border: Border.all(
                          color: filled
                              ? AppColors.brightTealBlue
                              : AppColors.shadowGrey.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.brightTealBlue.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 60),

                // Keypad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDigitButton('1'),
                          _buildDigitButton('2'),
                          _buildDigitButton('3'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDigitButton('4'),
                          _buildDigitButton('5'),
                          _buildDigitButton('6'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDigitButton('7'),
                          _buildDigitButton('8'),
                          _buildDigitButton('9'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 70), // Spacer
                          _buildDigitButton('0'),
                          // Backspace Button
                          GestureDetector(
                            onTap: _onBackspace,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.backspace_outlined,
                                  color: AppColors.shadowGrey.withOpacity(0.7),
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
