import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/dialog_helpers.dart';
import '../utils/localization_helper.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/export_helper.dart';

class NotationConverterScreen extends StatefulWidget {
  const NotationConverterScreen({super.key});

  @override
  State<NotationConverterScreen> createState() =>
      _NotationConverterScreenState();
}

class _NotationConverterScreenState extends State<NotationConverterScreen> {
  // true = Latin→American, false = American→Latin
  bool _latinToAmerican = true;
  String _accidentalPreference = 'sharp_option';
  bool _useNoteKeyboard = true;

  final TextEditingController _inputController = TextEditingController();
  final GlobalKey _previewContainerKey = GlobalKey();
  String _convertedResult = '';

  final List<String> _latinSharp = [
    'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'
  ];
  final List<String> _latinFlat = [
    'Do', 'Reb', 'Re', 'Mib', 'Mi', 'Fa', 'Solb', 'Sol', 'Lab', 'La', 'Sib', 'Si'
  ];
  final List<String> _americanSharp = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];
  final List<String> _americanFlat = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  List<String> get _sourceScale {
    if (_latinToAmerican) {
      return _accidentalPreference == 'sharp_option' ? _latinSharp : _latinFlat;
    } else {
      return _accidentalPreference == 'sharp_option'
          ? _americanSharp
          : _americanFlat;
    }
  }

  List<String> get _keyboardNotes => _sourceScale;

  String _convertToken(String token) {
    if (token == '\n') return '\n';

    // Strip non-letter prefix
    int prefixEnd = 0;
    while (prefixEnd < token.length &&
        !RegExp(r'[a-zA-Z]').hasMatch(token[prefixEnd])) {
      prefixEnd++;
    }
    if (prefixEnd == token.length) return token;

    final prefix = token.substring(0, prefixEnd);
    final body = token.substring(prefixEnd);

    // Build combined lookup: sharp + flat source scales
    final allSource = _latinToAmerican
        ? [..._latinSharp, ..._latinFlat]
        : [..._americanSharp, ..._americanFlat];
    final allTarget = _latinToAmerican
        ? [..._americanSharp, ..._americanFlat]
        : [..._latinSharp, ..._latinFlat];

    // Sort by length descending so "Sol#" matches before "Sol"
    final indices = List.generate(allSource.length, (i) => i);
    indices.sort((a, b) => allSource[b].length.compareTo(allSource[a].length));

    for (final i in indices) {
      if (body.startsWith(allSource[i])) {
        final suffix = body.substring(allSource[i].length);
        return prefix + allTarget[i] + suffix;
      }
    }
    return token;
  }

  void _convert() {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;

    // Split preserving structure
    final tokens = text
        .split(RegExp(r'(\s+|\n)'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final converted = tokens.map(_convertToken).toList();

    setState(() {
      _convertedResult = converted.join(' ');
    });
  }

  void _appendNote(String note) {
    final current = _inputController.text.trimRight();
    final updated = current.isEmpty ? note : '$current $note';
    setState(() {
      _inputController.text = updated;
      _inputController.selection =
          TextSelection.fromPosition(TextPosition(offset: updated.length));
    });
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _convertedResult = '';
    });
  }

  void _copyResult() {
    if (_convertedResult.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _convertedResult));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.copied_snackbar)),
    );
  }

  void _swapDirection() {
    setState(() {
      _latinToAmerican = !_latinToAmerican;
      _convertedResult = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final fromLabel =
        _latinToAmerican ? loc.latina_option : loc.american_option;
    final toLabel =
        _latinToAmerican ? loc.american_option : loc.latina_option;

    return AppScaffold(
      title: loc.button_convert_notation,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Direction card with swap
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF132035),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  _buildDirectionPill(fromLabel),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _swapDirection();
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_horiz_rounded,
                              color: Color(0xFFD4AF37), size: 20),
                        ),
                      ),
                    ),
                  ),
                  _buildDirectionPill(toLabel),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Accidental preference
            buildStyledDropdown(
              value: _accidentalPreference,
              label: loc.accidental_preference_label,
              items: ['sharp_option', 'flat_option'],
              translateFn: (key) =>
                  loc.getTranslation(key),
              onChanged: (val) => setState(() {
                _accidentalPreference = val!;
                _convertedResult = '';
              }),
            ),
            const SizedBox(height: 16),

            // Input mode toggle
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF132035),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  _buildToggleOption(
                    icon: Icons.piano,
                    label: loc.input_mode_keyboard,
                    isSelected: _useNoteKeyboard,
                    onTap: () => setState(() => _useNoteKeyboard = true),
                  ),
                  _buildToggleOption(
                    icon: Icons.keyboard_rounded,
                    label: loc.input_mode_text,
                    isSelected: !_useNoteKeyboard,
                    onTap: () => setState(() => _useNoteKeyboard = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Text input field
            buildSectionLabel(loc.converter_input_label),
            TextField(
              controller: _inputController,
              maxLines: null,
              minLines: 2,
              readOnly: _useNoteKeyboard,
              showCursor: !_useNoteKeyboard,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: loc.converter_input_hint,
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
                suffixIcon: _inputController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: Colors.white.withOpacity(0.3), size: 20),
                        onPressed: () {
                          setState(() {
                            _inputController.clear();
                            _convertedResult = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),

            // Paste button (always visible in text mode)
            if (!_useNoteKeyboard) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      final current = _inputController.text;
                      final updated = current.isEmpty
                          ? data.text!
                          : '$current ${data.text!}';
                      setState(() {
                        _inputController.text = updated;
                        _inputController.selection =
                            TextSelection.fromPosition(
                                TextPosition(offset: updated.length));
                      });
                    }
                  },
                  icon: const Icon(Icons.paste_rounded,
                      color: Color(0xFFD4AF37), size: 18),
                  label: Text(loc.converter_paste_button,
                      style: const TextStyle(
                          color: Color(0xFFD4AF37), fontSize: 13)),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Note keyboard (when enabled)
            if (_useNoteKeyboard) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _keyboardNotes
                    .map((note) => CustomButton(
                          text: note,
                          isSmall: true,
                          onPressed: () => _appendNote(note),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Symbol buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [',', '/', '-', '(', ')']
                    .map((sym) => CustomButton(
                          text: sym,
                          isSmall: true,
                          onPressed: () => _appendNote(sym),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      icon: Icons.keyboard_return,
                      text: loc.newline_button,
                      onPressed: () {
                        final current = _inputController.text;
                        final updated = '$current\n';
                        setState(() {
                          _inputController.text = updated;
                          _inputController.selection =
                              TextSelection.fromPosition(
                                  TextPosition(offset: updated.length));
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      icon: Icons.backspace_outlined,
                      text: loc.clear_last_button,
                      onPressed: () {
                        final text = _inputController.text.trimRight();
                        if (text.isEmpty) return;
                        final lastSpace = text.lastIndexOf(' ');
                        final updated =
                            lastSpace == -1 ? '' : text.substring(0, lastSpace);
                        setState(() {
                          _inputController.text = updated;
                          _inputController.selection =
                              TextSelection.fromPosition(
                                  TextPosition(offset: updated.length));
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Convert button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: loc.converter_convert_button,
                isPrimary: true,
                icon: Icons.translate_rounded,
                onPressed: _convert,
              ),
            ),

            const SizedBox(height: 24),

            // Result
            if (_convertedResult.isNotEmpty) ...[
              buildSectionLabel(loc.converter_result_label),
              buildPreviewContainer(
                repaintKey: _previewContainerKey,
                text: _convertedResult,
                placeholder: loc.empty_sequence_placeholder,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      icon: Icons.copy,
                      text: loc.copy_button,
                      onPressed: _copyResult,
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
                                context, loc.converter_pdf_title);
                            if (title != null && title.isNotEmpty) {
                              ExportHelper.exportAsPdf(
                                title: title,
                                content: _convertedResult,
                                filename: 'conversion_notacion.pdf',
                              );
                            }
                          },
                          onExportImage: () {
                            Navigator.pop(context);
                            ExportHelper.exportAsImage(
                              context: context,
                              repaintKey: _previewContainerKey,
                              filename: 'conversion_notacion.png',
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _clearAll,
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

  Widget _buildDirectionPill(String label) {
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Urbanist',
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF0A1628) : Colors.white54,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF0A1628)
                        : Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Urbanist',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
