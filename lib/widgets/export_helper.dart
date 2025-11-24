import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExportHelper {
  /// Exporta el contenido de un widget como imagen PNG usando un RepaintBoundary
  static Future<void> exportAsImage({
    required BuildContext context,
    required GlobalKey repaintKey,
    required String filename,
  }) async {
    final loc = AppLocalizations.of(context)!;

    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.image_export_widget_error)),
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await Printing.sharePdf(bytes: pngBytes, filename: filename);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.image_export_error}: $e')),
      );
    }
  }

  /// Exporta texto como PDF, útil para mostrar secuencias de notas o acordes
  static Future<void> exportAsPdf({
    required String title,
    required String content,
    required String filename,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text(content),
            ],
          ),
        ),
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  static Future<void> exportNoteSequenceAsPdf({
    required String originInstrument,
    required String targetInstrument,
    required String notationInput,
    required String notationOutput,
    required String accidentalPreference,
    required String content,
    required String filename,
    required String title,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text("De: $originInstrument", style: const pw.TextStyle(fontSize: 14)),
              pw.Text("A: $targetInstrument", style: const pw.TextStyle(fontSize: 14)),
              pw.Text("Notación: $notationInput → $notationOutput", style: const pw.TextStyle(fontSize: 14)),
              pw.Text("Alteraciones: $accidentalPreference", style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text(content, style: const pw.TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }
}
