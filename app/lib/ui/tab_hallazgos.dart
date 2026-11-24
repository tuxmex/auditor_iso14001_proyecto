import 'package:auditoria_core/auditoria_core.dart';
import 'package:flutter/material.dart';

/// "Redacción de hallazgo" del formato: número, hallazgo, requisito y evidencia.
class TabHallazgos extends StatelessWidget {
  const TabHallazgos({super.key, required this.sesion});

  final SesionAuditoria sesion;

  Future<void> _editar(BuildContext context, int? indice) async {
    final actual = indice == null ? null : sesion.auditoria.hallazgos[indice];
    final resultado = await showDialog<Hallazgo>(
      context: context,
      builder: (_) => _EditorHallazgo(catalogo: sesion.catalogo, inicial: actual),
    );
    if (resultado == null) return;
    if (indice == null) {
      sesion.agregarHallazgo(resultado);
    } else {
      sesion.editarHallazgo(indice, resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hallazgos = sesion.auditoria.hallazgos;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _editar(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Agregar hallazgo'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final n = sesion.aceptarSugerencias();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(n == 0
                        ? 'No hay cláusulas con "No" sin hallazgo.'
                        : 'Se agregaron $n borrador(es). Falta escribir la evidencia.'),
                  ));
                },
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Sugerir desde los "No"'),
              ),
            ],
          ),
        ),
        Expanded(
          child: hallazgos.isEmpty
              ? const Center(child: Text('Sin hallazgos todavía.'))
              : ListView.builder(
                  itemCount: hallazgos.length,
                  itemBuilder: (context, i) {
                    final h = hallazgos[i];
                    final incompleto = h.texto.trim().isEmpty || h.evidencia.trim().isEmpty;
                    return Card(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text('Requisito ${h.requisito}'),
                        subtitle: Text(
                          h.texto.isEmpty ? '(sin redacción)' : h.texto,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (incompleto)
                              Tooltip(
                                message: 'Falta redacción o evidencia',
                                child: Icon(Icons.warning_amber,
                                    color: Theme.of(context).colorScheme.error),
                              ),
                            IconButton(
                              tooltip: 'Quitar',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => sesion.quitarHallazgo(i),
                            ),
                          ],
                        ),
                        onTap: () => _editar(context, i),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EditorHallazgo extends StatefulWidget {
  const _EditorHallazgo({required this.catalogo, this.inicial});

  final Catalogo catalogo;
  final Hallazgo? inicial;

  @override
  State<_EditorHallazgo> createState() => _EditorHallazgoState();
}

class _EditorHallazgoState extends State<_EditorHallazgo> {
  late final TextEditingController _texto;
  late final TextEditingController _evidencia;
  late String _requisito;

  @override
  void initState() {
    super.initState();
    final h = widget.inicial;
    _texto = TextEditingController(text: h?.texto ?? '');
    _evidencia = TextEditingController(text: h?.evidencia ?? '');
    final primera = widget.catalogo.clausulas.first.numero;
    _requisito = h != null && widget.catalogo.clausula(h.requisito) != null
        ? h.requisito
        : primera;
  }

  @override
  void dispose() {
    _texto.dispose();
    _evidencia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.inicial == null ? 'Nuevo hallazgo' : 'Editar hallazgo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _requisito,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Requisito evaluado'),
              items: [
                for (final c in widget.catalogo.clausulas)
                  DropdownMenuItem(value: c.numero, child: Text(c.etiqueta, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _requisito = v ?? _requisito),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _texto,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Hallazgo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _evidencia,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Evidencia', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            Hallazgo(
              texto: _texto.text.trim(),
              requisito: _requisito,
              evidencia: _evidencia.text.trim(),
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
