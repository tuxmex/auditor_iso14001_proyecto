const fs = require('fs');
const C = (numero, titulo, proposito, qs) => ({ numero, titulo, proposito, preguntas: qs.map(([texto, evidencia], i) => ({ id: `${numero}-${i + 1}`, texto, evidencia })) });
const clausulas = [
  C('4.1', 'Organización y su contexto', 'El área entiende el entorno interno y externo que influye en lo que puede lograr con su gestión ambiental.', [
    ['¿El área identificó los asuntos externos (legales, climáticos, sociales, económicos, del entorno físico) que pueden afectar su desempeño ambiental?', 'Análisis de contexto (FODA, PESTEL u otro), minutas de reunión.'],
    ['¿El área identificó los asuntos internos (instalaciones, recursos, cultura, procesos, personal) que influyen en su desempeño ambiental?', 'Análisis de contexto, inventario de instalaciones y procesos.'],
    ['¿El área determinó si el cambio climático es un asunto relevante para su contexto y dejó constancia de su conclusión? (Enmienda 1:2024)', 'Registro de la decisión, análisis de contexto con el tema climático.'],
    ['¿El análisis de contexto se revisa periódicamente y sus cambios se reflejan en la planificación del sistema?', 'Fecha de la última revisión, actas de revisión por la dirección.'],
  ]),
  C('4.2', 'Partes interesadas', 'El área sabe quién puede afectarla o verse afectado por ella, y qué espera de su gestión ambiental.', [
    ['¿El área identificó a sus partes interesadas relevantes (estudiantes, personal, autoridades, vecinos, proveedores, contratistas)?', 'Matriz o listado de partes interesadas.'],
    ['¿Se determinaron las necesidades y expectativas de cada parte interesada que son relevantes para el sistema de gestión ambiental?', 'Matriz de necesidades y expectativas, encuestas, correos.'],
    ['¿El área decidió cuáles de esas necesidades y expectativas adopta como requisitos legales u otros requisitos?', 'Registro de decisiones, lista de requisitos aplicables.'],
    ['¿El área consideró que las partes interesadas pueden tener necesidades relacionadas con el clima, y lo documentó? (Enmienda 1:2024)', 'Matriz de partes interesadas con la columna o nota sobre clima.'],
  ]),
  C('5.2', 'Política ambiental', 'La alta dirección fija el rumbo ambiental y lo comunica.', [
    ['¿Existe una política ambiental vigente, aprobada por la alta dirección y adecuada al propósito y al contexto de la institución?', 'Documento de la política con firma, fecha y versión.'],
    ['¿La política incluye compromisos de protección del ambiente (incluida la prevención de la contaminación), de cumplimiento de requisitos y de mejora continua?', 'Texto de la política.'],
    ['¿La política ofrece un marco para establecer y revisar los objetivos ambientales?', 'Relación entre política y objetivos del área.'],
    ['¿La política está documentada, se comunica dentro del área y está disponible para las partes interesadas que la soliciten?', 'Carteles, intranet, sitio web, inducciones.'],
  ]),
  C('5.3', 'Roles y responsabilidades', 'Cada persona sabe qué le toca hacer y con qué autoridad en el sistema de gestión ambiental.', [
    ['¿Las responsabilidades y autoridades del sistema ambiental están asignadas en el área?', 'Organigrama, descripciones de puesto, nombramientos.'],
    ['¿El personal entrevistado conoce las responsabilidades ambientales que le corresponden?', 'Entrevista a dos o tres personas del área.'],
    ['¿Hay una persona con autoridad designada para informar a la alta dirección sobre el desempeño del sistema?', 'Nombramiento, informes enviados a la dirección.'],
    ['¿Las personas con roles ambientales cuentan con tiempo y recursos para cumplirlos?', 'Horas asignadas, presupuesto, equipo disponible.'],
  ]),
  C('6.1', 'Riesgos y oportunidades', 'El área piensa de antemano qué puede salir mal o mejor, y actúa en consecuencia.', [
    ['¿El área determinó los riesgos y oportunidades ligados a sus aspectos ambientales, requisitos legales, contexto y partes interesadas?', 'Matriz de riesgos y oportunidades.'],
    ['¿Se consideraron las situaciones potenciales de emergencia (incendio, derrame, fuga, inundación) dentro de ese análisis?', 'Escenarios de emergencia identificados.'],
    ['¿Se planificaron acciones para abordar esos riesgos y oportunidades, integradas a los procesos del área?', 'Plan de acciones, responsables y fechas.'],
    ['¿El área evalúa si las acciones tomadas fueron eficaces y conserva evidencia de lo que determinó?', 'Seguimiento de acciones, informes de resultados.'],
  ]),
  C('6.1.2', 'Aspectos ambientales', 'El área sabe qué de lo que hace interactúa con el ambiente y cuáles interacciones importan más.', [
    ['¿Existe un listado de actividades, productos y servicios del área con sus aspectos ambientales (agua, energía, residuos, emisiones, descargas, ruido)?', 'Inventario de aspectos ambientales.'],
    ['¿El análisis contempla condiciones normales, anormales (arranques, mantenimientos) y de emergencia?', 'Columnas o secciones por condición de operación.'],
    ['¿Se tomó en cuenta la perspectiva del ciclo de vida (compras, uso, disposición final) en lo que el área controla o influye?', 'Criterios de compra, destino final de residuos y equipos.'],
    ['¿Hay criterios definidos para decidir cuáles aspectos son significativos y se aplican de manera consistente?', 'Metodología de evaluación, matriz con calificaciones.'],
    ['¿La lista de aspectos significativos se mantiene actualizada y se comunica a los niveles pertinentes?', 'Fecha de actualización, evidencia de comunicación.'],
  ]),
  C('6.2', 'Objetivos ambientales y planificación para lograrlos', 'El área se pone metas ambientales concretas y un plan para alcanzarlas.', [
    ['¿El área tiene objetivos ambientales coherentes con la política y medibles (o evaluables)?', 'Programa de objetivos con indicadores.'],
    ['¿Los objetivos toman en cuenta los aspectos significativos, los requisitos aplicables y los riesgos y oportunidades?', 'Relación documentada entre objetivos y su origen.'],
    ['¿Existe un plan que define qué se hará, con qué recursos, quién responde, cuándo termina y cómo se evaluarán los resultados?', 'Plan de acción por objetivo.'],
    ['¿Se da seguimiento a los objetivos y se actualizan cuando es necesario?', 'Tablero de avance, minutas, revisiones.'],
  ]),
  C('7.3', 'Toma de conciencia', 'Las personas entienden por qué la gestión ambiental importa y cuál es su parte.', [
    ['¿El personal del área conoce la política ambiental?', 'Entrevistas, evaluación breve, evidencia de difusión.'],
    ['¿Conoce los aspectos ambientales significativos relacionados con su trabajo y los impactos reales o potenciales?', 'Entrevistas, registros de capacitación.'],
    ['¿Entiende cómo contribuye a la eficacia del sistema y qué se gana con un mejor desempeño ambiental?', 'Entrevistas.'],
    ['¿Sabe qué implica no cumplir los requisitos del sistema, incluidos los legales?', 'Entrevistas, material de inducción.'],
    ['¿Las personas que trabajan en nombre del área (contratistas, servicio social, becarios) también están al tanto?', 'Inducciones, reglamentos entregados, registros de asistencia.'],
  ]),
  C('7.4', 'Comunicación', 'El área sabe qué comunicar, a quién, cuándo y cómo, y también escucha.', [
    ['¿El área definió qué, cuándo, a quién y cómo comunica en materia ambiental, tanto hacia dentro como hacia fuera?', 'Procedimiento o matriz de comunicación.'],
    ['¿Se tomaron en cuenta los requisitos legales al decidir qué comunicar?', 'Relación entre obligaciones de reporte y la matriz.'],
    ['¿La información que se comunica es consistente con la del sistema y es confiable?', 'Comparación de comunicados con registros del sistema.'],
    ['¿Existe forma de recibir, documentar y responder las comunicaciones relevantes de las partes interesadas?', 'Buzón, correo, bitácora de quejas y respuestas.'],
    ['¿Hay evidencia de comunicaciones internas y externas realizadas?', 'Oficios, circulares, carteles, correos.'],
  ]),
  C('7.5', 'Información documentada', 'Los documentos y registros que el sistema necesita existen, se controlan y se pueden confiar.', [
    ['¿El área cuenta con la información documentada que exige el sistema y la que ella misma determinó necesaria?', 'Listado maestro de documentos y registros.'],
    ['¿Los documentos tienen identificación y descripción adecuadas (título, fecha, autor, código, versión) y un formato apropiado?', 'Muestra de documentos del área.'],
    ['¿Se controla su aprobación, distribución, acceso, uso y cambios, de modo que solo las versiones vigentes estén en los puntos de uso?', 'Control de versiones, lista de distribución.'],
    ['¿Los registros se almacenan, protegen y conservan según un criterio de retención definido?', 'Criterio de retención, archivo físico o digital.'],
    ['¿La información de origen externo que el sistema necesita (normas, permisos, manuales) está identificada y controlada?', 'Permisos, licencias, manuales de proveedores.'],
  ]),
  C('8.1', 'Planificación y control operacional', 'Los procesos que importan para el ambiente se ejecutan con control, también cuando hay cambios o emergencias.', [
    ['¿Los procesos ligados a aspectos significativos y requisitos legales están definidos y controlados con criterios operacionales (procedimientos, instrucciones)?', 'Procedimientos, instrucciones de trabajo, bitácoras.'],
    ['¿Se controlan los cambios planeados y se revisan las consecuencias de los cambios no previstos?', 'Registros de cambios, análisis posteriores.'],
    ['¿Se controlan o se influye sobre los procesos contratados con terceros (limpieza, jardinería, mantenimiento, residuos) y se les comunican los requisitos ambientales?', 'Contratos, cláusulas ambientales, evaluaciones de proveedores.'],
    ['¿Existen planes de preparación y respuesta ante emergencias, se prueban periódicamente y se revisan después de un incidente?', 'Planes, simulacros, extintores, kits de derrame, informes.'],
    ['¿Se conserva información de que los procesos se realizaron como se planearon?', 'Bitácoras, manifiestos de residuos, listas de verificación.'],
  ]),
  C('9.1', 'Seguimiento, medición, análisis y evaluación', 'El área mide lo que importa, confía en sus mediciones y usa los resultados.', [
    ['¿El área determinó qué se debe medir, con qué método, con qué criterios y cuándo se miden y analizan los resultados?', 'Programa de seguimiento, indicadores.'],
    ['¿Los equipos de medición usados están calibrados o verificados y se conserva evidencia de ello?', 'Certificados de calibración, bitácoras de verificación.'],
    ['¿Se evalúa periódicamente el cumplimiento de los requisitos legales y otros requisitos, y se conserva evidencia?', 'Informes de evaluación de cumplimiento.'],
    ['¿Los datos se analizan para detectar tendencias y los resultados se comunican a quien corresponde?', 'Gráficas de consumo, informes, minutas.'],
    ['¿Cuando se detectan incumplimientos o desviaciones se toman acciones y se da seguimiento?', 'Registros de acciones y su cierre.'],
  ]),
  C('10.3', 'Mejora continua', 'El sistema no se queda quieto: se vuelve más adecuado y eficaz con el tiempo.', [
    ['¿El área busca de forma activa mejorar la idoneidad, adecuación y eficacia de su sistema para mejorar el desempeño ambiental?', 'Iniciativas de mejora, propuestas del personal.'],
    ['¿Se pueden mostrar mejoras concretas recientes (menos consumo, menos residuos, menos incidentes)?', 'Comparativos antes y después, indicadores.'],
    ['¿Las decisiones de mejora se apoyan en los resultados del seguimiento, las auditorías y la revisión por la dirección?', 'Actas de revisión por la dirección, informes de auditoría.'],
    ['¿Se da seguimiento al cierre de los hallazgos de auditorías previas y se verifica que las acciones fueron eficaces?', 'Registro de hallazgos y acciones correctivas.'],
  ]),
];
const catalogo = { version: 1, norma: 'ISO 14001:2015 (con Enmienda 1:2024)', formato: 'F-OSC-39 Rev. 4', clausulas };
fs.writeFileSync(__dirname + '/../app/assets/catalogo_iso14001.json', JSON.stringify(catalogo, null, 2) + '\n');
console.log(clausulas.length, 'cláusulas,', clausulas.reduce((n, c) => n + c.preguntas.length, 0), 'preguntas');
