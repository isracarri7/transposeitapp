import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'MainMenuScreen.dart';

class SplashScreen extends StatefulWidget {
  final Function(Locale) onChangeLanguage;

  const SplashScreen({super.key, required this.onChangeLanguage});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _glowController;
  late AnimationController _barController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _glowAnimation;
  late Animation<double> _barWidth;

  @override
  void initState() {
    super.initState();

    // Logo: fade + scale + single rotation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.08, end: 0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Text: fade + slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Subtle glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Loading bar
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _barWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOutCubic),
    );

    // Start sequence
    _logoController.forward();
    _barController.forward();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _textController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child:
                  MainMenuScreen(onChangeLanguage: widget.onChangeLanguage),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _glowController.dispose();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0F1E35),
              Color(0xFF142842),
              Color(0xFF0F1E35),
              Color(0xFF0A1628),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing logo
              AnimatedBuilder(
                animation:
                    Listenable.merge([_logoController, _glowController]),
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _logoFade,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotation.value * math.pi,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(
                                    _glowAnimation.value *
                                        _logoFade.value *
                                        0.35),
                                blurRadius: 60,
                                spreadRadius: 15,
                              ),
                              BoxShadow(
                                color: const Color(0xFF4A90D9).withOpacity(
                                    _glowAnimation.value *
                                        _logoFade.value *
                                        0.1),
                                blurRadius: 100,
                                spreadRadius: 30,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 200,
                            height: 200,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 36),

              // App title
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      const Text(
                        'Transpose-it',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Urbanist',
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Localizations.localeOf(context).languageCode == 'es'
                            ? 'Tu música, en cualquier tono'
                            : 'Your music, any key',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFD4AF37),
                          fontFamily: 'Urbanist',
                          letterSpacing: 4.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Loading bar
              AnimatedBuilder(
                animation: _barController,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _barWidth.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFD4AF37),
                                Color(0xFFE8C84A),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
