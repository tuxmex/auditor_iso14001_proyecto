import 'package:auditoria_core/auditoria_core.dart';
import 'package:test/test.dart';

import 'ayuda.dart';

void main() {
  group('Catalogo.desdeJson', () {
    test('lee cláusulas y preguntas y las busca por id', () {
      final c = catalogoPrueba();
      expect(c.clausulas.length, 2);
      expect(c.totalPreguntas, 5);
      expect(c.pregunta('6.1.2-2')!.clausula, '6.1.2');
      expect(c.clausula('4.1')!.etiqueta, '4.1 Contexto');
      expect(c.pregunta('no-existe'), isNull);
    });

    test('la lista de cláusulas no se puede modificar desde fuera', () {
      final c = catalogoPrueba();
      expect(() => c.clausulas.clear(), throwsUnsupportedError);
    });

    test('rechaza lo que no es un objeto', () {
      expect(() => Catalogo.desdeJson([]), throwsFormatException);
      expect(() => Catalogo.desdeJson(null), throwsFormatException);
    });

    test('rechaza catálogo sin cláusulas, sin norma o con ids repetidos', () {
      expect(() => Catalogo.desdeJson({'norma': 'x', 'clausulas': []}),
          throwsFormatException);
      expect(() => Catalogo.desdeJson({'clausulas': [1]}), throwsFormatException);
      Map<String, Object?> clausula(String n) => {
            'numero': n,
            'titulo': 't',
            'proposito': 'p',
            'preguntas': [
              {'id': 'x-1', 'texto': '¿a?', 'evidencia': 'e'}
            ],
          };
      expect(
          () => Catalogo.desdeJson({
                'norma': 'n',
                'clausulas': [clausula('1'), clausula('2')]
              }),
          throwsA(isA<FormatException>()
              .having((e) => e.message, 'mensaje', contains('Id repetido'))));
    });

    test('el mensaje de error dice qué campo falta', () {
      expect(
          () => Catalogo.desdeJson({
                'norma': 'n',
                'clausulas': [
                  {'numero': '4.1', 'titulo': 't', 'preguntas': []}
                ]
              }),
          throwsA(isA<FormatException>()
              .having((e) => e.message, 'mensaje', contains('proposito'))));
    });
  });

  group('catálogo real de la app', () {
    final c = catalogoReal();
    test('tiene las 13 cláusulas pedidas, en orden', () {
      expect(c.clausulas.map((x) => x.numero).toList(), [
        '4.1', '4.2', '5.2', '5.3', '6.1', '6.1.2', '6.2',
        '7.3', '7.4', '7.5', '8.1', '9.1', '10.3',
      ]);
    });
    test('suma 58 preguntas', () => expect(c.totalPreguntas, 58));
    test('cada pregunta apunta a su cláusula', () {
      for (final p in c.todasLasPreguntas) {
        expect(p.id.startsWith('${p.clausula}-'), isTrue, reason: p.id);
      }
    });
  });
}
