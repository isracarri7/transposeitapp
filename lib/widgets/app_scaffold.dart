import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                    if (showBackButton) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Urbanist',
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
              // Subtle separator
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFD4AF37).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
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

/// Smooth page route transition for navigating between screens
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: child,
              ),
            );
          },
        );
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
      labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'Urbanist'),
      filled: true,
      fillColor: const Color(0xFF132035),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
    ),
    dropdownColor: const Color(0xFF132035),
    style: const TextStyle(color: Colors.white, fontFamily: 'Urbanist'),
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
    backgroundColor: const Color(0xFF0F1E35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        _buildExportTile(
          icon: Icons.picture_as_pdf_rounded,
          label: pdfLabel,
          onTap: onExportPdf,
        ),
        Divider(
          color: Colors.white.withOpacity(0.05),
          height: 1,
          indent: 72,
          endIndent: 16,
        ),
        _buildExportTile(
          icon: Icons.image_rounded,
          label: imageLabel,
          onTap: onExportImage,
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

Widget _buildExportTile({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFFD4AF37), size: 22),
    ),
    title: Text(label,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w500,
          fontSize: 15,
        )),
    trailing: Icon(Icons.arrow_forward_ios,
        color: Colors.white.withOpacity(0.2), size: 14),
    onTap: () {
      HapticFeedback.lightImpact();
      onTap();
    },
  );
}

/// Section header label
Widget buildSectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.85),
        fontSize: 14,
        fontFamily: 'Urbanist',
        letterSpacing: 0.3,
      ),
    ),
  );
}

/// Preview container for transposed/digitized results — dark theme
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
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1828),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmpty
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFD4AF37).withOpacity(0.25),
        ),
        boxShadow: [
          if (!isEmpty)
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Text(
        isEmpty ? placeholder : text,
        style: TextStyle(
          fontSize: 16,
          color: isEmpty ? Colors.white.withOpacity(0.25) : Colors.white,
          height: 1.7,
          fontFamily: 'Urbanist',
          fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
          letterSpacing: isEmpty ? 0 : 0.5,
        ),
      ),
    ),
  );
}
