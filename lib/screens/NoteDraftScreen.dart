import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/dialog_helpers.dart';
import '../utils/localization_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/export_helper.dart';
import 'OcrScreen.dart';

class NoteDraftScreen extends StatefulWidget {
  const NoteDraftScreen({super.key});

  @override
  State<NoteDraftScreen> createState() => _NoteDraftScreenState();
}

class _NoteDraftScreenState extends State<NoteDraftScreen> {
  String notationType = 'latina_option';
  String accidentalPreference = 'sharp_option';

  final List<String> chromaticLatinaSharp = ['Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'];
  final List<String> chromaticLatinaFlat = ['Do', 'Reb', 'Re', 'Mib', 'Mi', 'Fa', 'Solb', 'Sol', 'Lab', 'La', 'Sib', 'Si'];
  final List<String> chromaticAmericanSharp = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final List<String> chromaticAmericanFlat = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  List<String> sequence = [];
  final GlobalKey _previewContainerKey = GlobalKey();

  List<String> getAccidentals() {
    if (notationType == 'latina_option') {
      return accidentalPreference == 'sharp_option' ? chromaticLatinaSharp : chromaticLatinaFlat;
    } else {
      return accidentalPreference == 'sharp_option' ? chromaticAmericanSharp : chromaticAmericanFlat;
    }
  }

  void _addNote(String note) => setState(() => sequence.add(note));
  void _addSymbol(String symbol) => setState(() => sequence.add(symbol));
  void _addLineBreak() => setState(() => sequence.add('\n'));

  void _clearLast() {
    if (sequence.isNotEmpty) {
      setState(() => sequence.removeLast());
    }
  }

  void _clearAll() => setState(() => sequence.clear());

  void _copyToClipboard() {
    final result = _getDisplayText();
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.copied_snackbar),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getDisplayText() {
    return sequence
        .map((e) => [',', '/', '-', '(', ')', '\n'].contains(e) ? e : '$e ')
        .join()
        .replaceAll('\n ', '\n');
  }

  void _importFromOcr(String text) {
    setState(() {
      // Split OCR text into individual tokens and add to sequence
      final tokens = text
          .split(RegExp(r'\s+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      sequence.addAll(tokens);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final display = _getDisplayText();
    final List<String> notes = getAccidentals();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF122640), Color(0xFF1A3555)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.button_digitalize_notes,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // OCR Banner
                      _buildOcrBanner(loc),
                      const SizedBox(height: 20),

                      // Notation & accidental dropdowns
                      _buildDropdown(
                        value: notationType,
                        label: loc.notation_type_label,
                        items: ['latina_option', 'american_option'],
                        loc: loc,
                        onChanged: (val) => setState(() => notationType = val!),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        value: accidentalPreference,
                        label: loc.accidental_preference_label,
                        items: ['sharp_option', 'flat_option'],
                        loc: loc,
                        onChanged: (val) =>
                            setState(() => accidentalPreference = val!),
                      ),
                      const SizedBox(height: 20),

                      // Preview
                      Text(
                        loc.digitized_notes_label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RepaintBoundary(
                        key: _previewContainerKey,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 60),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            display.isEmpty
                                ? loc.empty_sequence_placeholder
                                : display,
                            style: TextStyle(
                              fontSize: 16,
                              color: display.isEmpty
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Note buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: notes
                            .map((note) => CustomButton(
                                  text: note,
                                  onPressed: () => _addNote(note),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),

                      // Symbol buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [',', '/', '-', '(', ')']
                            .map((sym) => CustomButton(
                                  text: sym,
                                  onPressed: () => _addSymbol(sym),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),

                      // Control buttons
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: loc.newline_button,
                              icon: Icons.keyboard_return,
                              onPressed: _addLineBreak,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: loc.clear_last_button,
                              icon: Icons.backspace,
                              onPressed: _clearLast,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Export buttons
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: loc.copy_text_button,
                              icon: Icons.copy,
                              onPressed: _copyToClipboard,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: loc.export_button,
                              icon: Icons.share,
                              onPressed: () async {
                                await showModalBottomSheet(
                                  context: context,
                                  backgroundColor: const Color(0xFF132035),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                  ),
                                  builder: (_) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      ListTile(
                                        leading: const Icon(
                                            Icons.picture_as_pdf,
                                            color: Color(0xFFD4AF37)),
                                        title: Text(loc.export_pdf_option,
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          final title =
                                              await promptForPdfTitle(
                                                  context,
                                                  loc.export_pdf_title_draft);
                                          if (title != null &&
                                              title.isNotEmpty) {
                                            ExportHelper.exportAsPdf(
                                              title: title,
                                              content: display,
                                              filename:
                                                  'notas_digitalizadas.pdf',
                                            );
                                          }
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.image,
                                            color: Color(0xFFD4AF37)),
                                        title: Text(loc.export_image_option,
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          ExportHelper.exportAsImage(
                                            context: context,
                                            repaintKey: _previewContainerKey,
                                            filename:
                                                'notas_digitalizadas.png',
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
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
                          icon: const Icon(Icons.refresh,
                              color: Color(0xFFD4AF37)),
                          label: Text(loc.reset_all_button,
                              style:
                                  const TextStyle(color: Color(0xFFD4AF37))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOcrBanner(AppLocalizations loc) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OcrScreen(onImport: _importFromOcr),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withOpacity(0.15),
                const Color(0xFFD4AF37).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.document_scanner,
                    color: Color(0xFFD4AF37), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.ocr_banner_title,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.ocr_banner_subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required AppLocalizations loc,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF132035),
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
      dropdownColor: const Color(0xFF132035),
      style: const TextStyle(color: Colors.white),
      items: items
          .map((key) => DropdownMenuItem(
                value: key,
                child: Text(loc.getTranslation(key)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
