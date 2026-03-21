import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'NoteInputScreen.dart';
import 'NoteSequenceScreen.dart';
import '../utils/localization_helper.dart';
import '../widgets/custom_button.dart';

class InstrumentSelectionScreen extends StatefulWidget {
  const InstrumentSelectionScreen({super.key});

  @override
  _InstrumentSelectionScreenState createState() => _InstrumentSelectionScreenState();
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: originInstrument,
                  decoration: InputDecoration(labelText: loc.origin_instrument_label),
                  items: instruments.map((instr) => DropdownMenuItem(
                    value: instr,
                    child: Text(loc.getTranslation(instr)),
                  )).toList(),
                  onChanged: (value) => setState(() => originInstrument = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: targetInstrument,
                  decoration: InputDecoration(labelText: loc.target_instrument_label),
                  items: instruments.map((instr) => DropdownMenuItem(
                    value: instr,
                    child: Text(loc.getTranslation(instr)),
                  )).toList(),
                  onChanged: (value) => setState(() => targetInstrument = value),
                ),
                const SizedBox(height: 16),
                Text(loc.notation_input_label),
                DropdownButtonFormField<String>(
                  value: notationInput,
                  items: ['latina_option', 'american_option'].map((key) => DropdownMenuItem(
                    value: key,
                    child: Text(loc.getTranslation(key)),
                  )).toList(),
                  onChanged: (value) => setState(() => notationInput = value!),
                ),
                const SizedBox(height: 16),
                Text(loc.notation_output_label),
                DropdownButtonFormField<String>(
                  value: notationOutput,
                  items: ['latina_option', 'american_option'].map((key) => DropdownMenuItem(
                    value: key,
                    child: Text(loc.getTranslation(key)),
                  )).toList(),
                  onChanged: (value) => setState(() => notationOutput = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: accidentalPreference,
                  decoration: InputDecoration(labelText: loc.accidental_preference_label),
                  items: ['sharp_option', 'flat_option'].map((key) => DropdownMenuItem(
                    value: key,
                    child: Text(loc.getTranslation(key)),
                  )).toList(),
                  onChanged: (value) => setState(() => accidentalPreference = value!),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: loc.quick_mode_button,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteInputScreen(
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
                      child: CustomButton(
                        text: loc.sequence_mode_button,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteSequenceScreen(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

