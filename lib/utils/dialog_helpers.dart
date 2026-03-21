import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<String?> promptForPdfTitle(BuildContext context, String defaultTitle) async {
  final loc = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: defaultTitle);

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(loc.pdf_title_prompt), // Traducción dinámica
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: loc.enter_pdf_title_hint), // Traducción dinámica
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel_button), // Traducción dinámica
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(loc.accept_button), // Traducción dinámica
          ),
        ],
      );
    },
  );
}
