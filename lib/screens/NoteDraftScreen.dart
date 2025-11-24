import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/dialog_helpers.dart';
import '../widgets/custom_button.dart';
import '../widgets/export_helper.dart';

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

  void _addNote(String note) {
    setState(() {
      sequence.add(note);
    });
  }

  void _addSymbol(String symbol) {
    setState(() {
      sequence.add(symbol);
    });
  }

  void _addLineBreak() {
    setState(() {
      sequence.add('\n');
    });
  }

  void _clearLast() {
    if (sequence.isNotEmpty) {
      setState(() {
        sequence.removeLast();
      });
    }
  }

  void _clearAll() {
    setState(() {
      sequence.clear();
    });
  }

  void _copyToClipboard() {
    final result = _getDisplayText();
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.copied_snackbar)),
    );
  }

  String _getDisplayText() {
    return sequence.map((e) => [',', '/', '-', '(', ')', '\n'].contains(e) ? e : '$e ').join().replaceAll('\n ', '\n');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final display = _getDisplayText();
    final List<String> notes = getAccidentals();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: notationType,
                decoration: InputDecoration(labelText: loc.notation_type_label),
                items: ['latina_option', 'american_option']
                    .map((key) => DropdownMenuItem(
                  value: key,
                  child: Text(loc.getTranslation(key)),
                ))
                    .toList(),
                onChanged: (val) => setState(() => notationType = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: accidentalPreference,
                decoration: InputDecoration(labelText: loc.accidental_preference_label),
                items: ['sharp_option', 'flat_option']
                    .map((key) => DropdownMenuItem(
                  value: key,
                  child: Text(loc.getTranslation(key)),
                ))
                    .toList(),
                onChanged: (val) => setState(() => accidentalPreference = val!),
              ),
              const SizedBox(height: 24),
              Text(loc.digitized_notes_label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RepaintBoundary(
                key: _previewContainerKey,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    display.isEmpty ? loc.empty_sequence_placeholder : display,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
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
                          builder: (_) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.picture_as_pdf),
                                title: Text(loc.export_pdf_option),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final title = await promptForPdfTitle(context, loc.export_pdf_title_draft);
                                  if (title != null && title.isNotEmpty) {
                                    ExportHelper.exportAsPdf(
                                      title: title,
                                      content: display,
                                      filename: 'notas_digitalizadas.pdf',
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
                                    filename: 'notas_digitalizadas.png',
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
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.refresh),
                  label: Text(loc.reset_all_button),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

extension LocalizationHelper on AppLocalizations {
  String getTranslation(String key) {
    switch (key) {
      case 'latina_option':
        return latina_option;
      case 'american_option':
        return american_option;
      case 'sharp_option':
        return sharp_option;
      case 'flat_option':
        return flat_option;
      default:
        return key;
    }
  }
}
