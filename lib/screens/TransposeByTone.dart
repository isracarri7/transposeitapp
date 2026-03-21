import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/dialog_helpers.dart';
import '../utils/localization_helper.dart';
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

  final List<String> complexityLabels = ['complexity_simple', 'complexity_chords', 'complexity_advanced'];

  final List<String> complexSuffixes = [
    '','m','7', 'm7', 'maj7', 'mM7', '6', 'm6', '6/9', '5', '9', 'm9', 'maj9', '11', 'm11', 'maj11',
    '13', 'm13', 'maj13', 'add', '7-5', '7+5', 'sus', 'dim', 'dim7', 'm7b5', 'aug', 'aug7'
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

  List<String> buildRootNoteDropdownItems() {
    return getRootNotes();
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
    final sortedScale = [...scale]..sort((a, b) => b.length.compareTo(a.length));
    for (var note in sortedScale) {
      if (chord.startsWith(note)) {
        final originalIndex = scale.indexOf(note);
        final newIndex = (originalIndex + semitoneShift) % 12;
        final newNote = scale[newIndex < 0 ? newIndex + 12 : newIndex];
        return chord.replaceFirst(note, newNote);
      }
    }
    return chord;
  }

  void transposeSequence() {
    final scale = getChromaticScale();
    final transposed = inputSequence.map((chord) => chord == '\n' ? '\n' : transposeChord(chord, scale)).toList();
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              DropdownButtonFormField<String>(
                value: notationType,
                decoration: InputDecoration(labelText: loc.notation_type_label),
                items: ['latina_option', 'american_option'].map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Text(loc.getTranslation(key)),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  notationType = value!;
                  selectedRootNote = '';
                }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: accidentalPreference,
                decoration: InputDecoration(labelText: loc.accidental_preference_label),
                items: ['sharp_option', 'flat_option'].map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Text(loc.getTranslation(key)),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  accidentalPreference = value!;
                  selectedRootNote = '';
                }),
              ),
              const SizedBox(height: 16),
              Text(loc.chord_complexity_label),
              const SizedBox(height: 8),
              ToggleButtons(
                isSelected: List.generate(3, (i) => complexityLevel == i),
                onPressed: (index) => setState(() {
                  complexityLevel = index;
                  if (index != 2) selectedRootNote = '';
                }),
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: Theme.of(context).colorScheme.primary,
                color: Theme.of(context).colorScheme.primary,
                children: complexityLabels.map((key) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(loc.getTranslation(key)),
                )).toList(),
              ),
              if (complexityLevel == 2) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRootNote.isNotEmpty ? selectedRootNote : null,
                  decoration: InputDecoration(labelText: loc.select_root_note_label),
                  items: buildRootNoteDropdownItems().map((note) => DropdownMenuItem(value: note, child: Text(note))).toList(),
                  onChanged: (value) => setState(() => selectedRootNote = value!),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.semitones_label),
                  Row(
                    children: [
                      IconButton(onPressed: () => setState(() => semitoneShift--), icon: const Icon(Icons.remove)),
                      Text('$semitoneShift'),
                      IconButton(onPressed: () => setState(() => semitoneShift++), icon: const Icon(Icons.add)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(loc.current_sequence_label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: loc.empty_sequence_placeholder,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    inputSequence = value.split(RegExp(r'(\s+|\n)')).where((s) => s.trim().isNotEmpty).toList();
                  });
                },
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: getDisplayedButtons().map((note) => CustomButton(
                  text: note,
                  onPressed: () {
                    final currentText = _textController.text.trimRight();
                    final updated = currentText.isEmpty ? note : '$currentText $note';
                    setState(() {
                      _textController.text = updated;
                      _textController.selection = TextSelection.fromPosition(TextPosition(offset: updated.length));
                      inputSequence = updated.split(RegExp(r'(\s+|\n)')).where((s) => s.trim().isNotEmpty).toList();
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: CustomButton(
                    icon: Icons.keyboard_return,
                    text: loc.newline_button,
                    onPressed: () {
                      final currentText = _textController.text;
                      final updated = '$currentText\n';
                      setState(() {
                        _textController.text = updated;
                        _textController.selection = TextSelection.fromPosition(TextPosition(offset: updated.length));
                        inputSequence = updated.split(RegExp(r'(\s+|\n)')).where((s) => s.trim().isNotEmpty).toList();
                      });
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: CustomButton(text: loc.transpose_button, onPressed: transposeSequence)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: CustomButton(icon: Icons.backspace, text: loc.clear_last_button, onPressed: clearLast)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomButton(icon: Icons.refresh, text: loc.reset_button, onPressed: clearAll)),
                ],
              ),
              const SizedBox(height: 24),
              if (transposedResult.isNotEmpty) ...[
                Text(loc.transposed_result_label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RepaintBoundary(
                  key: _previewContainerKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(transposedResult, style: const TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: CustomButton(icon: Icons.copy, text: loc.copy_button, onPressed: copyToClipboard)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        icon: Icons.share,
                        text: loc.export_button,
                        onPressed: () async {
                          await showModalBottomSheet(
                            context: context,
                            builder: (_) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.picture_as_pdf),
                                  title: Text(loc.export_pdf_option),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final title = await promptForPdfTitle(context, loc.export_pdf_title);
                                    if (title != null && title.isNotEmpty) {
                                      ExportHelper.exportAsPdf(title: title, content: transposedResult, filename: 'transposicion.pdf');
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.image),
                                  title: Text(loc.export_image_option),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ExportHelper.exportAsImage(context: context, repaintKey: _previewContainerKey, filename: 'transposicion.png');
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

