import 'package:auditoria_core/auditoria_core.dart';
import 'package:flutter/material.dart';

import 'pantalla_auditoria.dart';

/// Pantalla de inicio: las auditorías guardadas en el dispositivo.
class PantallaLista extends StatefulWidget {
  const PantallaLista({
    super.key,
    required this.catalogo,
    required this.repositorio,
  });

  final Catalogo catalogo;
  final RepositorioAuditorias repositorio;

  @override
  State<PantallaLista> createState() => _PantallaListaState();
}

class _PantallaListaState extends State<PantallaLista> {
  late Future<Listado> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.repositorio.listar();
  }

  void _recargar() => setState(() => _futuro = widget.repositorio.listar());

  Future<void> _abrir(Auditoria auditoria) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PantallaAuditoria(
        catalogo: widget.catalogo,
        repositorio: widget.repositorio,
        inicial: auditoria,
      ),
    ));
    if (mounted) _recargar();
  }

  Future<void> _nueva() => _abrir(
      Auditoria.nueva(id: generarId(DateTime.now()), ahora: DateTime.now()));

  Future<void> _abrirExistente(String id) async {
    try {
      final a = await widget.repositorio.cargar(id);
      if (a == null || !mounted) return;
      await _abrir(a);
    } on ArchivoCorrupto catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<bool> _confirmarBorrado(ResumenAuditoria r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar auditoría?'),
        content: Text(
            'Se borrará "${r.area.isEmpty ? 'Sin área' : r.area}" de este dispositivo. No se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Borrar')),
        ],
      ),
    );
    if (ok == true) await widget.repositorio.borrar(r.id);
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auditorías ISO 14001')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nueva,
        icon: const Icon(Icons.add),
        label: const Text('Nueva auditoría'),
      ),
      body: FutureBuilder<Listado>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('No se pudo leer el almacenamiento: ${snap.error}'));
          }
          final listado = snap.data!;
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (listado.corruptos.isNotEmpty)
                _Aviso(
                    'Se apartaron ${listado.corruptos.length} archivo(s) dañado(s) '
                    '(terminan en .corrupto).'),
              if (listado.noSoportados.isNotEmpty)
                _Aviso(
                    '${listado.noSoportados.length} archivo(s) vienen de una versión '
                    'más nueva de la app y no se pueden abrir.'),
              if (listado.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Todavía no hay auditorías.\nToca "Nueva auditoría" para empezar. '
                    'Todo se guarda solo en este dispositivo.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final r in listado.items)
                Dismissible(
                  key: ValueKey(r.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmarBorrado(r),
                  onDismissed: (_) => _recargar(),
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(r.area.isEmpty ? 'Sin área' : r.area),
                    subtitle: Text(
                        '${r.auditor.isEmpty ? 'Sin auditor' : r.auditor} · '
                        '${r.respondidas} respuestas · ${formatoFecha(r.actualizada.toLocal())}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrirExistente(r.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      margin: const EdgeInsets.all(12),
      child: Padding(padding: const EdgeInsets.all(12), child: Text(texto)),
    );
  }
}
