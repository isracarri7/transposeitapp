import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'MainMenuScreen.dart';

class SplashScreen extends StatefulWidget {
  final Function(Locale) onChangeLanguage;

  const SplashScreen({super.key, required this.onChangeLanguage});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeSlideController;
  late AnimationController _rotationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Fade & slide
    _fadeSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeSlideController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeSlideController, curve: Curves.easeOut));

    // Rotación
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOutCubic),
    );

    _fadeSlideController.forward();

    // Navegar al menú después de animación
    Future.delayed(const Duration(milliseconds: 3600), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: MainMenuScreen(onChangeLanguage: widget.onChangeLanguage),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeSlideController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1500),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1A26),
              Color(0xFF173142),
              Color(0xFF1E3B54),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (_, child) => Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: child,
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 400,
                  height: 400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
