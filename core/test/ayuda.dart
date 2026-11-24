import 'dart:convert';
import 'dart:io';

import 'package:auditoria_core/auditoria_core.dart';

/// Catálogo pequeño para las pruebas: 2 cláusulas, 2 y 3 preguntas.
Catalogo catalogoPrueba() => Catalogo.desdeJson({
      'version': 1,
      'norma': 'ISO 14001:2015',
      'formato': 'F-OSC-39',
      'clausulas': [
        {
          'numero': '4.1',
          'titulo': 'Contexto',
          'proposito': 'p',
          'preguntas': [
            {'id': '4.1-1', 'texto': '¿Uno?', 'evidencia': 'e'},
            {'id': '4.1-2', 'texto': '¿Dos?', 'evidencia': 'e'},
          ],
        },
        {
          'numero': '6.1.2',
          'titulo': 'Aspectos',
          'proposito': 'p',
          'preguntas': [
            {'id': '6.1.2-1', 'texto': '¿Tres?', 'evidencia': 'e'},
            {'id': '6.1.2-2', 'texto': '¿Cuatro?', 'evidencia': 'e'},
            {'id': '6.1.2-3', 'texto': '¿Cinco?', 'evidencia': 'e'},
          ],
        },
      ],
    });

/// El catálogo real de la app (la fuente única está en app/assets).
Catalogo catalogoReal() {
  final texto = File('../app/assets/catalogo_iso14001.json').readAsStringSync();
  return Catalogo.desdeJson(jsonDecode(texto));
}

final DateTime t0 = DateTime.utc(2026, 11, 20, 10);

Auditoria nueva([String id = 'a1']) => Auditoria.nueva(id: id, ahora: t0);

/// Auditoría con todo completo y válida para el catálogo de prueba.
Auditoria completa() {
  var a = nueva();
  a = a.copyWith(
    encabezado: Encabezado(
      objetivo: 'Evaluar el área',
      area: 'Laboratorio',
      auditor: 'Tacho',
      fecha: DateTime(2026, 11, 20),
    ),
  );
  for (final id in ['4.1-1', '4.1-2', '6.1.2-1', '6.1.2-2', '6.1.2-3']) {
    a = a.responder(id, Respuesta.cumple);
  }
  return a;
}
