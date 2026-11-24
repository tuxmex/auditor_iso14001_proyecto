import 'package:auditoria_core/auditoria_core.dart';
import 'package:flutter/material.dart';

/// La tabla del formato: pregunta, requisito, Sí / No y nota.
class TabLista extends StatelessWidget {
  const TabLista({super.key, required this.sesion});

  final SesionAuditoria sesion;

  @override
  Widget build(BuildContext context) {
    final resumen = sesion.resumen;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${resumen.respondidas} de ${resumen.total} preguntas respondidas'),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: resumen.avance, minHeight: 8),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final c in sesion.catalogo.clausulas)
                _TarjetaClausula(
                  key: PageStorageKey<String>('clausula-${c.numero}'),
                  clausula: c,
                  resumen: resumen.clausulas.firstWhere((r) => r.numero == c.numero),
                  sesion: sesion,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaClausula extends StatelessWidget {
  const _TarjetaClausula({
    super.key,
    required this.clausula,
    required this.resumen,
    required this.sesion,
  });

  final Clausula clausula;
  final ResumenClausula resumen;
  final SesionAuditoria sesion;

  @override
  Widget build(BuildContext context) {
    final p = resumen.porcentaje;
    return ExpansionTile(
      title: Text(clausula.etiqueta),
      subtitle: Text(
          '${resumen.respondidas}/${resumen.total} respondidas'
          '${p == null ? '' : ' · ${p.toStringAsFixed(0)} % Sí'}'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(clausula.proposito,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        for (final pregunta in clausula.preguntas)
          _FilaPregunta(
            key: ValueKey(pregunta.id),
            pregunta: pregunta,
            respuesta: sesion.auditoria.respuestaDe(pregunta.id),
            sesion: sesion,
          ),
      ],
    );
  }
}

class _FilaPregunta extends StatelessWidget {
  const _FilaPregunta({
    super.key,
    required this.pregunta,
    required this.respuesta,
    required this.sesion,
  });

  final Pregunta pregunta;
  final RespuestaPregunta respuesta;
  final SesionAuditoria sesion;

  @override
  Widget build(BuildContext context) {
    final r = respuesta.respuesta;
    final faltaNota = r == Respuesta.noCumple && respuesta.nota.trim().isEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pregunta.id}  ${pregunta.texto}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Evidencia sugerida: ${pregunta.evidencia}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            SegmentedButton<Respuesta>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: Respuesta.cumple, label: Text('Sí')),
                ButtonSegment(value: Respuesta.noCumple, label: Text('No')),
              ],
              selected: r == null ? <Respuesta>{} : {r},
              onSelectionChanged: (s) =>
                  sesion.responder(pregunta.id, s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: PageStorageKey<String>('nota-${pregunta.id}'),   // ← agregar esta línea
              initialValue: respuesta.nota,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nota / Comentario',
                border: const OutlineInputBorder(),
                errorText: faltaNota ? 'Explica por qué no cumple' : null,
              ),
              onChanged: (t) => sesion.nota(pregunta.id, t),
            ),
          ],
        ),
      ),
    );
  }
}
