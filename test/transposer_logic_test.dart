import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transposición musical', () {
    final latinNotes = [
      'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa',
      'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'
    ];
    final latinNotesFlat = [
      'Do', 'Reb', 'Re', 'Mib', 'Mi', 'Fa',
      'Solb', 'Sol', 'Lab', 'La', 'Sib', 'Si'
    ];

    int transposeIndex(int idx, int offset) => (idx + offset) % 12;

    test('Transponer Do 2 semitonos (♯)', () {
      final index = latinNotes.indexOf('Do');
      final newIndex = transposeIndex(index, 2);
      expect(latinNotes[newIndex], 'Re');
    });

    test('Transponer Do# 2 semitonos (♯)', () {
      final index = latinNotes.indexOf('Do#');
      final newIndex = transposeIndex(index, 2);
      expect(latinNotes[newIndex], 'Mi');
    });

    test('Transponer Do# 2 semitonos (♭)', () {
      final index = latinNotes.indexOf('Do#');
      final newIndex = transposeIndex(index, 2);
      expect(latinNotesFlat[newIndex], 'Mi');
    });

    test('Transponer Mi 2 semitonos (♭)', () {
      final index = latinNotes.indexOf('Mi');
      final newIndex = transposeIndex(index, 2);
      expect(latinNotesFlat[newIndex], 'Solb');
    });
  });
}
