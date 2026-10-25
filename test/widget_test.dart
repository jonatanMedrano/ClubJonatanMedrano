import 'package:club_jonatan_medrano/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fmtDate pasa AAAA-MM-DD a DD/MM/AAAA', () {
    expect(fmtDate('2026-10-24'), '24/10/2026');
  });

  test('hhmm recorta los segundos', () {
    expect(hhmm('19:00:00'), '19:00');
  });
}
