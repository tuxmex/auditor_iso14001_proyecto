import 'package:auditoria_core/auditoria_core.dart';
import 'package:flutter/material.dart';

import 'tab_encabezado.dart';
import 'tab_hallazgos.dart';
import 'tab_lista.dart';
import 'tab_reporte.dart';

/// Una auditoría abierta, con cuatro pestañas que siguen el orden del formato
/// F-OSC-39: encabezado, lista de verificación, hallazgos y reporte.
class PantallaAuditoria extends StatefulWidget {
  const PantallaAuditoria({
    super.key,
    required this.catalogo,
    required this.repositorio,
    required this.inicial,
  });

  final Catalogo catalogo;
  final RepositorioAuditorias repositorio;
  final Auditoria inicial;

  @override
  State<PantallaAuditoria> createState() => _PantallaAuditoriaState();
}

class _PantallaAuditoriaState extends State<PantallaAuditoria> {
  late final SesionAuditoria _sesion;

  @override
  void initState() {
    super.initState();
    _sesion = SesionAuditoria(
      catalogo: widget.catalogo,
      inicial: widget.inicial,
      repositorio: widget.repositorio,
      // El guardado termina de forma asíncrona: no redibujar si ya salimos.
      alCambiar: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _sesion.auditoria;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(a.encabezado.area.isEmpty ? 'Nueva auditoría' : a.encabezado.area),
          actions: [_EstadoGuardado(sesion: _sesion)],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Encabezado'),
              Tab(text: 'Lista'),
              Tab(text: 'Hallazgos'),
              Tab(text: 'Reporte'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TabEncabezado(sesion: _sesion),
            TabLista(sesion: _sesion),
            TabHallazgos(sesion: _sesion),
            TabReporte(sesion: _sesion),
          ],
        ),
      ),
    );
  }
}

class _EstadoGuardado extends StatelessWidget {
  const _EstadoGuardado({required this.sesion});
  final SesionAuditoria sesion;

  @override
  Widget build(BuildContext context) {
    if (sesion.ultimoError != null) {
      return IconButton(
        tooltip: 'No se pudo guardar. Toca para ver el motivo.',
        icon: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('No se pudo guardar'),
            content: Text('${sesion.ultimoError}\n\nTus cambios siguen en pantalla; se reintentará con el siguiente cambio.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Icon(
        sesion.guardando ? Icons.sync : Icons.cloud_done_outlined,
        semanticLabel: sesion.guardando ? 'Guardando' : 'Guardado en el dispositivo',
      ),
    );
  }
}
