import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/dialog_helpers.dart';
import '../utils/localization_helper.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/export_helper.dart';

class TransposeByToneScreen extends StatefulWidget {
  const TransposeByToneScreen({super.key});

  @override
  State<TransposeByToneScreen> createState() => _TransposeByToneScreenState();
}

class _TransposeByToneScreenState extends State<TransposeByToneScreen> {
  String notationType = 'latina_option';
  String accidentalPreference = 'sharp_option';
  int semitoneShift = 0;
  int complexityLevel = 0;
  String selectedRootNote = '';

  final GlobalKey _previewContainerKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();

  final List<String> complexityLabels = [
    'complexity_simple',
    'complexity_chords',
    'complexity_advanced',
  ];

  final List<String> complexSuffixes = [
    '', 'm', '7', 'm7', 'maj7', 'mM7', '6', 'm6', '6/9', '5', '9', 'm9',
    'maj9', '11', 'm11', 'maj11', '13', 'm13', 'maj13', 'add', '7-5', '7+5',
    'sus', 'dim', 'dim7', 'm7b5', 'aug', 'aug7',
  ];

  final List<String> chromaticLatinaSharp = ['Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'];
  final List<String> chromaticLatinaFlat = ['Do', 'Reb', 'Re', 'Mib', 'Mi', 'Fa', 'Solb', 'Sol', 'Lab', 'La', 'Sib', 'Si'];
  final List<String> chromaticAmericanSharp = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final List<String> chromaticAmericanFlat = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  late Map<String, List<String>> complexChordsMapLatina;
  late Map<String, List<String>> complexChordsMapAmerican;
  List<String> inputSequence = [];
  String transposedResult = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    complexChordsMapLatina = _buildChordMap(chromaticLatinaSharp + chromaticLatinaFlat);
    complexChordsMapAmerican = _buildChordMap(chromaticAmericanSharp + chromaticAmericanFlat);
  }

  Map<String, List<String>> _buildChordMap(List<String> rootNotes) {
    final Map<String, List<String>> chordMap = {};
    for (final root in rootNotes.toSet()) {
      chordMap[root] = complexSuffixes.map((suffix) => '$root$suffix').toList();
    }
    return chordMap;
  }

  List<String> getRootNotes() {
    if (notationType == 'latina_option') {
      return accidentalPreference == 'sharp_option' ? chromaticLatinaSharp : chromaticLatinaFlat;
    } else {
      return accidentalPreference == 'sharp_option' ? chromaticAmericanSharp : chromaticAmericanFlat;
    }
  }

  List<String> getDisplayedButtons() {
    if (complexityLevel == 0) {
      return getRootNotes();
    } else if (complexityLevel == 1) {
      return getRootNotes().expand((note) => [note, '${note}m']).toList();
    } else if (complexityLevel == 2 && selectedRootNote.isNotEmpty) {
      final map = notationType == 'latina_option' ? complexChordsMapLatina : complexChordsMapAmerican;
      return map[selectedRootNote] ?? [];
    }
    return [];
  }

  List<String> getChromaticScale() {
    if (notationType == 'latina_option') {
      return accidentalPreference == 'sharp_option' ? chromaticLatinaSharp : chromaticLatinaFlat;
    } else {
      return accidentalPreference == 'sharp_option' ? chromaticAmericanSharp : chromaticAmericanFlat;
    }
  }

  String transposeChord(String chord, List<String> scale) {
    // Strip non-letter prefix (e.g. "//G" → prefix="//" body="G")
    int prefixEnd = 0;
    while (prefixEnd < chord.length &&
        !RegExp(r'[a-zA-Z]').hasMatch(chord[prefixEnd])) {
      prefixEnd++;
    }
    if (prefixEnd == chord.length) return chord; // no musical content

    final prefix = chord.substring(0, prefixEnd);
    final body = chord.substring(prefixEnd);

    final sortedScale = [...scale]..sort((a, b) => b.length.compareTo(a.length));
    for (var note in sortedScale) {
      if (body.startsWith(note)) {
        final originalIndex = scale.indexOf(note);
        final newIndex = ((originalIndex + semitoneShift) % 12 + 12) % 12;
        return prefix + body.replaceFirst(note, scale[newIndex]);
      }
    }
    return chord;
  }

  void transposeSequence() {
    final scale = getChromaticScale();
    final transposed = inputSequence
        .map((chord) => chord == '\n' ? '\n' : transposeChord(chord, scale))
        .toList();
    setState(() {
      transposedResult = transposed.join(' ').replaceAll('\n ', '\n');
    });
  }

  void clearAll() {
    setState(() {
      inputSequence.clear();
      transposedResult = '';
      _textController.clear();
    });
  }

  void clearLast() {
    if (inputSequence.isNotEmpty) {
      setState(() {
        inputSequence.removeLast();
        _textController.text = inputSequence.join(' ');
      });
    }
  }

  void copyToClipboard() {
    Clipboard.setData(ClipboardData(text: transposedResult));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.copied_snackbar)),
    );
  }

  void _appendToTextField(String value) {
    final currentText = _textController.text.trimRight();
    final updated = currentText.isEmpty ? value : '$currentText $value';
    setState(() {
      _textController.text = updated;
      _textController.selection =
          TextSelection.fromPosition(TextPosition(offset: updated.length));
      inputSequence = updated
          .split(RegExp(r'(\s+|\n)'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AppScaffold(
      title: loc.button_transpose_by_tone,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notation dropdown
            buildStyledDropdown(
              value: notationType,
              label: loc.notation_type_label,
              items: ['latina_option', 'american_option'],
              translateFn: (key) => loc.getTranslation(key),
              onChanged: (value) => setState(() {
                notationType = value!;
                selectedRootNote = '';
              }),
            ),
            const SizedBox(height: 12),

            // Accidental dropdown
            buildStyledDropdown(
              value: accidentalPreference,
              label: loc.accidental_preference_label,
              items: ['sharp_option', 'flat_option'],
              translateFn: (key) => loc.getTranslation(key),
              onChanged: (value) => setState(() {
                accidentalPreference = value!;
                selectedRootNote = '';
              }),
            ),
            const SizedBox(height: 20),

            // Chord complexity
            buildSectionLabel(loc.chord_complexity_label),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF132035),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: List.generate(3, (i) {
                  final isSelected = complexityLevel == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          complexityLevel = i;
                          if (i != 2) selectedRootNote = '';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFD4AF37)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          loc.getTranslation(complexityLabels[i]),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF0A1628)
                                : Colors.white54,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Root note for advanced mode
            if (complexityLevel == 2) ...[
              const SizedBox(height: 12),
              buildStyledDropdown(
                value: selectedRootNote.isNotEmpty ? selectedRootNote : getRootNotes().first,
                label: loc.select_root_note_label,
                items: getRootNotes(),
                translateFn: (key) => key,
                onChanged: (value) => setState(() => selectedRootNote = value!),
              ),
            ],

            const SizedBox(height: 20),

            // Semitone shift
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF132035),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.semitones_label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  Row(
                    children: [
                      _buildSemitoneBtn(Icons.remove, () => setState(() => semitoneShift--)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$semitoneShift',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD4AF37),
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ),
                      _buildSemitoneBtn(Icons.add, () => setState(() => semitoneShift++)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Text input
            buildSectionLabel(loc.current_sequence_label),
            TextField(
              controller: _textController,
              maxLines: null,
              minLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: loc.empty_sequence_placeholder,
                filled: true,
                fillColor: const Color(0xFF0D1828),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  inputSequence = value
                      .split(RegExp(r'(\s+|\n)'))
                      .where((s) => s.trim().isNotEmpty)
                      .toList();
                });
              },
            ),

            const SizedBox(height: 16),

            // Note/chord buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: getDisplayedButtons()
                  .map((note) => CustomButton(
                        text: note,
                        isSmall: true,
                        onPressed: () => _appendToTextField(note),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // Action row
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    icon: Icons.keyboard_return,
                    text: loc.newline_button,
                    onPressed: () {
                      final current = _textController.text;
                      final updated = '$current\n';
                      setState(() {
                        _textController.text = updated;
                        _textController.selection = TextSelection.fromPosition(
                            TextPosition(offset: updated.length));
                        inputSequence = updated
                            .split(RegExp(r'(\s+|\n)'))
                            .where((s) => s.trim().isNotEmpty)
                            .toList();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: loc.transpose_button,
                    isPrimary: true,
                    onPressed: transposeSequence,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    icon: Icons.backspace_outlined,
                    text: loc.clear_last_button,
                    onPressed: clearLast,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    icon: Icons.refresh,
                    text: loc.reset_button,
                    onPressed: clearAll,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Transposed result
            if (transposedResult.isNotEmpty) ...[
              buildSectionLabel(loc.transposed_result_label),
              buildPreviewContainer(
                repaintKey: _previewContainerKey,
                text: transposedResult,
                placeholder: loc.empty_sequence_placeholder,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      icon: Icons.copy,
                      text: loc.copy_button,
                      onPressed: copyToClipboard,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      icon: Icons.ios_share_rounded,
                      text: loc.export_button,
                      onPressed: () async {
                        await showExportBottomSheet(
                          context: context,
                          pdfLabel: loc.export_pdf_option,
                          imageLabel: loc.export_image_option,
                          onExportPdf: () async {
                            Navigator.pop(context);
                            final title = await promptForPdfTitle(
                                context, loc.export_pdf_title);
                            if (title != null && title.isNotEmpty) {
                              ExportHelper.exportAsPdf(
                                title: title,
                                content: transposedResult,
                                filename: 'transposicion.pdf',
                              );
                            }
                          },
                          onExportImage: () {
                            Navigator.pop(context);
                            ExportHelper.exportAsImage(
                              context: context,
                              repaintKey: _previewContainerKey,
                              filename: 'transposicion.png',
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSemitoneBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFFD4AF37).withOpacity(0.15),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2C42),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.2),
            ),
          ),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
        ),
      ),
    );
  }
}
