import 'package:auditoria_core/auditoria_core.dart';
import 'package:test/test.dart';

import 'ayuda.dart';

void main() {
  final cat = catalogoPrueba();

  test('una auditoría incompleta sale marcada como BORRADOR con pendientes', () {
    final r = construirReporteTexto(cat, nueva());
    expect(r, contains('BORRADOR'));
    expect(r, contains('PENDIENTES PARA EMITIR'));
    expect(r, contains('Falta: objetivo de la auditoría.'));
  });

  test('una auditoría completa no es borrador y sigue el orden del formato', () {
    final r = construirReporteTexto(cat, completa());
    expect(r, isNot(contains('BORRADOR')));
    expect(r, isNot(contains('PENDIENTES')));
    final orden = [
      'LISTA DE VERIFICACIÓN',
      'Objetivo de la auditoría: Evaluar el área',
      'Área a ser auditada: Laboratorio',
      'RESUMEN',
      'REDACCIÓN DE HALLAZGOS',
      'Auditor: Tacho',
      'Fecha: 20/11/2026',
    ];
    var desde = 0;
    for (final t in orden) {
      final i = r.indexOf(t, desde);
      expect(i, greaterThanOrEqualTo(0), reason: 'falta o desordenado: $t');
      desde = i;
    }
  });

  test('muestra Sí / No / -- y las notas', () {
    final a = nueva()
        .responder('4.1-1', Respuesta.cumple)
        .responder('4.1-2', Respuesta.noCumple)
        .conNota('4.1-2', 'No hay evidencia');
    final r = construirReporteTexto(cat, a);
    expect(r, contains('4.1-1  [Sí]  Uno'));
    expect(r, contains('4.1-2  [No]  Dos'));
    expect(r, contains('Nota: No hay evidencia'));
    expect(r, contains('6.1.2-1  [--]'));
  });

  test('el resumen muestra porcentajes y "sin datos" cuando no hay respuestas', () {
    final a = nueva().responder('4.1-1', Respuesta.cumple);
    final r = construirReporteTexto(cat, a);
    expect(r, contains('4.1 Contexto: 100 %'));
    expect(r, contains('6.1.2 Aspectos: sin datos'));
  });

  test('formatoFecha rellena con ceros y tolera null', () {
    expect(formatoFecha(DateTime(2026, 3, 5)), '05/03/2026');
    expect(formatoFecha(null), '__/__/____');
  });

  test('lista los hallazgos numerados', () {
    final a = completa().copyWith(hallazgos: const [
      Hallazgo(texto: 'H uno', requisito: '4.1', evidencia: 'E uno'),
    ]);
    final r = construirReporteTexto(cat, a);
    expect(r, contains('1. Requisito evaluado: 4.1'));
    expect(r, contains('Evidencia: E uno'));
  });

  group('nombreArchivoReporte', () {
    test('quita acentos, espacios y símbolos', () {
      final a = completa().copyWith(
          encabezado: Encabezado(
              area: 'Laboratorio de Química / Taller #2',
              fecha: DateTime(2026, 3, 5)));
      expect(nombreArchivoReporte(a),
          'F-OSC-39_Laboratorio_de_Quimica_Taller_2_20260305.pdf');
    });
    test('sin área usa un nombre genérico y la fecha de actualización', () {
      expect(nombreArchivoReporte(nueva()), 'F-OSC-39_sin_area_20261120.pdf');
    });
  });
}
