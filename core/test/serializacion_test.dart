import 'dart:convert';

import 'package:auditoria_core/auditoria_core.dart';
import 'package:test/test.dart';

import 'ayuda.dart';

void main() {
  pruebasDeId();
  Auditoria rica() => completa()
      .responder('6.1.2-2', Respuesta.noCumple)
      .conNota('6.1.2-2', 'Falta el inventario ñandú áéíóú')
      .copyWith(hallazgos: const [
    Hallazgo(texto: 'Hallazgo 1', requisito: '6.1.2', evidencia: 'Foto'),
  ]);

  test('ida y vuelta por JSON de texto conserva todo', () {
    final a = rica();
    final texto = jsonEncode(auditoriaAJson(a));
    final b = auditoriaDesdeJson(jsonDecode(texto));
    expect(b.id, a.id);
    expect(b.creada, a.creada);
    expect(b.actualizada, a.actualizada);
    expect(b.encabezado.area, 'Laboratorio');
    expect(b.encabezado.fecha, a.encabezado.fecha);
    expect(b.respuestaDe('6.1.2-2').respuesta, Respuesta.noCumple);
    expect(b.respuestaDe('6.1.2-2').nota, contains('ñandú'));
    expect(b.respuestaDe('4.1-1').respuesta, Respuesta.cumple);
    expect(b.hallazgos.single.evidencia, 'Foto');
  });

  test('el JSON declara la versión del esquema', () {
    expect(auditoriaAJson(nueva())['version'], versionEsquema);
  });

  test('un archivo de una versión más nueva se rechaza con su propio error', () {
    final j = auditoriaAJson(nueva())..['version'] = versionEsquema + 1;
    expect(() => auditoriaDesdeJson(j), throwsA(isA<VersionNoSoportada>()));
  });

  test('entradas dañadas producen FormatException, no errores de tipo', () {
    expect(() => auditoriaDesdeJson('hola'), throwsFormatException);
    expect(() => auditoriaDesdeJson({}), throwsFormatException);
    expect(() => auditoriaDesdeJson({'version': 'uno'}), throwsFormatException);
    final sinFecha = auditoriaAJson(nueva())..['creada'] = 'ayer';
    expect(() => auditoriaDesdeJson(sinFecha), throwsFormatException);
  });

  test('un id con ../ se rechaza al leer (defensa contra rutas)', () {
    final j = auditoriaAJson(nueva())..['id'] = '../../etc/passwd';
    expect(() => auditoriaDesdeJson(j), throwsFormatException);
    expect(idValido('abc_DEF-123'), isTrue);
    expect(idValido(''), isFalse);
    expect(idValido('a b'), isFalse);
  });

  test('respuestas desconocidas o con tipo raro se leen como "sin responder"', () {
    final j = auditoriaAJson(nueva());
    j['respuestas'] = {
      'a': {'r': 'quizás', 'n': ''},
      'b': {'r': 42, 'n': 'nota ok'},
      'c': 'no soy mapa',
      'd': {'r': 'cumple', 'n': 7},
    };
    final a = auditoriaDesdeJson(j);
    expect(a.respuestas.containsKey('a'), isFalse);
    expect(a.respuestaDe('b').respuesta, isNull);
    expect(a.respuestaDe('b').nota, 'nota ok');
    expect(a.respuestas.containsKey('c'), isFalse);
    expect(a.respuestaDe('d').respuesta, Respuesta.cumple);
    expect(a.respuestaDe('d').nota, '');
  });

  test('hallazgos con elementos basura se omiten sin romper', () {
    final j = auditoriaAJson(nueva());
    j['hallazgos'] = [
      5,
      {'texto': 't', 'requisito': '4.1', 'evidencia': 'e'}
    ];
    expect(auditoriaDesdeJson(j).hallazgos.length, 1);
  });
}

void pruebasDeId() {
  test('generarId siempre produce un id válido y es determinista con azar fijo', () {
    final a = generarId(DateTime.utc(2026, 11, 20), 7);
    expect(idValido(a), isTrue);
    expect(a, generarId(DateTime.utc(2026, 11, 20), 7));
    expect(a, isNot(generarId(DateTime.utc(2026, 11, 20), 8)));
    expect(idValido(generarId(DateTime.now())), isTrue);
  });
}
