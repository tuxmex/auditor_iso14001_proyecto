import 'package:auditoria_core/auditoria_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../infra/pdf_reporte.dart';

class TabReporte extends StatelessWidget {
  const TabReporte({super.key, required this.sesion});

  final SesionAuditoria sesion;

  Future<void> _conAviso(BuildContext context, Future<void> Function() accion) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await accion();
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text('No se pudo completar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumen = sesion.resumen;
    final problemas = sesion.problemas;
    final global = resumen.porcentaje;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(global == null ? '— %' : '${global.toStringAsFixed(0)} %',
                    style: Theme.of(context).textTheme.displaySmall),
                const Text('de cumplimiento (sobre lo respondido)'),
                const SizedBox(height: 8),
                Text('${resumen.cumple} Sí · ${resumen.noCumple} No · ${resumen.pendientes} sin responder'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final c in resumen.clausulas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c.numero} ${c.titulo}  ·  '
                    '${c.porcentaje == null ? 'sin datos' : '${c.porcentaje!.toStringAsFixed(0)} %'}'),
                LinearProgressIndicator(value: (c.porcentaje ?? 0) / 100, minHeight: 6),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (problemas.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.verified_outlined),
              title: Text('Listo para emitir'),
              subtitle: Text('El reporte no llevará la marca de borrador.'),
            ),
          )
        else
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.pending_actions, color: Theme.of(context).colorScheme.error),
              title: Text('Faltan ${problemas.length} punto(s) para emitir'),
              subtitle: const Text('Hasta entonces el reporte sale como borrador.'),
              children: [for (final p in problemas) ListTile(dense: true, title: Text(p.mensaje))],
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Compartir PDF'),
          onPressed: () => _conAviso(context, () async {
            await compartirPdf(sesion.catalogo, sesion.auditoria);
          }),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.print),
          label: const Text('Imprimir o guardar como PDF'),
          onPressed: () => _conAviso(context, () => imprimirPdf(sesion.catalogo, sesion.auditoria)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.article_outlined),
          label: const Text('Ver reporte de texto'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Reporte'),
              content: SingleChildScrollView(
                child: SelectableText(
                  sesion.reporteTexto,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: sesion.reporteTexto));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Copiar'),
                ),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
