import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension LocalizationHelper on AppLocalizations {
  String getTranslation(String key) {
    switch (key) {
      // Notation options
      case 'latina_option':
        return latina_option;
      case 'american_option':
        return american_option;
      case 'sharp_option':
        return sharp_option;
      case 'flat_option':
        return flat_option;

      // Complexity levels
      case 'complexity_simple':
        return complexity_simple;
      case 'complexity_chords':
        return complexity_chords;
      case 'complexity_advanced':
        return complexity_advanced;

      // Instruments
      case 'piano':
        return piano;
      case 'trumpet':
        return trumpet;
      case 'alto_sax':
        return alto_sax;
      case 'tenor_sax':
        return tenor_sax;
      case 'clarinet_bb':
        return clarinet_bb;
      case 'french_horn':
        return french_horn;
      case 'clarinet_a':
        return clarinet_a;
      case 'flute':
        return flute;

      default:
        return key;
    }
  }
}
