/// Modelo inmutable de una auditoría (una hoja F-OSC-39 completa).

enum Respuesta { cumple, noCumple }

class Encabezado {
  const Encabezado({
    this.objetivo = '',
    this.area = '',
    this.norma = 'ISO 14001:2015',
    this.elementos = '',
    this.documentos = '',
    this.auditor = '',
    this.fecha,
  });

  final String objetivo;
  final String area;
  final String norma;
  final String elementos;
  final String documentos;
  final String auditor;
  final DateTime? fecha;

  Encabezado copyWith({
    String? objetivo,
    String? area,
    String? norma,
    String? elementos,
    String? documentos,
    String? auditor,
    DateTime? fecha,
  }) {
    return Encabezado(
      objetivo: objetivo ?? this.objetivo,
      area: area ?? this.area,
      norma: norma ?? this.norma,
      elementos: elementos ?? this.elementos,
      documentos: documentos ?? this.documentos,
      auditor: auditor ?? this.auditor,
      fecha: fecha ?? this.fecha,
    );
  }
}

class RespuestaPregunta {
  const RespuestaPregunta({this.respuesta, this.nota = ''});

  final Respuesta? respuesta; // null = sin responder
  final String nota;

  bool get vacia => respuesta == null && nota.trim().isEmpty;
}

class Hallazgo {
  const Hallazgo({
    required this.texto,
    required this.requisito,
    this.evidencia = '',
  });

  final String texto;
  final String requisito; // número de cláusula, por ejemplo "6.1.2"
  final String evidencia;

  Hallazgo copyWith({String? texto, String? requisito, String? evidencia}) {
    return Hallazgo(
      texto: texto ?? this.texto,
      requisito: requisito ?? this.requisito,
      evidencia: evidencia ?? this.evidencia,
    );
  }
}

class Auditoria {
  const Auditoria({
    required this.id,
    required this.creada,
    required this.actualizada,
    this.encabezado = const Encabezado(),
    this.respuestas = const {},
    this.hallazgos = const [],
  });

  factory Auditoria.nueva({required String id, required DateTime ahora}) {
    return Auditoria(id: id, creada: ahora, actualizada: ahora);
  }

  final String id;
  final DateTime creada;
  final DateTime actualizada;
  final Encabezado encabezado;
  final Map<String, RespuestaPregunta> respuestas;
  final List<Hallazgo> hallazgos;

  RespuestaPregunta respuestaDe(String preguntaId) =>
      respuestas[preguntaId] ?? const RespuestaPregunta();

  Auditoria copyWith({
    DateTime? actualizada,
    Encabezado? encabezado,
    Map<String, RespuestaPregunta>? respuestas,
    List<Hallazgo>? hallazgos,
  }) {
    return Auditoria(
      id: id,
      creada: creada,
      actualizada: actualizada ?? this.actualizada,
      encabezado: encabezado ?? this.encabezado,
      respuestas: respuestas ?? this.respuestas,
      hallazgos: hallazgos ?? this.hallazgos,
    );
  }

  /// Marca Sí/No. Con null quita la respuesta y conserva la nota.
  Auditoria responder(String preguntaId, Respuesta? valor) {
    final actual = respuestaDe(preguntaId);
    return _conRespuesta(
        preguntaId, RespuestaPregunta(respuesta: valor, nota: actual.nota));
  }

  Auditoria conNota(String preguntaId, String nota) {
    final actual = respuestaDe(preguntaId);
    return _conRespuesta(
        preguntaId, RespuestaPregunta(respuesta: actual.respuesta, nota: nota));
  }

  Auditoria _conRespuesta(String preguntaId, RespuestaPregunta r) {
    final nuevo = Map<String, RespuestaPregunta>.of(respuestas);
    if (r.vacia) {
      nuevo.remove(preguntaId);
    } else {
      nuevo[preguntaId] = r;
    }
    return copyWith(respuestas: Map.unmodifiable(nuevo));
  }
}
