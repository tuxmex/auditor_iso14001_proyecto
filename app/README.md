# auditoria_iso14001 (app Flutter)

1. Genera las carpetas de plataforma sin tocar tu código:

   ```bash
   cd app
   flutter create --platforms=android,ios --project-name auditoria_iso14001 .
   ```

   Revisa que `lib/main.dart` siga siendo el de este proyecto (si el comando lo reemplazó,
   restáuralo del zip) y que `pubspec.yaml` conserve `auditoria_core` y los assets.

2. Instala y prueba:

   ```bash
   flutter pub get
   flutter test
   flutter run
   ```

El catálogo de preguntas está en `assets/catalogo_iso14001.json`. Se valida desde `../tools`:

```bash
cd ../tools && node --test && node validar_catalogo.js
```
