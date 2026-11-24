import 'package:auditoria_core/auditoria_core.dart';
import 'package:flutter/material.dart';

import 'ui/pantalla_lista.dart';

class AplicacionAuditoria extends StatelessWidget {
  const AplicacionAuditoria({
    super.key,
    required this.catalogo,
    required this.repositorio,
  });

  final Catalogo catalogo;
  final RepositorioAuditorias repositorio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auditoría ISO 14001',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B7F5C)),
      ),
      home: PantallaLista(catalogo: catalogo, repositorio: repositorio),
    );
  }
}

class PantallaErrorArranque extends StatelessWidget {
  const PantallaErrorArranque({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No se pudo iniciar la app.\n\n$mensaje',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
