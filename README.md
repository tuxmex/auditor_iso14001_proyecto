# Auditoría ISO 14001 (UTNG) — lista de verificación F-OSC-39

Aplicación Flutter para auditar cualquier área de la UTNG con 13 cláusulas de ISO 14001:2015
(4.1, 4.2, 5.2, 5.3, 6.1, 6.1.2, 6.2, 7.3, 7.4, 7.5, 8.1, 9.1 y 10.3), con persistencia en el
dispositivo y reporte (PDF y texto) que sigue el orden del formato F-OSC-39 Rev. 4.

- `core/`  Paquete Dart puro (sin Flutter): catálogo, modelo, cálculo, validación, serialización,
           repositorio en archivos, sesión con guardado fusionado y reporte de texto. 61 pruebas.
- `app/`   Aplicación Flutter (pantallas y PDF) y el catálogo de preguntas en JSON (58 preguntas).
- `tools/` Validador del catálogo en Node (11 pruebas).

## Cómo probarlo
    cd tools && node --test && node validar_catalogo.js
    cd ../core && dart pub get && dart test
    cd ../app && flutter create --platforms=android,ios --project-name auditoria_iso14001 . \
      && flutter pub get && flutter test && flutter run

Las pruebas del núcleo leen el catálogo real desde `app/assets/catalogo_iso14001.json`.

## Importante
- Las preguntas son redacción propia del curso, basadas en la estructura de la norma; no sustituyen el
  texto de ISO 14001:2015 ni su Enmienda 1:2024. Consulta tu copia licenciada al auditar.
- Estado de verificación: núcleo y herramientas ejecutados; pantallas Flutter y PDF no se ejecutaron
  en el entorno donde se escribió (sin Flutter). Corre `flutter test` y prueba en un teléfono real.
- El logotipo de la UTNG no se incluye: agrégalo como asset si tienes permiso de uso.
