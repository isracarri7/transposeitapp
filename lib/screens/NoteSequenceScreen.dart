import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/dialog_helpers.dart';
import '../utils/localization_helper.dart';
import '../widgets/app_scaffold.dart';
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
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('−', '-')
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll('，', ',')
        .replaceAll('／', '/')
        .replaceAll('\u2018', '\'')
        .replaceAll('\u2019', '\'')
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"');
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
      _textController.selection =
          TextSelection.fromPosition(TextPosition(offset: updated.length));
      sequence = updated
          .split(RegExp(r'(\s+|\n)'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
    });
  }

  void _clearLast() {
    if (sequence.isNotEmpty) {
      setState(() {
        sequence.removeLast();
        _textController.text = sequence.join(' ');
        _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length));
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

      final idx = inputNotes
          .indexWhere((n) => n.toLowerCase() == cleanNote.toLowerCase());
      if (idx == -1) return '?';

      final newIndex = ((idx + offset) % 12 + 12) % 12;
      return outputNotes[newIndex];
    }).toList();

    setState(() {
      transposedResult = transposed
          .map((note) =>
              [',', '/', '(', ')', '\n'].contains(note) ? note : '$note ')
          .join()
          .replaceAll('\n ', '\n');
    });
  }

  void _appendToTextField(String value) {
    final current = _textController.text.trimRight();
    final updated = current.isEmpty ? value : '$current $value';
    setState(() {
      _textController.text = updated;
      _textController.selection =
          TextSelection.fromPosition(TextPosition(offset: updated.length));
      sequence = updated
          .split(RegExp(r'(\s+|\n)'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
    });
  }

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
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF132035),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  _buildInstrumentPill(
                      loc.getTranslation(widget.originInstrument)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward,
                        color: const Color(0xFFD4AF37).withOpacity(0.7),
                        size: 20),
                  ),
                  _buildInstrumentPill(
                      loc.getTranslation(widget.targetInstrument)),
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
                  sequence = value
                      .split(
                          RegExp(r'(?=[,\/\-\(\)\n])|(?<=[,\/\-\(\)\n])|\s+'))
                      .where((s) => s.trim().isNotEmpty)
                      .toList();
                });
              },
            ),

            const SizedBox(height: 16),

            // Note buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: inputNotes
                  .map((note) => CustomButton(
                        text: note,
                        isSmall: true,
                        onPressed: () => _appendToTextField(note),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Symbol buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [',', '/', '-', '(', ')']
                  .map((symbol) => CustomButton(
                        text: symbol,
                        isSmall: true,
                        onPressed: () => _appendToTextField(symbol),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // Control row
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    icon: Icons.keyboard_return,
                    text: loc.newline_button,
                    onPressed: _addLineBreak,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    icon: Icons.backspace_outlined,
                    text: loc.clear_last_button,
                    onPressed: _clearLast,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Transpose button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: loc.transpose_button,
                isPrimary: true,
                icon: Icons.swap_horiz_rounded,
                onPressed: _transpose,
              ),
            ),

            const SizedBox(height: 24),

            // Result
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
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: transposedResult));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.copied_snackbar)),
                        );
                      },
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
                                context, loc.note_sequence_pdf_title);
                            if (title != null && title.isNotEmpty) {
                              ExportHelper.exportNoteSequenceAsPdf(
                                title: title,
                                originInstrument: loc.getTranslation(
                                    widget.originInstrument),
                                targetInstrument: loc.getTranslation(
                                    widget.targetInstrument),
                                notationInput:
                                    loc.getTranslation(widget.notationInput),
                                notationOutput:
                                    loc.getTranslation(widget.notationOutput),
                                accidentalPreference: loc.getTranslation(
                                    widget.accidentalPreference),
                                content: transposedResult,
                                filename: 'transposicion_notas.pdf',
                                labelFrom: loc.pdf_label_from,
                                labelTo: loc.pdf_label_to,
                                labelNotation: loc.pdf_label_notation,
                                labelAccidentals: loc.pdf_label_accidentals,
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
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      sequence.clear();
                      transposedResult = '';
                      _textController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
                  label: Text(loc.reset_all_button,
                      style: const TextStyle(color: Color(0xFFD4AF37))),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentPill(String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2C42),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
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
}
