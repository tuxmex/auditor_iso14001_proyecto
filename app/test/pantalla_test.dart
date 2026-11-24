import 'package:auditoria_core/auditoria_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auditoria_iso14001/ui/pantalla_auditoria.dart';

Catalogo _catalogo() => Catalogo.desdeJson({
      'norma': 'ISO 14001:2015',
      'clausulas': [
        {
          'numero': '4.1',
          'titulo': 'Contexto',
          'proposito': 'p',
          'preguntas': [
            {'id': '4.1-1', 'texto': '¿Primera pregunta?', 'evidencia': 'e'},
          ],
        },
      ],
    });

void main() {
  testWidgets('responder Sí guarda en el repositorio', (tester) async {
    final repo = RepositorioMemoria();
    await tester.pumpWidget(MaterialApp(
      home: PantallaAuditoria(
        catalogo: _catalogo(),
        repositorio: repo,
        inicial: Auditoria.nueva(id: 'a1', ahora: DateTime.utc(2026, 11, 20)),
      ),
    ));

    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4.1 Contexto'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Primera pregunta'), findsOneWidget);

    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();

    expect(repo.almacen['a1']!.respuestaDe('4.1-1').respuesta, Respuesta.cumple);
  });

  testWidgets('marcar No sin nota muestra el aviso de que falta explicar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PantallaAuditoria(
        catalogo: _catalogo(),
        repositorio: RepositorioMemoria(),
        inicial: Auditoria.nueva(id: 'a1', ahora: DateTime.utc(2026, 11, 20)),
      ),
    ));
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4.1 Contexto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.text('Explica por qué no cumple'), findsOneWidget);
  });

  testWidgets('la pestaña Reporte avisa cuántos puntos faltan', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PantallaAuditoria(
        catalogo: _catalogo(),
        repositorio: RepositorioMemoria(),
        inicial: Auditoria.nueva(id: 'a1', ahora: DateTime.utc(2026, 11, 20)),
      ),
    ));
    await tester.tap(find.text('Reporte'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Faltan'), findsOneWidget);
  });
}
