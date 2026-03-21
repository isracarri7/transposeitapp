import 'package:flutter/material.dart';

/// Shared scaffold wrapper with dark gradient background and custom app bar.
/// Use this in every screen for visual consistency.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0F1E35),
              Color(0xFF142842),
              Color(0xFF0F1E35),
              Color(0xFF0A1628),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    if (showBackButton) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Urbanist',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
              // Body
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// Styled dropdown matching the app theme
Widget buildStyledDropdown({
  required String value,
  required String label,
  required List<String> items,
  required String Function(String key) translateFn,
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
    icon: Icon(Icons.keyboard_arrow_down_rounded,
        color: Colors.white.withOpacity(0.5)),
    items: items
        .map((key) => DropdownMenuItem(
              value: key,
              child: Text(translateFn(key)),
            ))
        .toList(),
    onChanged: onChanged,
  );
}

/// Styled bottom sheet for export options
Future<void> showExportBottomSheet({
  required BuildContext context,
  required VoidCallback onExportPdf,
  required VoidCallback onExportImage,
  required String pdfLabel,
  required String imageLabel,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF132035),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf,
                color: Color(0xFFD4AF37), size: 22),
          ),
          title: Text(pdfLabel,
              style: const TextStyle(color: Colors.white, fontFamily: 'Urbanist')),
          trailing: Icon(Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3), size: 14),
          onTap: onExportPdf,
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.image,
                color: Color(0xFFD4AF37), size: 22),
          ),
          title: Text(imageLabel,
              style: const TextStyle(color: Colors.white, fontFamily: 'Urbanist')),
          trailing: Icon(Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3), size: 14),
          onTap: onExportImage,
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

/// Section header label
Widget buildSectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Urbanist',
      ),
    ),
  );
}

/// Preview container for transposed/digitized results
Widget buildPreviewContainer({
  required GlobalKey repaintKey,
  required String text,
  required String placeholder,
}) {
  final isEmpty = text.trim().isEmpty;
  return RepaintBoundary(
    key: repaintKey,
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        isEmpty ? placeholder : text,
        style: TextStyle(
          fontSize: 16,
          color: isEmpty ? Colors.grey : Colors.black87,
          height: 1.6,
        ),
      ),
    ),
  );
}
