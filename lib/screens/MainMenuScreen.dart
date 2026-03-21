import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/app_scaffold.dart';
import 'NoteDraftScreen.dart';
import 'TransposeByTone.dart';
import 'InstrumentSelectionScreen.dart';

class MainMenuScreen extends StatelessWidget {
  final Function(Locale) onChangeLanguage;

  const MainMenuScreen({super.key, required this.onChangeLanguage});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language toggle pill
          Container(
            margin: const EdgeInsets.only(right: 16, top: 4),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLangButton('EN', const Locale('en'), currentLocale),
                _buildLangButton('ES', const Locale('es'), currentLocale),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0F1E35),
              Color(0xFF142842),
              Color(0xFF0F1E35),
              Color(0xFF0A1628),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with subtle glow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.12),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.app_title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Urbanist',
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.tagline,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFD4AF37).withOpacity(0.7),
                    fontFamily: 'Urbanist',
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 48),

                // Menu buttons
                _buildMenuButton(
                  icon: Icons.tune_rounded,
                  label: loc.button_transpose_by_tone,
                  subtitle: loc.menu_subtitle_tone,
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(
                        page: const TransposeByToneScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  icon: Icons.swap_horiz_rounded,
                  label: loc.button_transpose_between_instruments,
                  subtitle: loc.menu_subtitle_instruments,
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(
                        page: const InstrumentSelectionScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  icon: Icons.edit_note_rounded,
                  label: loc.button_digitalize_notes,
                  subtitle: loc.menu_subtitle_digitalize,
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(
                        page: const NoteDraftScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(
      String label, Locale locale, Locale currentLocale) {
    final isSelected = currentLocale.languageCode == locale.languageCode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChangeLanguage(locale);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4AF37)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0A1628) : Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            fontFamily: 'Urbanist',
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFFD4AF37).withOpacity(0.08),
        highlightColor: const Color(0xFFD4AF37).withOpacity(0.04),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFD4AF37), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 12,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.15),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
