import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../widgets/app_scaffold.dart';

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
      XFile? picked;
      try {
        picked = await _picker.pickImage(
          source: source,
          maxWidth: 2400,
          maxHeight: 2400,
          imageQuality: 92,
        );
      } on PlatformException catch (e) {
        // Camera permission denied or other platform error
        if (!mounted) return;
        final loc = AppLocalizations.of(context)!;
        setState(() {
          _state = OcrState.error;
          _errorMessage = e.code == 'camera_access_denied'
              ? loc.camera_permission_denied
              : loc.source_open_error(
                  source == ImageSource.camera
                      ? loc.camera_source
                      : loc.gallery_source,
                  e.message ?? '',
                );
        });
        return;
      }

      // Guard: user cancelled or widget disposed while camera was open
      if (picked == null) return;
      if (!mounted) return;

      String finalPath = picked.path;

      // Only attempt cropping on mobile (where it's supported)
      try {
        final loc = AppLocalizations.of(context)!;
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: picked.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: loc.ocr_crop_title,
              toolbarColor: const Color(0xFF0A1628),
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: const Color(0xFFD4AF37),
              backgroundColor: const Color(0xFF0A1628),
              cropFrameColor: const Color(0xFFD4AF37),
              cropGridColor: Colors.white24,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: loc.ocr_crop_title),
          ],
        );

        // Guard after cropper returns
        if (!mounted) return;

        if (croppedFile != null) {
          finalPath = croppedFile.path;
        }
        // If user cancelled crop, we still use the original picked image
      } catch (cropError) {
        // Cropper failed — use original image
        debugPrint('Image cropper error: $cropError');
        if (!mounted) return;
      }

      setState(() {
        _imagePath = finalPath;
        _state = OcrState.ready;
        _resultController.clear();
      });

      await _extractText(finalPath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = OcrState.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _extractText(String path) async {
    if (!mounted) return;
    setState(() => _state = OcrState.processing);

    try {
      final inputImage = InputImage.fromFilePath(path);
      final RecognizedText recognized =
          await _getRecognizer().processImage(inputImage);

      if (!mounted) return;

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
      if (!mounted) return;
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
      return AppScaffold(
        title: loc.ocr_title,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132035),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: const Icon(Icons.no_photography_outlined,
                      size: 48, color: Colors.white24),
                ),
                const SizedBox(height: 24),
                const Text(
                  'OCR is only available on Android and iOS devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: loc.ocr_title,
      actions: [
        if (_state == OcrState.done || _state == OcrState.ready)
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            tooltip: loc.reset_button,
            onPressed: _reset,
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Source selection (idle state)
            if (_state == OcrState.idle) ...[
              const SizedBox(height: 40),
              Icon(
                Icons.document_scanner_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 24),
              Text(
                loc.ocr_instructions,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(height: 40),
              _buildSourceButton(
                icon: Icons.camera_alt_rounded,
                label: loc.ocr_camera,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _buildSourceButton(
                icon: Icons.photo_library_rounded,
                label: loc.ocr_gallery,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],

            // Image preview
            if (_imagePath != null && _state != OcrState.idle) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.file(
                    File(_imagePath!),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white24, size: 48),
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
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],

            // Error state
            if (_state == OcrState.error) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE05C5C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE05C5C).withOpacity(0.25),
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
                      icon: Icons.camera_alt_rounded,
                      label: loc.ocr_retry_camera,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.photo_library_rounded,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF132035),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                        fontFamily: 'Urbanist',
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
              const SizedBox(height: 16),

              // Editable result
              buildSectionLabel(loc.ocr_result_label),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1828),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
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
                        icon: Icons.download_rounded,
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
                      icon: Icons.camera_alt_rounded,
                      label: loc.ocr_new_scan_camera,
                      onTap: () => _pickImage(ImageSource.camera),
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.photo_library_rounded,
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
            color: const Color(0xFF132035),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.2),
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
            : const Color(0xFF1A2C42);
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
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isOutlined
                ? BorderSide(color: Colors.white.withOpacity(0.15))
                : isPrimary
                    ? BorderSide.none
                    : BorderSide(
                        color: const Color(0xFFD4AF37).withOpacity(0.15)),
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
