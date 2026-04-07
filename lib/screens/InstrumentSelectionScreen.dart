import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'NoteInputScreen.dart';
import 'NoteSequenceScreen.dart';
import '../utils/localization_helper.dart';
import '../widgets/app_scaffold.dart';


class InstrumentSelectionScreen extends StatefulWidget {
  const InstrumentSelectionScreen({super.key});

  @override
  State<InstrumentSelectionScreen> createState() =>
      _InstrumentSelectionScreenState();
}

class _InstrumentSelectionScreenState extends State<InstrumentSelectionScreen> {
  final List<String> instruments = [
    'piano', 'trumpet', 'alto_sax', 'tenor_sax',
    'clarinet_bb', 'french_horn', 'clarinet_a', 'flute',
  ];

  String? originInstrument = 'piano';
  String? targetInstrument = 'trumpet';
  String notationInput = 'latina_option';
  String notationOutput = 'latina_option';
  String accidentalPreference = 'sharp_option';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AppScaffold(
      title: loc.button_transpose_between_instruments,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Origin instrument
            buildStyledDropdown(
              value: originInstrument!,
              label: loc.origin_instrument_label,
              items: instruments,
              translateFn: (key) => loc.getTranslation(key),
              onChanged: (value) => setState(() => originInstrument = value),
            ),
            const SizedBox(height: 12),

            // Swap button
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      final temp = originInstrument;
                      originInstrument = targetInstrument;
                      targetInstrument = temp;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.swap_vert_rounded,
                      color: Color(0xFFD4AF37),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Target instrument
            buildStyledDropdown(
              value: targetInstrument!,
              label: loc.target_instrument_label,
              items: instruments,
              translateFn: (key) => loc.getTranslation(key),
              onChanged: (value) => setState(() => targetInstrument = value),
            ),

            const SizedBox(height: 24),

            // Divider
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 16),

            // Notation input
            buildSectionLabel(loc.notation_input_label),
            buildStyledDropdown(
              value: notationInput,
              label: loc.notation_type_label,
              items: ['latina_option', 'american_option'],
              translateFn: (key) => loc.getTranslation(key),
              onChanged: (value) => setState(() => notationInput = value!),
            ),
            const SizedBox(height: 12),

            // Notation output
            buildSectionLabel(loc.notation_output_label),
            buildStyledDropdown(
              value: notationOutput,
              label: loc.notation_type_label,
              items: ['latina_option', 'american_option'],
              translateFn: (key) => loc.getTranslation(key),
              onChanged: (value) => setState(() => notationOutput = value!),
            ),
            const SizedBox(height: 12),

            // Accidentals
            buildStyledDropdown(
              value: accidentalPreference,
              label: loc.accidental_preference_label,
              items: ['sharp_option', 'flat_option'],
              translateFn: (key) => loc.getTranslation(key),
              onChanged: (value) =>
                  setState(() => accidentalPreference = value!),
            ),

            const SizedBox(height: 32),

            // Mode buttons
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    icon: Icons.touch_app_rounded,
                    label: loc.quick_mode_button,
                    onTap: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(
                          page: NoteInputScreen(
                            originInstrument: originInstrument!,
                            targetInstrument: targetInstrument!,
                            notationInput: notationInput,
                            notationOutput: notationOutput,
                            accidentalPreference: accidentalPreference,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeCard(
                    icon: Icons.queue_music_rounded,
                    label: loc.sequence_mode_button,
                    onTap: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(
                          page: NoteSequenceScreen(
                            originInstrument: originInstrument!,
                            targetInstrument: targetInstrument!,
                            notationInput: notationInput,
                            notationOutput: notationOutput,
                            accidentalPreference: accidentalPreference,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF132035),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFD4AF37), size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
