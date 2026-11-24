/// Catálogo de cláusulas y preguntas. Vive en un JSON (assets/catalogo_iso14001.json)
/// para que el docente pueda cambiar preguntas sin tocar el código.

class Pregunta {
  const Pregunta({
    required this.id,
    required this.clausula,
    required this.texto,
    required this.evidencia,
  });

  final String id; // por ejemplo "6.1.2-3"
  final String clausula; // por ejemplo "6.1.2"
  final String texto;
  final String evidencia; // evidencia sugerida
}

class Clausula {
  const Clausula({
    required this.numero,
    required this.titulo,
    required this.proposito,
    required this.preguntas,
  });

  final String numero;
  final String titulo;
  final String proposito;
  final List<Pregunta> preguntas;

  String get etiqueta => '$numero $titulo';
}

class Catalogo {
  Catalogo({
    required this.norma,
    required this.formato,
    required List<Clausula> clausulas,
  }) : clausulas = List.unmodifiable(clausulas) {
    for (final c in this.clausulas) {
      _clausulaPorNumero[c.numero] = c;
      for (final p in c.preguntas) {
        _preguntaPorId[p.id] = p;
      }
    }
  }

  final String norma;
  final String formato;
  final List<Clausula> clausulas;

  final Map<String, Clausula> _clausulaPorNumero = {};
  final Map<String, Pregunta> _preguntaPorId = {};

  Clausula? clausula(String numero) => _clausulaPorNumero[numero];
  Pregunta? pregunta(String id) => _preguntaPorId[id];

  Iterable<Pregunta> get todasLasPreguntas sync* {
    for (final c in clausulas) {
      yield* c.preguntas;
    }
  }

  int get totalPreguntas => _preguntaPorId.length;

  /// Lee el catálogo desde el JSON ya decodificado. Lanza [FormatException]
  /// con un mensaje claro si algo no cuadra (un catálogo malo debe fallar al
  /// arrancar, no a media auditoría).
  factory Catalogo.desdeJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('El catálogo debe ser un objeto JSON.');
    }
    final norma = _texto(json, 'norma', 'catálogo');
    final formato = json['formato'] is String ? json['formato'] as String : '';
    final lista = json['clausulas'];
    if (lista is! List || lista.isEmpty) {
      throw const FormatException('El catálogo no tiene la lista "clausulas".');
    }
    final clausulas = <Clausula>[];
    final numeros = <String>{};
    final ids = <String>{};
    for (final item in lista) {
      if (item is! Map) {
        throw const FormatException('Una cláusula no es un objeto.');
      }
      final numero = _texto(item, 'numero', 'cláusula');
      if (!numeros.add(numero)) {
        throw FormatException('Cláusula repetida: $numero');
      }
      final titulo = _texto(item, 'titulo', 'cláusula $numero');
      final proposito = _texto(item, 'proposito', 'cláusula $numero');
      final lp = item['preguntas'];
      if (lp is! List || lp.isEmpty) {
        throw FormatException('La cláusula $numero no tiene preguntas.');
      }
      final preguntas = <Pregunta>[];
      for (final q in lp) {
        if (q is! Map) {
          throw FormatException('Una pregunta de $numero no es un objeto.');
        }
        final id = _texto(q, 'id', 'pregunta de $numero');
        if (!ids.add(id)) throw FormatException('Id repetido: $id');
        preguntas.add(Pregunta(
          id: id,
          clausula: numero,
          texto: _texto(q, 'texto', 'pregunta $id'),
          evidencia: _texto(q, 'evidencia', 'pregunta $id'),
        ));
      }
      clausulas.add(Clausula(
        numero: numero,
        titulo: titulo,
        proposito: proposito,
        preguntas: preguntas,
      ));
    }
    return Catalogo(norma: norma, formato: formato, clausulas: clausulas);
  }

  static String _texto(Map m, String clave, String contexto) {
    final v = m[clave];
    if (v is! String || v.trim().isEmpty) {
      throw FormatException('Falta "$clave" en $contexto.');
    }
    return v.trim();
  }
}
