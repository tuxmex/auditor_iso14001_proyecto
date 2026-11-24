import 'catalogo.dart';
import 'evaluacion.dart';
import 'modelo.dart';
import 'repositorio.dart';
import 'reporte_texto.dart';

/// Una auditoría abierta: aplica cada cambio y lo guarda en el repositorio.
///
/// Los guardados se encolan y se fusionan: si el usuario teclea una nota y se
/// disparan 50 cambios mientras se escribe el disco, solo se escribe el
/// último estado. Nunca hay dos escrituras al mismo tiempo ni una vieja
/// pisando a una nueva.
class SesionAuditoria {
  SesionAuditoria({
    required this.catalogo,
    required Auditoria inicial,
    required this.repositorio,
    DateTime Function()? reloj,
    this.alCambiar,
  })  : _auditoria = inicial,
        _reloj = reloj ?? DateTime.now;

  final Catalogo catalogo;
  final RepositorioAuditorias repositorio;
  final DateTime Function() _reloj;

  /// La pantalla se redibuja cuando esto se llama.
  final void Function()? alCambiar;

  Auditoria _auditoria;
  Auditoria? _pendiente;
  Future<void>? _trabajo;
  Object? _ultimoError;

  Auditoria get auditoria => _auditoria;
  Object? get ultimoError => _ultimoError;
  bool get guardando => _trabajo != null;

  ResumenGlobal get resumen => calcularResumen(catalogo, _auditoria);
  List<Problema> get problemas => validarParaEmitir(catalogo, _auditoria);
  String get reporteTexto => construirReporteTexto(catalogo, _auditoria);

  /// Se completa cuando no queda nada por escribir.
  Future<void> get guardado async {
    while (_trabajo != null) {
      await _trabajo;
    }
  }

  void responder(String preguntaId, Respuesta? valor) =>
      _aplicar((a) => a.responder(preguntaId, valor));

  void nota(String preguntaId, String texto) =>
      _aplicar((a) => a.conNota(preguntaId, texto));

  void actualizarEncabezado(Encabezado Function(Encabezado) cambio) =>
      _aplicar((a) => a.copyWith(encabezado: cambio(a.encabezado)));

  void agregarHallazgo(Hallazgo h) =>
      _aplicar((a) => a.copyWith(hallazgos: [...a.hallazgos, h]));

  void editarHallazgo(int indice, Hallazgo h) {
    if (indice < 0 || indice >= _auditoria.hallazgos.length) return;
    _aplicar((a) {
      final lista = [...a.hallazgos];
      lista[indice] = h;
      return a.copyWith(hallazgos: lista);
    });
  }

  void quitarHallazgo(int indice) {
    if (indice < 0 || indice >= _auditoria.hallazgos.length) return;
    _aplicar((a) {
      final lista = [...a.hallazgos]..removeAt(indice);
      return a.copyWith(hallazgos: lista);
    });
  }

  /// Agrega los borradores de hallazgo para cláusulas con "No". Devuelve
  /// cuántos agregó.
  int aceptarSugerencias() {
    final nuevos = sugerirHallazgos(catalogo, _auditoria);
    if (nuevos.isEmpty) return 0;
    _aplicar((a) => a.copyWith(hallazgos: [...a.hallazgos, ...nuevos]));
    return nuevos.length;
  }

  void _aplicar(Auditoria Function(Auditoria) cambio) {
    _auditoria = cambio(_auditoria).copyWith(actualizada: _reloj());
    _pendiente = _auditoria;
    alCambiar?.call();
    _trabajo ??= _vaciar();
  }

  Future<void> _vaciar() async {
    try {
      while (_pendiente != null) {
        final a = _pendiente!;
        _pendiente = null;
        try {
          await repositorio.guardar(a);
          if (_ultimoError != null) {
            _ultimoError = null;
            alCambiar?.call();
          }
        } catch (e) {
          _ultimoError = e;
          alCambiar?.call();
        }
      }
    } finally {
      _trabajo = null;
    }
  }
}
