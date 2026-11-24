# auditoria_core

Lógica pura de Dart (sin Flutter) de la lista de verificación ISO 14001 (formato F-OSC-39):
catálogo, modelo, cálculo de cumplimiento, validación para emitir el reporte, serialización,
repositorio en archivos JSON, sesión con guardado fusionado y reporte de texto.

```bash
cd core
dart pub get
dart test
```

Las pruebas leen el catálogo real desde `../app/assets/catalogo_iso14001.json`.
Usa `dart:io`, así que es para Android, iOS y escritorio (no para web).
