import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/custom_button.dart';

class NoteInputScreen extends StatelessWidget {
  final String originInstrument;
  final String targetInstrument;
  final String notationInput;
  final String notationOutput;
  final String accidentalPreference;

  NoteInputScreen({
    required this.originInstrument,
    required this.targetInstrument,
    required this.notationInput,
    required this.notationOutput,
    required this.accidentalPreference,
    super.key,
  });

  final List<String> latinNotes = ['Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'];
  final List<String> americanNotes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final List<String> latinNotesFlat = ['Do', 'Reb', 'Re', 'Mib', 'Mi', 'Fa', 'Solb', 'Sol', 'Lab', 'La', 'Sib', 'Si'];
  final List<String> americanNotesFlat = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final notes = notationInput == 'latina_option'
        ? (accidentalPreference == 'sharp_option' ? latinNotes : latinNotesFlat)
        : (accidentalPreference == 'sharp_option' ? americanNotes : americanNotesFlat);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              Text(
                loc.select_note_title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: notes.map((note) {
                  return CustomButton(
                    text: note,
                    onPressed: () {
                      final index = notes.indexOf(note);
                      final transposedIndex = _transpose(index, originInstrument, targetInstrument);
                      final transposedNote = _getNote(transposedIndex);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(loc.result_dialog_title),
                          content: Text(
                            loc.note_transposition_format(note, transposedNote),
                            style: const TextStyle(fontSize: 24),
                          ),
                          actions: [
                            TextButton(
                              child: Text(loc.ok_button),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _transpose(int inputIndex, String from, String to) {
    final offsets = {
      'piano': 0,
      'trumpet': 2,
      'alto_sax': 9,
      'tenor_sax': 2,
      'clarinet_bb': 2,
      'french_horn': 7,
      'clarinet_a': 3,
      'flute': 5,
    };
    final fromOffset = offsets[from] ?? 0;
    final toOffset = offsets[to] ?? 0;
    final diff = toOffset - fromOffset;
    return ((inputIndex + diff) % 12 + 12) % 12;
  }

  String _getNote(int index) {
    if (notationOutput == 'latina_option') {
      return accidentalPreference == 'sharp_option' ? latinNotes[index] : latinNotesFlat[index];
    } else {
      return accidentalPreference == 'sharp_option' ? americanNotes[index] : americanNotesFlat[index];
    }
  }
}
