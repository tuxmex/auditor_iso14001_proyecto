import 'dart:convert';
import 'dart:io';

import 'package:auditoria_core/auditoria_core.dart';
import 'package:test/test.dart';

import 'ayuda.dart';

void main() {
  late Directory dir;
  late RepositorioArchivos repo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('auditorias_');
    repo = RepositorioArchivos(Directory('${dir.path}/datos'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('guardar crea la carpeta y cargar devuelve lo mismo', () async {
    final a = completa();
    await repo.guardar(a);
    final b = await repo.cargar(a.id);
    expect(b, isNotNull);
    expect(b!.encabezado.area, 'Laboratorio');
    expect(b.respuestaDe('4.1-1').respuesta, Respuesta.cumple);
  });

  test('no deja archivos temporales después de guardar', () async {
    await repo.guardar(nueva());
    final nombres = Directory('${dir.path}/datos')
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .toList();
    expect(nombres, ['a1.json']);
  });

  test('guardar de nuevo reemplaza el contenido anterior', () async {
    await repo.guardar(nueva());
    await repo.guardar(nueva().responder('4.1-1', Respuesta.noCumple));
    final b = await repo.cargar('a1');
    expect(b!.respuestaDe('4.1-1').respuesta, Respuesta.noCumple);
  });

  test('cargar un id que no existe devuelve null', () async {
    expect(await repo.cargar('nada'), isNull);
  });

  test('un id con ../ nunca toca el disco fuera de la carpeta', () async {
    expect(() => repo.cargar('../fuera'), throwsArgumentError);
    expect(() => repo.borrar('a/b'), throwsArgumentError);
    final a = Auditoria(id: '../x', creada: t0, actualizada: t0);
    expect(() => repo.guardar(a), throwsArgumentError);
  });

  test('listar ordena por última actualización, la más reciente primero', () async {
    await repo.guardar(nueva('vieja'));
    await repo.guardar(
        nueva('nueva').copyWith(actualizada: t0.add(const Duration(days: 1))));
    final l = await repo.listar();
    expect(l.items.map((e) => e.id), ['nueva', 'vieja']);
  });

  test('listar sin carpeta devuelve una lista vacía', () async {
    final l = await repo.listar();
    expect(l.items, isEmpty);
  });

  test('un archivo dañado se aparta como .corrupto y no rompe el listado', () async {
    await repo.guardar(nueva('buena'));
    File('${dir.path}/datos/mala.json').writeAsStringSync('{ esto no es json');
    final l = await repo.listar();
    expect(l.items.map((e) => e.id), ['buena']);
    expect(l.corruptos, ['mala.json']);
    expect(File('${dir.path}/datos/mala.json.corrupto').existsSync(), isTrue);
    expect(File('${dir.path}/datos/mala.json').existsSync(), isFalse);
    // la segunda vez ya no aparece como corrupto
    expect((await repo.listar()).corruptos, isEmpty);
  });

  test('cargar un archivo dañado lanza ArchivoCorrupto', () async {
    await Directory('${dir.path}/datos').create();
    File('${dir.path}/datos/rota.json').writeAsStringSync('[]');
    expect(() => repo.cargar('rota'), throwsA(isA<ArchivoCorrupto>()));
  });

  test('un archivo de versión más nueva se reporta y NO se aparta', () async {
    await Directory('${dir.path}/datos').create();
    final j = auditoriaAJson(nueva('futura'))..['version'] = 99;
    File('${dir.path}/datos/futura.json').writeAsStringSync(jsonEncode(j));
    final l = await repo.listar();
    expect(l.noSoportados, ['futura.json']);
    expect(File('${dir.path}/datos/futura.json').existsSync(), isTrue);
  });

  test('borrar elimina el archivo y tolera borrar dos veces', () async {
    await repo.guardar(nueva());
    await repo.borrar('a1');
    expect(await repo.cargar('a1'), isNull);
    await repo.borrar('a1');
  });

  test('el resumen cuenta solo las preguntas respondidas', () async {
    await repo.guardar(nueva()
        .responder('x', Respuesta.cumple)
        .conNota('y', 'solo nota'));
    final l = await repo.listar();
    expect(l.items.single.respondidas, 1);
  });
}
