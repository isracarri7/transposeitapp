import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/dialog_helpers.dart';
import '../utils/localization_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/export_helper.dart';

class NoteSequenceScreen extends StatefulWidget {
  final String originInstrument;
  final String targetInstrument;
  final String notationInput;
  final String notationOutput;
  final String accidentalPreference;

  const NoteSequenceScreen({
    required this.originInstrument,
    required this.targetInstrument,
    required this.notationInput,
    required this.notationOutput,
    required this.accidentalPreference,
    super.key,
  });

  @override
  State<NoteSequenceScreen> createState() => _NoteSequenceScreenState();
}

class _NoteSequenceScreenState extends State<NoteSequenceScreen> {
  final List<String> latinNotes = ['Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'];
  final List<String> americanNotes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final List<String> latinNotesFlat = ['Do', 'Reb', 'Re', 'Mib', 'Mi', 'Fa', 'Solb', 'Sol', 'Lab', 'La', 'Sib', 'Si'];
  final List<String> americanNotesFlat = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  String normalizeSymbol(String input) {
    return input
        .replaceAll('–', '-')   // guion largo a guion normal
        .replaceAll('—', '-')   // em dash a guion normal
        .replaceAll('−', '-')   // signo menos matemático a guion
        .replaceAll('（', '(')  // paréntesis chino a normal
        .replaceAll('）', ')')  // paréntesis chino a normal
        .replaceAll('，', ',')  // coma china a normal
        .replaceAll('／', '/')  // slash japonés a normal
        .replaceAll('‘', '\'')  // comillas curvas a rectas
        .replaceAll('’', '\'')  // comillas curvas a rectas
        .replaceAll('“', '"')   // comillas curvas a rectas
        .replaceAll('”', '"');  // comillas curvas a rectas
  }

  List<String> sequence = [];
  String transposedResult = '';

  late List<String> inputNotes;
  late List<String> outputNotes;

  final GlobalKey _previewContainerKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    inputNotes = widget.notationInput == 'latina_option'
        ? (widget.accidentalPreference == 'sharp_option' ? latinNotes : latinNotesFlat)
        : (widget.accidentalPreference == 'sharp_option' ? americanNotes : americanNotesFlat);

    outputNotes = widget.notationOutput == 'latina_option'
        ? (widget.accidentalPreference == 'sharp_option' ? latinNotes : latinNotesFlat)
        : (widget.accidentalPreference == 'sharp_option' ? americanNotes : americanNotesFlat);
  }

  int getOffset() {
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
    final fromOffset = offsets[widget.originInstrument] ?? 0;
    final toOffset = offsets[widget.targetInstrument] ?? 0;
    return ((toOffset - fromOffset) % 12 + 12) % 12;
  }

  void _addLineBreak() {
    final current = _textController.text;
    final updated = '$current\n';
    setState(() {
      _textController.text = updated;
      _textController.selection = TextSelection.fromPosition(TextPosition(offset: updated.length));
      sequence = updated.split(RegExp(r'(\s+|\n)')).where((s) => s.trim().isNotEmpty).toList();
    });
  }
  void _clearLast() {
    if (sequence.isNotEmpty) {
      setState(() {
        sequence.removeLast();
        _textController.text = sequence.join(' ');
        _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
      });
    }
  }

  void _transpose() {
    final offset = getOffset();
    final transposed = sequence.map((note) {
      if (note == '\n') return '\n';

      final cleanNote = normalizeSymbol(note);
      final allowedSymbols = [',', '/', '-', '(', ')'];

      if (allowedSymbols.contains(cleanNote)) return cleanNote;

      final idx = inputNotes.indexWhere((n) => n.toLowerCase() == cleanNote.toLowerCase());
      if (idx == -1) return '?';

      final newIndex = (idx + offset) % 12;
      return outputNotes[newIndex];
    }).toList();

    setState(() {
      transposedResult = transposed
          .map((note) => [',', '/', '(', ')', '\n'].contains(note) ? note : '$note ')
          .join()
          .replaceAll('\n ', '\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              Text(loc.current_sequence_label, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: loc.empty_sequence_placeholder,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                style: const TextStyle(fontSize: 18),
                onChanged: (value) {
                  setState(() {
                    sequence = value
                        .split(RegExp(r'(?=[,\/\-\(\)\n])|(?<=[,\/\-\(\)\n])|\s+'))
                        .where((s) => s.trim().isNotEmpty)
                        .toList();
                  });
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: inputNotes.map((note) => CustomButton(
                  text: note,
                  onPressed: () {
                    final current = _textController.text.trimRight();
                    final updated = current.isEmpty ? note : '$current $note';
                    setState(() {
                      _textController.text = updated;
                      _textController.selection = TextSelection.fromPosition(TextPosition(offset: updated.length));
                      sequence = updated.split(RegExp(r'(\s+|\n)')).where((s) => s.trim().isNotEmpty).toList();
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [',', '/', '-', '(', ')'].map((symbol) => CustomButton(
                  text: symbol,
                  onPressed: () {
                    final current = _textController.text.trimRight();
                    final updated = current.isEmpty ? symbol : '$current $symbol';
                    setState(() {
                      _textController.text = updated;
                      _textController.selection = TextSelection.fromPosition(TextPosition(offset: updated.length));
                      sequence = updated.split(RegExp(r'(\s+|\n)')).where((s) => s.trim().isNotEmpty).toList();
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: CustomButton(icon: Icons.keyboard_return, text: loc.newline_button, onPressed: _addLineBreak)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomButton(icon: Icons.backspace, text: loc.clear_last_button, onPressed: _clearLast)),
                ],
              ),
              const SizedBox(height: 20),
              CustomButton(text: loc.transpose_button, onPressed: _transpose),
              const SizedBox(height: 20),
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
                    child: Text(transposedResult, style: const TextStyle(fontSize: 18, color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        icon: Icons.copy,
                        text: loc.copy_button,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: transposedResult));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.copied_snackbar)),
                          );
                        },
                      ),
                    ),
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
                                    final title = await promptForPdfTitle(context, loc.note_sequence_pdf_title);
                                    if (title != null && title.isNotEmpty) {
                                      ExportHelper.exportNoteSequenceAsPdf(
                                        title: title,
                                        originInstrument: loc.getTranslation(widget.originInstrument),
                                        targetInstrument: loc.getTranslation(widget.targetInstrument),
                                        notationInput: loc.getTranslation(widget.notationInput),
                                        notationOutput: loc.getTranslation(widget.notationOutput),
                                        accidentalPreference: loc.getTranslation(widget.accidentalPreference),
                                        content: transposedResult,
                                        filename: 'transposicion_notas.pdf',
                                        labelFrom: loc.pdf_label_from,
                                        labelTo: loc.pdf_label_to,
                                        labelNotation: loc.pdf_label_notation,
                                        labelAccidentals: loc.pdf_label_accidentals,
                                      );
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.image),
                                  title: Text(loc.export_image_option),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ExportHelper.exportAsImage(
                                      context: context,
                                      repaintKey: _previewContainerKey,
                                      filename: 'transposicion.png',
                                    );
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
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        sequence.clear();
                        transposedResult = '';
                        _textController.clear();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(loc.reset_all_button),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
