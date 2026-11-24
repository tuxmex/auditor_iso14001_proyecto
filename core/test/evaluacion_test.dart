import 'package:auditoria_core/auditoria_core.dart';
import 'package:test/test.dart';

import 'ayuda.dart';

void main() {
  final cat = catalogoPrueba();

  group('calcularResumen', () {
    test('sin respuestas: porcentaje nulo y todo pendiente', () {
      final r = calcularResumen(cat, nueva());
      expect(r.total, 5);
      expect(r.pendientes, 5);
      expect(r.porcentaje, isNull);
      expect(r.avance, 0);
      expect(r.clausulas.first.porcentaje, isNull);
    });

    test('el porcentaje usa solo las preguntas respondidas', () {
      var a = nueva()
          .responder('4.1-1', Respuesta.cumple)
          .responder('4.1-2', Respuesta.noCumple)
          .responder('6.1.2-1', Respuesta.cumple);
      final r = calcularResumen(cat, a);
      expect(r.cumple, 2);
      expect(r.noCumple, 1);
      expect(r.pendientes, 2);
      expect(r.porcentaje, closeTo(66.67, 0.01));
      expect(r.avance, closeTo(0.6, 1e-9));
      expect(r.clausulas[0].porcentaje, 50);
      expect(r.clausulas[1].porcentaje, 100);
      expect(r.clausulas[1].pendientes, 2);
    });

    test('ignora respuestas a preguntas que ya no están en el catálogo', () {
      final a = nueva().responder('fantasma-1', Respuesta.cumple);
      expect(calcularResumen(cat, a).respondidas, 0);
    });
  });

  group('validarParaEmitir', () {
    test('una auditoría completa y sin "No" no tiene problemas', () {
      expect(validarParaEmitir(cat, completa()), isEmpty);
    });

    test('pide objetivo, área, auditor y fecha', () {
      final p = validarParaEmitir(cat, nueva());
      final enc = p.where((x) => x.tipo == TipoProblema.encabezado).toList();
      expect(enc.length, 4);
      expect(p.where((x) => x.tipo == TipoProblema.sinResponder).length, 5);
    });

    test('un "No" exige nota y un hallazgo que cite su cláusula', () {
      final a = completa().responder('6.1.2-2', Respuesta.noCumple);
      final p = validarParaEmitir(cat, a);
      expect(p.map((x) => x.tipo),
          containsAll([TipoProblema.noSinNota, TipoProblema.noSinHallazgo]));
      expect(p.firstWhere((x) => x.tipo == TipoProblema.noSinNota).referencia,
          '6.1.2-2');
      expect(
          p.firstWhere((x) => x.tipo == TipoProblema.noSinHallazgo).referencia,
          '6.1.2');
    });

    test('con nota y hallazgo completo ya no hay problemas', () {
      final a = completa()
          .responder('6.1.2-2', Respuesta.noCumple)
          .conNota('6.1.2-2', 'No hay inventario')
          .copyWith(hallazgos: const [
        Hallazgo(
            texto: 'Falta inventario de aspectos',
            requisito: '6.1.2',
            evidencia: 'Entrevista con el responsable'),
      ]);
      expect(validarParaEmitir(cat, a), isEmpty);
    });

    test('un hallazgo sin evidencia o con requisito inexistente es problema', () {
      final a = completa().copyWith(hallazgos: const [
        Hallazgo(texto: 'algo', requisito: '4.1'),
        Hallazgo(texto: 'otro', requisito: '9.9', evidencia: 'x'),
      ]);
      final tipos = validarParaEmitir(cat, a).map((x) => x.tipo);
      expect(tipos, contains(TipoProblema.hallazgoIncompleto));
      expect(tipos, contains(TipoProblema.hallazgoRequisitoInvalido));
    });

    test('un hallazgo en una cláusula sin "No" no estorba', () {
      final a = completa().copyWith(hallazgos: const [
        Hallazgo(texto: 'observación', requisito: '4.1', evidencia: 'foto'),
      ]);
      expect(validarParaEmitir(cat, a), isEmpty);
    });
  });

  group('sugerirHallazgos', () {
    test('una sugerencia por cláusula con "No", con notas incluidas', () {
      final a = completa()
          .responder('4.1-1', Respuesta.noCumple)
          .conNota('4.1-1', 'sin análisis')
          .responder('6.1.2-1', Respuesta.noCumple)
          .responder('6.1.2-3', Respuesta.noCumple);
      final s = sugerirHallazgos(cat, a);
      expect(s.map((h) => h.requisito), ['4.1', '6.1.2']);
      expect(s[0].texto, contains('sin análisis'));
      expect(s[1].texto, contains('¿Tres?'));
      expect(s[1].texto, contains('¿Cinco?'));
      expect(s[1].evidencia, isEmpty); // la evidencia la escribe el auditor
    });

    test('no repite cláusulas que ya tienen hallazgo', () {
      final a = completa().responder('4.1-1', Respuesta.noCumple).copyWith(
          hallazgos: const [Hallazgo(texto: 't', requisito: '4.1')]);
      expect(sugerirHallazgos(cat, a), isEmpty);
    });

    test('sin "No" no sugiere nada', () {
      expect(sugerirHallazgos(cat, completa()), isEmpty);
    });
  });
}
