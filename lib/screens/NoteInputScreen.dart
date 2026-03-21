import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/localization_helper.dart';
import '../widgets/app_scaffold.dart';


class NoteInputScreen extends StatelessWidget {
  final String originInstrument;
  final String targetInstrument;
  final String notationInput;
  final String notationOutput;
  final String accidentalPreference;

  const NoteInputScreen({
    required this.originInstrument,
    required this.targetInstrument,
    required this.notationInput,
    required this.notationOutput,
    required this.accidentalPreference,
    super.key,
  });

  final List<String> latinNotes = const ['Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'];
  final List<String> americanNotes = const ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final List<String> latinNotesFlat = const ['Do', 'Reb', 'Re', 'Mib', 'Mi', 'Fa', 'Solb', 'Sol', 'Lab', 'La', 'Sib', 'Si'];
  final List<String> americanNotesFlat = const ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final notes = notationInput == 'latina_option'
        ? (accidentalPreference == 'sharp_option' ? latinNotes : latinNotesFlat)
        : (accidentalPreference == 'sharp_option' ? americanNotes : americanNotesFlat);

    return AppScaffold(
      title: loc.select_note_title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF132035),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  _buildInstrumentPill(loc.getTranslation(originInstrument)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward,
                          color: Color(0xFFD4AF37), size: 16),
                    ),
                  ),
                  _buildInstrumentPill(loc.getTranslation(targetInstrument)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Instructions
            Text(
              loc.select_note_title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Urbanist',
              ),
            ),
            const SizedBox(height: 16),

            // Note buttons — grid layout
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final isSharpFlat = note.contains('#') || note.contains('b') && note.length > 1;
                return _NoteButton(
                  note: note,
                  isAccidental: isSharpFlat,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final idx = notes.indexOf(note);
                    final transposedIndex =
                        _transpose(idx, originInstrument, targetInstrument);
                    final transposedNote = _getNote(transposedIndex);
                    _showResultDialog(context, loc, note, transposedNote);
                  },
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(BuildContext context, AppLocalizations loc,
      String original, String transposed) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.result_dialog_title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Urbanist',
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildResultNoteChip(original, false),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFFD4AF37), size: 22),
                  ),
                ),
                _buildResultNoteChip(transposed, true),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0A1628),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Urbanist',
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultNoteChip(String note, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: isPrimary
            ? const Color(0xFFD4AF37).withOpacity(0.12)
            : const Color(0xFF1A2C42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary
              ? const Color(0xFFD4AF37).withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
          width: isPrimary ? 1.5 : 1,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Text(
        note,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: isPrimary ? const Color(0xFFD4AF37) : Colors.white,
          fontFamily: 'Urbanist',
        ),
      ),
    );
  }

  Widget _buildInstrumentPill(String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2C42),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.15),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Urbanist',
          ),
          overflow: TextOverflow.ellipsis,
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
      return accidentalPreference == 'sharp_option'
          ? latinNotes[index]
          : latinNotesFlat[index];
    } else {
      return accidentalPreference == 'sharp_option'
          ? americanNotes[index]
          : americanNotesFlat[index];
    }
  }
}

class _NoteButton extends StatelessWidget {
  final String note;
  final bool isAccidental;
  final VoidCallback onTap;

  const _NoteButton({
    required this.note,
    required this.onTap,
    this.isAccidental = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: const Color(0xFFD4AF37).withOpacity(0.15),
        highlightColor: const Color(0xFFD4AF37).withOpacity(0.08),
        child: Container(
          decoration: BoxDecoration(
            color: isAccidental
                ? const Color(0xFF0F1E35)
                : const Color(0xFF1A2C42),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAccidental
                  ? const Color(0xFFD4AF37).withOpacity(0.25)
                  : const Color(0xFFD4AF37).withOpacity(0.1),
            ),
          ),
          child: Center(
            child: Text(
              note,
              style: TextStyle(
                color: isAccidental
                    ? const Color(0xFFD4AF37)
                    : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Urbanist',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
