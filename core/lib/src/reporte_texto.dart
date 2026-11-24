import 'catalogo.dart';
import 'evaluacion.dart';
import 'modelo.dart';

String formatoFecha(DateTime? f) {
  if (f == null) return '__/__/____';
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(f.day)}/${dos(f.month)}/${f.year}';
}

String _pct(double? p) => p == null ? 'sin datos' : '${p.toStringAsFixed(0)} %';

String _sinSignos(String t) => t.replaceAll('¿', '').replaceAll('?', '');

/// Reporte de texto que sigue el orden del formato F-OSC-39.
/// Si faltan datos, se marca como BORRADOR y se listan los pendientes.
String construirReporteTexto(Catalogo catalogo, Auditoria a) {
  final e = a.encabezado;
  final resumen = calcularResumen(catalogo, a);
  final problemas = validarParaEmitir(catalogo, a);
  final b = StringBuffer();

  b.writeln('UNIVERSIDAD TECNOLÓGICA DEL NORTE DE GUANAJUATO');
  b.writeln('LISTA DE VERIFICACIÓN  (F-OSC-39)');
  if (problemas.isNotEmpty) {
    b.writeln('*** BORRADOR: faltan ${problemas.length} punto(s) por resolver ***');
  }
  b.writeln();
  b.writeln('Objetivo de la auditoría: ${e.objetivo}');
  b.writeln('Área a ser auditada: ${e.area}');
  b.writeln('Norma bajo la que se va a auditar: ${e.norma}');
  b.writeln('Elementos a ser revisados en el área: ${e.elementos}');
  b.writeln('Documentos de referencia para la auditoría: ${e.documentos}');
  b.writeln();

  b.writeln('RESUMEN');
  b.writeln(
      'Cumplimiento global: ${_pct(resumen.porcentaje)} '
      '(${resumen.cumple} Sí, ${resumen.noCumple} No, ${resumen.pendientes} sin responder)');
  for (final c in resumen.clausulas) {
    b.writeln('  ${c.numero} ${c.titulo}: ${_pct(c.porcentaje)}'
        '  [${c.cumple} Sí / ${c.noCumple} No / ${c.pendientes} pendientes]');
  }
  b.writeln();

  b.writeln('LISTA DE VERIFICACIÓN');
  for (final c in catalogo.clausulas) {
    b.writeln();
    b.writeln('${c.numero} ${c.titulo}');
    for (final p in c.preguntas) {
      final r = a.respuestaDe(p.id);
      final marca = switch (r.respuesta) {
        Respuesta.cumple => 'Sí',
        Respuesta.noCumple => 'No',
        null => '--',
      };
      b.writeln('  ${p.id}  [$marca]  ${_sinSignos(p.texto)}');
      if (r.nota.trim().isNotEmpty) b.writeln('        Nota: ${r.nota.trim()}');
    }
  }
  b.writeln();

  b.writeln('REDACCIÓN DE HALLAZGOS');
  if (a.hallazgos.isEmpty) {
    b.writeln('  (sin hallazgos)');
  } else {
    for (var i = 0; i < a.hallazgos.length; i++) {
      final h = a.hallazgos[i];
      b.writeln('${i + 1}. Requisito evaluado: ${h.requisito}');
      b.writeln('   Hallazgo: ${h.texto}');
      b.writeln('   Evidencia: ${h.evidencia}');
    }
  }
  b.writeln();

  if (problemas.isNotEmpty) {
    b.writeln('PENDIENTES PARA EMITIR EL REPORTE FINAL');
    for (final p in problemas) {
      b.writeln('  - ${p.mensaje}');
    }
    b.writeln();
  }

  b.writeln('Auditor: ${e.auditor}     Firma: ____________     Fecha: ${formatoFecha(e.fecha)}');
  b.writeln('Rev. 4: 30/noviembre/2017');
  return b.toString();
}

/// Nombre de archivo para compartir el reporte: sin espacios ni acentos
/// ni caracteres que den problemas en algún sistema de archivos.
String nombreArchivoReporte(Auditoria a) {
  final f = a.encabezado.fecha ?? a.actualizada;
  String dos(int n) => n.toString().padLeft(2, '0');
  const acentos = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N',
  };
  final area = a.encabezado.area
      .split('')
      .map((c) => acentos[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final parteArea = area.isEmpty ? 'sin_area' : area;
  return 'F-OSC-39_${parteArea}_${f.year}${dos(f.month)}${dos(f.day)}.pdf';
}
