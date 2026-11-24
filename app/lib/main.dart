import 'dart:convert';
import 'dart:io';

import 'package:auditoria_core/auditoria_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final texto = await rootBundle.loadString('assets/catalogo_iso14001.json');
    final catalogo = Catalogo.desdeJson(jsonDecode(texto));
    final base = await getApplicationDocumentsDirectory();
    final repositorio = RepositorioArchivos(Directory('${base.path}/auditorias'));
    runApp(AplicacionAuditoria(catalogo: catalogo, repositorio: repositorio));
  } catch (e) {
    // Un catálogo roto debe verse como mensaje claro, no como pantalla roja.
    runApp(PantallaErrorArranque(mensaje: '$e'));
  }
}
