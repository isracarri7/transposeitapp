import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF1E2A38),
      elevation: 3,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Urbanist',
      ),
    );

    final button = icon == null
        ? ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Text(text),
    )
        : ElevatedButton.icon(
      onPressed: onPressed,
      style: buttonStyle,
      icon: Icon(icon),
      label: Text(text),
    );

    return SizedBox(
      height: 48,
      child: button,
    );
  }
}