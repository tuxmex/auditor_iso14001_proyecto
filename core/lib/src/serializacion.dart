import 'dart:math';

import 'modelo.dart';

/// Versión del formato de archivo. Si cambia la forma de guardar, se sube y
/// se escribe aquí la migración de las versiones anteriores.
const int versionEsquema = 1;

/// El archivo lo escribió una versión más nueva de la app.
class VersionNoSoportada implements Exception {
  const VersionNoSoportada(this.version);
  final int version;
  @override
  String toString() =>
      'El archivo usa el formato $version y esta app solo entiende hasta el $versionEsquema.';
}

final RegExp _formatoId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

bool idValido(String id) => _formatoId.hasMatch(id);

Map<String, Object?> auditoriaAJson(Auditoria a) {
  return {
    'version': versionEsquema,
    'id': a.id,
    'creada': a.creada.toUtc().toIso8601String(),
    'actualizada': a.actualizada.toUtc().toIso8601String(),
    'encabezado': {
      'objetivo': a.encabezado.objetivo,
      'area': a.encabezado.area,
      'norma': a.encabezado.norma,
      'elementos': a.encabezado.elementos,
      'documentos': a.encabezado.documentos,
      'auditor': a.encabezado.auditor,
      'fecha': a.encabezado.fecha?.toIso8601String(),
    },
    'respuestas': {
      for (final e in a.respuestas.entries)
        e.key: {
          'r': switch (e.value.respuesta) {
            Respuesta.cumple => 'cumple',
            Respuesta.noCumple => 'noCumple',
            null => null,
          },
          'n': e.value.nota,
        },
    },
    'hallazgos': [
      for (final h in a.hallazgos)
        {'texto': h.texto, 'requisito': h.requisito, 'evidencia': h.evidencia},
    ],
  };
}

/// Lee una auditoría de un JSON ya decodificado. Es defensivo: un archivo
/// editado a mano o dañado produce un [FormatException] claro, nunca un
/// error de tipos a mitad de la pantalla.
Auditoria auditoriaDesdeJson(Object? json) {
  if (json is! Map) {
    throw const FormatException('El archivo no contiene un objeto JSON.');
  }
  final version = json['version'];
  if (version is! int) {
    throw const FormatException('Falta la versión del formato.');
  }
  if (version > versionEsquema) throw VersionNoSoportada(version);
  if (version < 1) throw FormatException('Versión inválida: $version');

  final id = json['id'];
  if (id is! String || !idValido(id)) {
    throw const FormatException('Identificador inválido.');
  }
  final creada = _fechaObligatoria(json['creada'], 'creada');
  final actualizada = _fechaObligatoria(json['actualizada'], 'actualizada');

  final enc = json['encabezado'];
  final encabezado = enc is Map
      ? Encabezado(
          objetivo: _texto(enc['objetivo']),
          area: _texto(enc['area']),
          norma: _texto(enc['norma']).isEmpty
              ? 'ISO 14001:2015'
              : _texto(enc['norma']),
          elementos: _texto(enc['elementos']),
          documentos: _texto(enc['documentos']),
          auditor: _texto(enc['auditor']),
          fecha: enc['fecha'] is String
              ? DateTime.tryParse(enc['fecha'] as String)
              : null,
        )
      : const Encabezado();

  final respuestas = <String, RespuestaPregunta>{};
  final rs = json['respuestas'];
  if (rs is Map) {
    for (final e in rs.entries) {
      final v = e.value;
      if (e.key is! String || v is! Map) continue;
      final r = switch (v['r']) {
        'cumple' => Respuesta.cumple,
        'noCumple' => Respuesta.noCumple,
        _ => null, // valor desconocido = sin responder
      };
      final rp = RespuestaPregunta(respuesta: r, nota: _texto(v['n']));
      if (!rp.vacia) respuestas[e.key as String] = rp;
    }
  }

  final hallazgos = <Hallazgo>[];
  final hs = json['hallazgos'];
  if (hs is List) {
    for (final h in hs) {
      if (h is! Map) continue;
      hallazgos.add(Hallazgo(
        texto: _texto(h['texto']),
        requisito: _texto(h['requisito']),
        evidencia: _texto(h['evidencia']),
      ));
    }
  }

  return Auditoria(
    id: id,
    creada: creada,
    actualizada: actualizada,
    encabezado: encabezado,
    respuestas: Map.unmodifiable(respuestas),
    hallazgos: List.unmodifiable(hallazgos),
  );
}

String _texto(Object? v) => v is String ? v : '';

DateTime _fechaObligatoria(Object? v, String nombre) {
  final d = v is String ? DateTime.tryParse(v) : null;
  if (d == null) throw FormatException('Fecha inválida en "$nombre".');
  return d;
}

/// Identificador nuevo: letra + tiempo en base 36 + 3 caracteres al azar.
/// Siempre cumple [idValido], así que sirve como nombre de archivo.
String generarId(DateTime ahora, [int? azar]) {
  final r = azar ?? Random().nextInt(46656); // 36 * 36 * 36
  return 'a${ahora.microsecondsSinceEpoch.toRadixString(36)}'
      '${r.toRadixString(36).padLeft(3, '0')}';
}
