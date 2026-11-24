import 'package:auditoria_core/auditoria_core.dart';
import 'package:test/test.dart';

import 'ayuda.dart';

void main() {
  late RepositorioMemoria repo;
  late SesionAuditoria s;
  late int avisos;
  var hora = DateTime.utc(2026, 11, 20, 12);

  setUp(() {
    repo = RepositorioMemoria();
    avisos = 0;
    s = SesionAuditoria(
      catalogo: catalogoPrueba(),
      inicial: nueva(),
      repositorio: repo,
      reloj: () => hora = hora.add(const Duration(seconds: 1)),
      alCambiar: () => avisos++,
    );
  });

  test('cada cambio avisa a la pantalla y termina guardado', () async {
    s.responder('4.1-1', Respuesta.cumple);
    expect(avisos, 1);
    expect(s.guardando, isTrue);
    await s.guardado;
    expect(s.guardando, isFalse);
    expect(repo.almacen['a1']!.respuestaDe('4.1-1').respuesta, Respuesta.cumple);
  });

  test('muchos cambios seguidos se fusionan y gana el último estado', () async {
    for (var i = 0; i < 100; i++) {
      s.nota('4.1-1', 'texto $i');
    }
    await s.guardado;
    expect(repo.almacen['a1']!.respuestaDe('4.1-1').nota, 'texto 99');
    // 1 escritura que ya estaba en curso + 1 con el último estado
    expect(repo.escrituras, lessThanOrEqualTo(2));
  });

  test('el reloj actualiza la fecha de modificación', () async {
    final antes = s.auditoria.actualizada;
    s.responder('4.1-1', Respuesta.cumple);
    expect(s.auditoria.actualizada.isAfter(antes), isTrue);
    await s.guardado;
  });

  test('un fallo al guardar se registra, avisa y la siguiente escritura lo limpia', () async {
    repo.fallaAlGuardar = StateError('disco lleno');
    s.responder('4.1-1', Respuesta.cumple);
    await s.guardado;
    expect(s.ultimoError, isA<StateError>());
    final avisosConError = avisos;
    expect(avisosConError, greaterThanOrEqualTo(2)); // cambio + aviso del error

    repo.fallaAlGuardar = null;
    s.responder('4.1-2', Respuesta.cumple);
    await s.guardado;
    expect(s.ultimoError, isNull);
    expect(repo.almacen['a1']!.respuestaDe('4.1-2').respuesta, Respuesta.cumple);
  });

  test('hallazgos: agregar, editar y quitar con índices fuera de rango ignorados', () async {
    s.agregarHallazgo(const Hallazgo(texto: 'a', requisito: '4.1'));
    s.agregarHallazgo(const Hallazgo(texto: 'b', requisito: '6.1.2'));
    s.editarHallazgo(0, const Hallazgo(texto: 'a2', requisito: '4.1', evidencia: 'e'));
    s.editarHallazgo(9, const Hallazgo(texto: 'x', requisito: '4.1'));
    s.quitarHallazgo(1);
    s.quitarHallazgo(-1);
    await s.guardado;
    final h = repo.almacen['a1']!.hallazgos;
    expect(h.length, 1);
    expect(h.single.texto, 'a2');
    expect(h.single.evidencia, 'e');
  });

  test('aceptarSugerencias agrega borradores y devuelve cuántos', () async {
    s.responder('6.1.2-1', Respuesta.noCumple);
    expect(s.aceptarSugerencias(), 1);
    expect(s.aceptarSugerencias(), 0); // ya está cubierta
    await s.guardado;
    expect(repo.almacen['a1']!.hallazgos.single.requisito, '6.1.2');
  });

  test('actualizarEncabezado cambia solo el campo indicado', () async {
    s.actualizarEncabezado((e) => e.copyWith(area: 'Biblioteca'));
    s.actualizarEncabezado((e) => e.copyWith(auditor: 'Ana'));
    await s.guardado;
    final e = repo.almacen['a1']!.encabezado;
    expect(e.area, 'Biblioteca');
    expect(e.auditor, 'Ana');
  });

  test('resumen, problemas y reporte reflejan el estado actual', () {
    s.responder('4.1-1', Respuesta.noCumple);
    expect(s.resumen.noCumple, 1);
    expect(s.problemas, isNotEmpty);
    expect(s.reporteTexto, contains('BORRADOR'));
  });
}
