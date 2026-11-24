import 'dart:typed_data';

import 'package:auditoria_core/auditoria_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Genera un PDF con la estructura del formato F-OSC-39.
/// Usa las fuentes estándar del PDF (Helvetica): cubre acentos y ñ.
Future<Uint8List> construirPdf(Catalogo catalogo, Auditoria a) async {
  final e = a.encabezado;
  final problemas = validarParaEmitir(catalogo, a);
  final resumen = calcularResumen(catalogo, a);

  pw.Widget texto(String t, {bool negrita = false, double tam = 8}) => pw.Text(
        t,
        style: pw.TextStyle(
          fontSize: tam,
          fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      );

  pw.Widget celda(String t, {bool negrita = false}) =>
      pw.Padding(padding: const pw.EdgeInsets.all(3), child: texto(t, negrita: negrita));

  pw.Widget campo(String etiqueta, String valor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.RichText(
          text: pw.TextSpan(
            style: const pw.TextStyle(fontSize: 9),
            children: [
              pw.TextSpan(text: '$etiqueta: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: valor),
            ],
          ),
        ),
      );

  String marca(Respuesta? r) => switch (r) {
        Respuesta.cumple => '[X] Sí   [  ] No',
        Respuesta.noCumple => '[  ] Sí   [X] No',
        null => '[  ] Sí   [  ] No',
      };

  final filasPreguntas = <pw.TableRow>[
    pw.TableRow(
      repeat: true,
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        celda('No.', negrita: true),
        celda('Pregunta', negrita: true),
        celda('Requisito a evaluar', negrita: true),
        celda('Cumple con requisito', negrita: true),
        celda('Nota / Comentario', negrita: true),
      ],
    ),
    for (final c in catalogo.clausulas)
      for (final p in c.preguntas)
        pw.TableRow(
          children: [
            celda(p.id),
            celda(p.texto),
            celda('${a.encabezado.norma}, ${c.numero}'),
            celda(marca(a.respuestaDe(p.id).respuesta)),
            celda(a.respuestaDe(p.id).nota),
          ],
        ),
  ];

  final filasHallazgos = <pw.TableRow>[
    pw.TableRow(
      repeat: true,
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        celda('No.', negrita: true),
        celda('Hallazgo', negrita: true),
        celda('Requisito evaluado', negrita: true),
        celda('Evidencia', negrita: true),
      ],
    ),
    for (var i = 0; i < a.hallazgos.length; i++)
      pw.TableRow(
        children: [
          celda('${i + 1}'),
          celda(a.hallazgos[i].texto),
          celda(a.hallazgos[i].requisito),
          celda(a.hallazgos[i].evidencia),
        ],
      ),
  ];

  String pct(double? p) => p == null ? 'sin datos' : '${p.toStringAsFixed(0)} %';

  final doc = pw.Document(
    title: 'Lista de verificación F-OSC-39',
    author: e.auditor,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Universidad Tecnológica del Norte de Guanajuato',
              style: const pw.TextStyle(fontSize: 9)),
          pw.Text('LISTA DE VERIFICACIÓN',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
        ],
      ),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          texto('Rev. 4: 30/noviembre/2017'),
          texto('F-OSC-39   Página ${ctx.pageNumber} de ${ctx.pagesCount}'),
        ],
      ),
      build: (ctx) => [
        if (problemas.isNotEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            margin: const pw.EdgeInsets.only(bottom: 8),
            color: PdfColors.yellow200,
            child: texto(
              'BORRADOR: faltan ${problemas.length} punto(s) por resolver antes de emitir el reporte final.',
              negrita: true,
              tam: 9,
            ),
          ),
        campo('Objetivo de la auditoría', e.objetivo),
        campo('Área a ser auditada', e.area),
        campo('Norma bajo la que se va a auditar', e.norma),
        campo('Elementos a ser revisados en el área', e.elementos),
        campo('Documentos de referencia para la auditoría', e.documentos),
        pw.SizedBox(height: 8),
        pw.Text('Resumen de cumplimiento: ${pct(resumen.porcentaje)}  '
            '(${resumen.cumple} Sí, ${resumen.noCumple} No, ${resumen.pendientes} sin responder)',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        for (final c in resumen.clausulas)
          texto('${c.numero} ${c.titulo}: ${pct(c.porcentaje)}'),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(34),
            1: pw.FlexColumnWidth(4),
            2: pw.FlexColumnWidth(2),
            3: pw.FixedColumnWidth(78),
            4: pw.FlexColumnWidth(2.5),
          },
          children: filasPreguntas,
        ),
        pw.SizedBox(height: 14),
        pw.Text('Redacción de hallazgo',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        if (a.hallazgos.isEmpty)
          texto('(sin hallazgos)')
        else
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(34),
              1: pw.FlexColumnWidth(5),
              2: pw.FixedColumnWidth(60),
              3: pw.FlexColumnWidth(3),
            },
            children: filasHallazgos,
          ),
        pw.SizedBox(height: 28),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            texto('Auditor: ${e.auditor.isEmpty ? '________________' : e.auditor}', tam: 9),
            texto('Firma: ______________', tam: 9),
            texto('Fecha: ${formatoFecha(e.fecha)}', tam: 9),
          ],
        ),
      ],
    ),
  );

  return doc.save();
}

/// Abre el menú de compartir del sistema con el PDF.
Future<bool> compartirPdf(Catalogo catalogo, Auditoria a) async {
  final bytes = await construirPdf(catalogo, a);
  return Printing.sharePdf(bytes: bytes, filename: nombreArchivoReporte(a));
}

/// Abre el diálogo de impresión (permite "Guardar como PDF").
Future<void> imprimirPdf(Catalogo catalogo, Auditoria a) async {
  final bytes = await construirPdf(catalogo, a);
  await Printing.layoutPdf(
    name: nombreArchivoReporte(a),
    onLayout: (_) async => bytes,
  );
}
