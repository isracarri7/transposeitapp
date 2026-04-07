import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData? icon;
  final bool isPrimary;
  final bool isSmall;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isPrimary = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isPrimary ? const Color(0xFFD4AF37) : const Color(0xFF1A2C42);
    final fgColor =
        isPrimary ? const Color(0xFF0A1628) : Colors.white;
    final borderColor = isPrimary
        ? Colors.transparent
        : const Color(0xFFD4AF37).withOpacity(0.12);

    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: fgColor,
      backgroundColor: bgColor,
      elevation: 0,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 14 : 16,
        vertical: isSmall ? 10 : 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmall ? 10 : 14),
        side: BorderSide(color: borderColor),
      ),
      textStyle: TextStyle(
        fontSize: isSmall ? 14 : 15,
        fontWeight: FontWeight.w600,
        fontFamily: 'Urbanist',
      ),
    );

    void handlePress() {
      HapticFeedback.lightImpact();
      onPressed();
    }

    final button = icon == null
        ? ElevatedButton(
            onPressed: handlePress,
            style: buttonStyle,
            child: Text(text),
          )
        : ElevatedButton.icon(
            onPressed: handlePress,
            style: buttonStyle,
            icon: Icon(icon, size: isSmall ? 16 : 20),
            label: Text(text),
          );

    return SizedBox(
      height: isSmall ? 42 : 50,
      child: button,
    );
  }
}
