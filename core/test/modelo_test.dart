import 'package:auditoria_core/auditoria_core.dart';
import 'package:test/test.dart';

import 'ayuda.dart';

void main() {
  test('responder no modifica la auditoría original (inmutabilidad)', () {
    final a = nueva();
    final b = a.responder('4.1-1', Respuesta.cumple);
    expect(a.respuestaDe('4.1-1').respuesta, isNull);
    expect(b.respuestaDe('4.1-1').respuesta, Respuesta.cumple);
  });

  test('quitar la respuesta conserva la nota; sin nota borra la entrada', () {
    var a = nueva().responder('x', Respuesta.noCumple).conNota('x', 'porque');
    a = a.responder('x', null);
    expect(a.respuestaDe('x').respuesta, isNull);
    expect(a.respuestaDe('x').nota, 'porque');
    a = a.conNota('x', '  ');
    expect(a.respuestas.containsKey('x'), isFalse);
  });

  test('el mapa de respuestas no se puede modificar desde fuera', () {
    final a = nueva().responder('x', Respuesta.cumple);
    expect(() => a.respuestas['y'] = const RespuestaPregunta(),
        throwsUnsupportedError);
  });

  test('copyWith conserva id y fecha de creación', () {
    final a = nueva('abc').copyWith(actualizada: DateTime.utc(2027));
    expect(a.id, 'abc');
    expect(a.creada, t0);
    expect(a.actualizada, DateTime.utc(2027));
  });

  test('Encabezado.copyWith cambia solo lo indicado', () {
    const e = Encabezado(area: 'A', auditor: 'B');
    final f = e.copyWith(area: 'C');
    expect(f.area, 'C');
    expect(f.auditor, 'B');
    expect(f.norma, 'ISO 14001:2015');
  });
}
