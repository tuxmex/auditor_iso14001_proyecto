import 'dart:convert';
import 'dart:io';

import 'modelo.dart';
import 'serializacion.dart';

/// Lo que la pantalla de inicio necesita para listar una auditoría sin
/// cargar todo su contenido.
class ResumenAuditoria {
  const ResumenAuditoria({
    required this.id,
    required this.area,
    required this.auditor,
    required this.actualizada,
    required this.respondidas,
  });

  final String id;
  final String area;
  final String auditor;
  final DateTime actualizada;
  final int respondidas;

  factory ResumenAuditoria.de(Auditoria a) {
    return ResumenAuditoria(
      id: a.id,
      area: a.encabezado.area,
      auditor: a.encabezado.auditor,
      actualizada: a.actualizada,
      respondidas:
          a.respuestas.values.where((r) => r.respuesta != null).length,
    );
  }
}

/// Resultado de listar: lo que se pudo leer y lo que no, sin ocultarlo.
class Listado {
  const Listado({
    required this.items,
    this.corruptos = const [],
    this.noSoportados = const [],
  });

  final List<ResumenAuditoria> items;
  final List<String> corruptos; // archivos dañados, apartados como .corrupto
  final List<String> noSoportados; // escritos por una app más nueva
}

class ArchivoCorrupto implements Exception {
  const ArchivoCorrupto(this.id, this.motivo);
  final String id;
  final String motivo;
  @override
  String toString() => 'La auditoría $id está dañada: $motivo';
}

abstract interface class RepositorioAuditorias {
  Future<Listado> listar();
  Future<Auditoria?> cargar(String id);
  Future<void> guardar(Auditoria auditoria);
  Future<void> borrar(String id);
}

/// Un archivo JSON por auditoría dentro de [directorio].
/// Escribe en un archivo temporal y lo renombra: si la app se cierra a mitad
/// de la escritura, el archivo anterior queda intacto.
class RepositorioArchivos implements RepositorioAuditorias {
  RepositorioArchivos(this.directorio);

  final Directory directorio;

  File _archivo(String id) {
    if (!idValido(id)) {
      throw ArgumentError.value(id, 'id', 'Identificador no permitido');
    }
    return File('${directorio.path}${Platform.pathSeparator}$id.json');
  }

  @override
  Future<void> guardar(Auditoria a) async {
    final destino = _archivo(a.id);
    await directorio.create(recursive: true);
    final temporal = File('${destino.path}.tmp');
    await temporal.writeAsString(jsonEncode(auditoriaAJson(a)), flush: true);
    await temporal.rename(destino.path);
  }

  @override
  Future<Auditoria?> cargar(String id) async {
    final f = _archivo(id);
    if (!await f.exists()) return null;
    try {
      return auditoriaDesdeJson(jsonDecode(await f.readAsString()));
    } on FormatException catch (e) {
      throw ArchivoCorrupto(id, e.message);
    }
  }

  @override
  Future<Listado> listar() async {
    if (!await directorio.exists()) return const Listado(items: []);
    final items = <ResumenAuditoria>[];
    final corruptos = <String>[];
    final noSoportados = <String>[];
    await for (final e in directorio.list()) {
      if (e is! File || !e.path.endsWith('.json')) continue;
      final nombre = e.uri.pathSegments.last;
      try {
        final a = auditoriaDesdeJson(jsonDecode(await e.readAsString()));
        items.add(ResumenAuditoria.de(a));
      } on VersionNoSoportada {
        noSoportados.add(nombre);
      } on FormatException {
        corruptos.add(nombre);
        try {
          await e.rename('${e.path}.corrupto');
        } on FileSystemException {
          // si no se puede apartar, al menos no rompe el listado
        }
      }
    }
    items.sort((a, b) => b.actualizada.compareTo(a.actualizada));
    return Listado(items: items, corruptos: corruptos, noSoportados: noSoportados);
  }

  @override
  Future<void> borrar(String id) async {
    final f = _archivo(id);
    if (await f.exists()) await f.delete();
  }
}

/// Para pruebas y para la app mientras no hay disco.
class RepositorioMemoria implements RepositorioAuditorias {
  final Map<String, Auditoria> almacen = {};

  /// Útil para simular fallos en las pruebas.
  Object? fallaAlGuardar;

  /// Cuántas veces se escribió de verdad.
  int escrituras = 0;

  @override
  Future<void> guardar(Auditoria a) async {
    await Future<void>.delayed(Duration.zero);
    final falla = fallaAlGuardar;
    if (falla != null) throw falla;
    escrituras++;
    almacen[a.id] = a;
  }

  @override
  Future<Auditoria?> cargar(String id) async => almacen[id];

  @override
  Future<void> borrar(String id) async {
    almacen.remove(id);
  }

  @override
  Future<Listado> listar() async {
    final items = almacen.values.map(ResumenAuditoria.de).toList()
      ..sort((a, b) => b.actualizada.compareTo(a.actualizada));
    return Listado(items: items);
  }
}
