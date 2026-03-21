import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/dialog_helpers.dart';
import '../utils/localization_helper.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/export_helper.dart';
import 'OcrScreen.dart' show OcrScreen, isOcrSupported;

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
      return accidentalPreference == 'sharp_option'
          ? chromaticLatinaSharp
          : chromaticLatinaFlat;
    } else {
      return accidentalPreference == 'sharp_option'
          ? chromaticAmericanSharp
          : chromaticAmericanFlat;
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
      SnackBar(content: Text(AppLocalizations.of(context)!.copied_snackbar)),
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

    return AppScaffold(
      title: loc.button_digitalize_notes,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OCR Banner (mobile only)
            if (isOcrSupported) ...[
              _buildOcrBanner(loc),
              const SizedBox(height: 20),
            ],

            // Notation & accidental dropdowns
            buildStyledDropdown(
              value: notationType,
              label: loc.notation_type_label,
              items: ['latina_option', 'american_option'],
              translateFn: (key) => loc.getTranslation(key),
              onChanged: (val) => setState(() => notationType = val!),
            ),
            const SizedBox(height: 12),
            buildStyledDropdown(
              value: accidentalPreference,
              label: loc.accidental_preference_label,
              items: ['sharp_option', 'flat_option'],
              translateFn: (key) => loc.getTranslation(key),
              onChanged: (val) =>
                  setState(() => accidentalPreference = val!),
            ),
            const SizedBox(height: 20),

            // Preview
            buildSectionLabel(loc.digitized_notes_label),
            buildPreviewContainer(
              repaintKey: _previewContainerKey,
              text: display,
              placeholder: loc.empty_sequence_placeholder,
            ),
            const SizedBox(height: 20),

            // Note buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: notes
                  .map((note) => CustomButton(
                        text: note,
                        isSmall: true,
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
                        isSmall: true,
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
                    icon: Icons.backspace_outlined,
                    onPressed: _clearLast,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                    icon: Icons.ios_share_rounded,
                    onPressed: () async {
                      await showExportBottomSheet(
                        context: context,
                        pdfLabel: loc.export_pdf_option,
                        imageLabel: loc.export_image_option,
                        onExportPdf: () async {
                          Navigator.pop(context);
                          final title = await promptForPdfTitle(
                              context, loc.export_pdf_title_draft);
                          if (title != null && title.isNotEmpty) {
                            ExportHelper.exportAsPdf(
                              title: title,
                              content: display,
                              filename: 'notas_digitalizadas.pdf',
                            );
                          }
                        },
                        onExportImage: () {
                          Navigator.pop(context);
                          ExportHelper.exportAsImage(
                            context: context,
                            repaintKey: _previewContainerKey,
                            filename: 'notas_digitalizadas.png',
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

            const SizedBox(height: 32),
          ],
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
            SmoothPageRoute(
              page: OcrScreen(onImport: _importFromOcr),
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
}
