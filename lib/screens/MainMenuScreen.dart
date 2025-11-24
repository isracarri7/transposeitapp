import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'NoteDraftScreen.dart';
import 'TransposeByTone.dart';
import 'InstrumentSelectionScreen.dart';

class MainMenuScreen extends StatelessWidget {
  final Function(Locale) onChangeLanguage;

  const MainMenuScreen({super.key, required this.onChangeLanguage});
//Agrego una linea para que me deje subirla
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 🔄 Selector de idioma con banderas
          IconButton(
            icon: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
            tooltip: 'English',
            onPressed: () => onChangeLanguage(const Locale('en')),
          ),
          IconButton(
            icon: const Text('🇲🇽', style: TextStyle(fontSize: 22)),
            tooltip: 'Español',
            onPressed: () => onChangeLanguage(const Locale('es')),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1A26), Color(0xFF173142), Color(0xFF1E3B54)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🖼️ Logo centrado
                SizedBox(
                  height: 300,
                  width: 300,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                // Título
                Text(
                  loc.app_title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Urbanist',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 48),

                // Botón 1
                ElevatedButton.icon(
                  icon: const Icon(Icons.tune),
                  label: Text(loc.button_transpose_by_tone),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransposeByToneScreen()),
                    );
                  },
                  style: _buttonStyle(),
                ),
                const SizedBox(height: 20),

                // Botón 2
                ElevatedButton.icon(
                  icon: const Icon(Icons.music_note),
                  label: Text(loc.button_transpose_between_instruments),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InstrumentSelectionScreen()),
                    );
                  },
                  style: _buttonStyle(),
                ),
                const SizedBox(height: 20),

                // Botón 3
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: Text(loc.button_digitalize_notes),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NoteDraftScreen()),
                    );
                  },
                  style: _buttonStyle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(60),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0A2342),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      shadowColor: Colors.black54,
    );
  }
}
