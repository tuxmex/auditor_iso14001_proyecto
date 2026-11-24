import 'catalogo.dart';
import 'modelo.dart';

class ResumenClausula {
  const ResumenClausula({
    required this.numero,
    required this.titulo,
    required this.total,
    required this.cumple,
    required this.noCumple,
  });

  final String numero;
  final String titulo;
  final int total;
  final int cumple;
  final int noCumple;

  int get pendientes => total - cumple - noCumple;
  int get respondidas => cumple + noCumple;

  /// Porcentaje de "Sí" entre las preguntas ya respondidas.
  /// Null si todavía no se respondió ninguna (no es lo mismo que 0 %).
  double? get porcentaje => respondidas == 0 ? null : cumple * 100 / respondidas;
}

class ResumenGlobal {
  const ResumenGlobal(this.clausulas);

  final List<ResumenClausula> clausulas;

  int get total => clausulas.fold(0, (s, c) => s + c.total);
  int get cumple => clausulas.fold(0, (s, c) => s + c.cumple);
  int get noCumple => clausulas.fold(0, (s, c) => s + c.noCumple);
  int get respondidas => cumple + noCumple;
  int get pendientes => total - respondidas;
  double? get porcentaje => respondidas == 0 ? null : cumple * 100 / respondidas;

  /// Avance de la captura entre 0 y 1.
  double get avance => total == 0 ? 0 : respondidas / total;
}

/// Las respuestas a preguntas que ya no existen en el catálogo se ignoran.
ResumenGlobal calcularResumen(Catalogo catalogo, Auditoria auditoria) {
  final lista = <ResumenClausula>[];
  for (final c in catalogo.clausulas) {
    var si = 0;
    var no = 0;
    for (final p in c.preguntas) {
      switch (auditoria.respuestaDe(p.id).respuesta) {
        case Respuesta.cumple:
          si++;
        case Respuesta.noCumple:
          no++;
        case null:
          break;
      }
    }
    lista.add(ResumenClausula(
      numero: c.numero,
      titulo: c.titulo,
      total: c.preguntas.length,
      cumple: si,
      noCumple: no,
    ));
  }
  return ResumenGlobal(lista);
}

enum TipoProblema {
  encabezado,
  sinResponder,
  noSinNota,
  noSinHallazgo,
  hallazgoIncompleto,
  hallazgoRequisitoInvalido,
}

class Problema {
  const Problema(this.tipo, this.mensaje, {this.referencia});

  final TipoProblema tipo;
  final String mensaje;

  /// Id de pregunta, número de cláusula o número de hallazgo, según el tipo.
  final String? referencia;
}

/// Lista de lo que falta para poder emitir el reporte final.
/// Vacía = el reporte puede emitirse sin la marca de BORRADOR.
List<Problema> validarParaEmitir(Catalogo catalogo, Auditoria a) {
  final problemas = <Problema>[];
  final e = a.encabezado;

  void exige(String valor, String nombre) {
    if (valor.trim().isEmpty) {
      problemas.add(Problema(TipoProblema.encabezado, 'Falta: $nombre.',
          referencia: nombre));
    }
  }

  exige(e.objetivo, 'objetivo de la auditoría');
  exige(e.area, 'área a ser auditada');
  exige(e.auditor, 'nombre del auditor');
  if (e.fecha == null) {
    problemas.add(const Problema(TipoProblema.encabezado, 'Falta: fecha.',
        referencia: 'fecha'));
  }

  final clausulasConNo = <String>{};
  for (final p in catalogo.todasLasPreguntas) {
    final r = a.respuestaDe(p.id);
    if (r.respuesta == null) {
      problemas.add(Problema(
          TipoProblema.sinResponder, 'Sin responder: ${p.id}.',
          referencia: p.id));
    } else if (r.respuesta == Respuesta.noCumple) {
      clausulasConNo.add(p.clausula);
      if (r.nota.trim().isEmpty) {
        problemas.add(Problema(TipoProblema.noSinNota,
            'La respuesta "No" de ${p.id} necesita una nota que explique por qué.',
            referencia: p.id));
      }
    }
  }

  for (var i = 0; i < a.hallazgos.length; i++) {
    final h = a.hallazgos[i];
    final n = i + 1;
    if (catalogo.clausula(h.requisito) == null) {
      problemas.add(Problema(TipoProblema.hallazgoRequisitoInvalido,
          'El hallazgo $n cita un requisito que no existe: "${h.requisito}".',
          referencia: '$n'));
    }
    if (h.texto.trim().isEmpty || h.evidencia.trim().isEmpty) {
      problemas.add(Problema(TipoProblema.hallazgoIncompleto,
          'El hallazgo $n está incompleto: necesita redacción y evidencia.',
          referencia: '$n'));
    }
  }

  final citadas = a.hallazgos.map((h) => h.requisito).toSet();
  for (final c in catalogo.clausulas) {
    if (clausulasConNo.contains(c.numero) && !citadas.contains(c.numero)) {
      problemas.add(Problema(TipoProblema.noSinHallazgo,
          'La cláusula ${c.numero} tiene respuestas "No" pero ningún hallazgo que la cite.',
          referencia: c.numero));
    }
  }
  return problemas;
}

/// Borradores de hallazgo para cada cláusula con respuestas "No" que aún no
/// tiene un hallazgo que la cite. La evidencia queda vacía a propósito: la
/// tiene que escribir quien audita.
List<Hallazgo> sugerirHallazgos(Catalogo catalogo, Auditoria a) {
  final citadas = a.hallazgos.map((h) => h.requisito).toSet();
  final sugeridos = <Hallazgo>[];
  for (final c in catalogo.clausulas) {
    if (citadas.contains(c.numero)) continue;
    final lineas = <String>[];
    for (final p in c.preguntas) {
      final r = a.respuestaDe(p.id);
      if (r.respuesta != Respuesta.noCumple) continue;
      final nota = r.nota.trim();
      lineas.add(nota.isEmpty ? '- ${p.texto}' : '- ${p.texto}\n  Nota: $nota');
    }
    if (lineas.isEmpty) continue;
    sugeridos.add(Hallazgo(
      texto:
          'No se cumple lo siguiente en la cláusula ${c.etiqueta}:\n${lineas.join('\n')}',
      requisito: c.numero,
    ));
  }
  return sugeridos;
}
