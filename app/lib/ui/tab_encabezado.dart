import 'package:auditoria_core/auditoria_core.dart';
import 'package:flutter/material.dart';

class TabEncabezado extends StatelessWidget {
  const TabEncabezado({super.key, required this.sesion});

  final SesionAuditoria sesion;

  @override
  Widget build(BuildContext context) {
    final e = sesion.auditoria.encabezado;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Campo(
          clave: 'objetivo',
          etiqueta: 'Objetivo de la auditoría',
          valor: e.objetivo,
          lineas: 3,
          alCambiar: (t) => sesion.actualizarEncabezado((x) => x.copyWith(objetivo: t)),
        ),
        _Campo(
          clave: 'area',
          etiqueta: 'Área a ser auditada',
          valor: e.area,
          alCambiar: (t) => sesion.actualizarEncabezado((x) => x.copyWith(area: t)),
        ),
        _Campo(
          clave: 'norma',
          etiqueta: 'Norma bajo la que se va a auditar',
          valor: e.norma,
          alCambiar: (t) => sesion.actualizarEncabezado((x) => x.copyWith(norma: t)),
        ),
        _Campo(
          clave: 'elementos',
          etiqueta: 'Elementos a ser revisados en el área',
          valor: e.elementos,
          lineas: 3,
          alCambiar: (t) => sesion.actualizarEncabezado((x) => x.copyWith(elementos: t)),
        ),
        _Campo(
          clave: 'documentos',
          etiqueta: 'Documentos de referencia para la auditoría',
          valor: e.documentos,
          lineas: 3,
          alCambiar: (t) => sesion.actualizarEncabezado((x) => x.copyWith(documentos: t)),
        ),
        _Campo(
          clave: 'auditor',
          etiqueta: 'Auditor',
          valor: e.auditor,
          alCambiar: (t) => sesion.actualizarEncabezado((x) => x.copyWith(auditor: t)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event),
          title: const Text('Fecha de la auditoría'),
          subtitle: Text(formatoFecha(e.fecha)),
          trailing: const Icon(Icons.edit_calendar),
          onTap: () async {
            final elegida = await showDatePicker(
              context: context,
              initialDate: e.fecha ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (elegida != null) {
              sesion.actualizarEncabezado((x) => x.copyWith(fecha: elegida));
            }
          },
        ),
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.clave,
    required this.etiqueta,
    required this.valor,
    required this.alCambiar,
    this.lineas = 1,
  });

  final String clave;
  final String etiqueta;
  final String valor;
  final int lineas;
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey('campo-$clave'),
        initialValue: valor,
        minLines: lineas,
        maxLines: lineas == 1 ? 1 : lineas + 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
        ),
        onChanged: alCambiar,
      ),
    );
  }
}
