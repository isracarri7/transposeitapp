import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

enum OcrState { idle, ready, processing, done, error }

/// Returns true if the current platform supports ML Kit OCR (Android/iOS only).
bool get isOcrSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class OcrScreen extends StatefulWidget {
  final void Function(String text)? onImport;

  const OcrScreen({super.key, this.onImport});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  TextRecognizer? _textRecognizer;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _resultController = TextEditingController();

  TextRecognizer _getRecognizer() {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  OcrState _state = OcrState.idle;
  String? _imagePath;
  String _errorMessage = '';
  double _confidence = 0.0;
  int _blockCount = 0;

  @override
  void dispose() {
    _textRecognizer?.close();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (picked == null) return;
      if (!mounted) return;

      final loc = AppLocalizations.of(context)!;

      // Offer cropping to let user focus on the relevant area
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: loc.ocr_crop_title,
            toolbarColor: const Color(0xFF0A1628),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFD4AF37),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: loc.ocr_crop_title),
        ],
      );

      final String finalPath = croppedFile?.path ?? picked.path;

      setState(() {
        _imagePath = finalPath;
        _state = OcrState.ready;
        _resultController.clear();
      });

      await _extractText(finalPath);
    } catch (e) {
      setState(() {
        _state = OcrState.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _extractText(String path) async {
    setState(() => _state = OcrState.processing);

    try {
      final inputImage = InputImage.fromFilePath(path);
      final RecognizedText recognized =
          await _getRecognizer().processImage(inputImage);

      // Calculate average confidence and block count
      double totalConfidence = 0;
      int elementCount = 0;
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            totalConfidence += element.confidence ?? 0;
            elementCount++;
          }
        }
      }

      setState(() {
        _resultController.text = recognized.text;
        _confidence = elementCount > 0 ? totalConfidence / elementCount : 0;
        _blockCount = recognized.blocks.length;
        _state = recognized.text.isEmpty ? OcrState.error : OcrState.done;
        if (recognized.text.isEmpty) {
          _errorMessage = AppLocalizations.of(context)!.ocr_no_text_found;
        }
      });
    } catch (e) {
      setState(() {
        _state = OcrState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _copyToClipboard() {
    if (_resultController.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _resultController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.copied_snackbar),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _importToDraft() {
    if (_resultController.text.isEmpty) return;
    widget.onImport?.call(_resultController.text);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _state = OcrState.idle;
      _imagePath = null;
      _resultController.clear();
      _errorMessage = '';
      _confidence = 0;
      _blockCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Platform guard: OCR only works on Android/iOS
    if (!isOcrSupported) {
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.no_photography_outlined,
                              size: 64, color: Colors.white38),
                          SizedBox(height: 16),
                          Text(
                            'OCR is only available on Android and iOS devices.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                      loc.ocr_title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                    const Spacer(),
                    if (_state == OcrState.done || _state == OcrState.ready)
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
                        tooltip: loc.reset_button,
                        onPressed: _reset,
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Source selection (always visible when idle)
                      if (_state == OcrState.idle) ...[
                        const SizedBox(height: 40),
                        Icon(
                          Icons.document_scanner_outlined,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          loc.ocr_instructions,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                            fontFamily: 'Urbanist',
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildSourceButton(
                          icon: Icons.camera_alt,
                          label: loc.ocr_camera,
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                        const SizedBox(height: 12),
                        _buildSourceButton(
                          icon: Icons.photo_library,
                          label: loc.ocr_gallery,
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ],

                      // Image preview
                      if (_imagePath != null && _state != OcrState.idle) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 250),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(
                                File(_imagePath!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Processing indicator
                      if (_state == OcrState.processing) ...[
                        const SizedBox(height: 32),
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD4AF37),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.ocr_processing,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],

                      // Error state
                      if (_state == OcrState.error) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE05C5C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE05C5C).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFE05C5C), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: Color(0xFFE05C5C),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.camera_alt,
                                label: loc.ocr_retry_camera,
                                onTap: () => _pickImage(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.photo_library,
                                label: loc.ocr_retry_gallery,
                                onTap: () => _pickImage(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Results
                      if (_state == OcrState.done) ...[
                        // Confidence indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132035),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _confidence > 0.7
                                    ? Icons.check_circle
                                    : _confidence > 0.4
                                        ? Icons.info
                                        : Icons.warning,
                                color: _confidence > 0.7
                                    ? const Color(0xFF4CAF50)
                                    : _confidence > 0.4
                                        ? const Color(0xFFD4AF37)
                                        : const Color(0xFFE05C5C),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.ocr_confidence(
                                    (_confidence * 100).toStringAsFixed(0)),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                loc.ocr_blocks(_blockCount.toString()),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Editable result
                        Text(
                          loc.ocr_result_label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1828),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _resultController,
                            maxLines: 8,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(14),
                              border: InputBorder.none,
                              hintText: loc.ocr_edit_hint,
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.copy,
                                label: loc.copy_button,
                                onTap: _copyToClipboard,
                              ),
                            ),
                            if (widget.onImport != null) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.download,
                                  label: loc.ocr_import_button,
                                  onTap: _importToDraft,
                                  isPrimary: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Re-scan buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.camera_alt,
                                label: loc.ocr_new_scan_camera,
                                onTap: () => _pickImage(ImageSource.camera),
                                isOutlined: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.photo_library,
                                label: loc.ocr_new_scan_gallery,
                                onTap: () => _pickImage(ImageSource.gallery),
                                isOutlined: true,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A3050).withOpacity(0.8),
                const Color(0xFF132035).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFD4AF37), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isOutlined = false,
  }) {
    final Color bgColor = isPrimary
        ? const Color(0xFFD4AF37)
        : isOutlined
            ? Colors.transparent
            : const Color(0xFF1E2A38);
    final Color fgColor = isPrimary ? const Color(0xFF0A1628) : Colors.white;

    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          foregroundColor: fgColor,
          backgroundColor: bgColor,
          elevation: isOutlined ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isOutlined
                ? BorderSide(color: Colors.white.withOpacity(0.2))
                : BorderSide.none,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Urbanist',
          ),
        ),
      ),
    );
  }
}
