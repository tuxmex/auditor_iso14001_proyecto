'use strict';
const fs = require('node:fs');
const path = require('node:path');

const REQUERIDAS = ['4.1', '4.2', '5.2', '5.3', '6.1', '6.1.2', '6.2', '7.3', '7.4', '7.5', '8.1', '9.1', '10.3'];

// Devuelve la lista de problemas del catálogo (vacía si está bien).
function validarCatalogo(c) {
  const p = [];
  if (!c || typeof c !== 'object') return ['El catálogo debe ser un objeto JSON.'];
  if (!Number.isInteger(c.version)) p.push('Falta version (entero).');
  if (typeof c.norma !== 'string' || !c.norma.trim()) p.push('Falta norma.');
  if (!Array.isArray(c.clausulas) || c.clausulas.length === 0) return [...p, 'Falta la lista clausulas.'];
  const numeros = new Set();
  const ids = new Set();
  for (const cl of c.clausulas) {
    const n = cl && cl.numero;
    if (typeof n !== 'string' || !/^\d+(\.\d+)*$/.test(n)) { p.push(`Cláusula con número inválido: ${JSON.stringify(n)}`); continue; }
    if (numeros.has(n)) p.push(`Cláusula repetida: ${n}`);
    numeros.add(n);
    if (!cl.titulo || !String(cl.titulo).trim()) p.push(`${n}: falta título.`);
    if (!cl.proposito || !String(cl.proposito).trim()) p.push(`${n}: falta propósito.`);
    if (!Array.isArray(cl.preguntas) || cl.preguntas.length < 3) { p.push(`${n}: necesita al menos 3 preguntas.`); continue; }
    cl.preguntas.forEach((q, i) => {
      const esperado = `${n}-${i + 1}`;
      if (q.id !== esperado) p.push(`${n}: la pregunta ${i + 1} debe llamarse ${esperado} (tiene ${q.id}).`);
      if (ids.has(q.id)) p.push(`Id repetido: ${q.id}`);
      ids.add(q.id);
      if (!q.texto || !String(q.texto).trim()) p.push(`${q.id}: falta texto.`);
      else if (!/^¿.*\?(\s*\(.*\))?$/.test(String(q.texto).trim())) p.push(`${q.id}: la pregunta debe iniciar con ¿ y cerrar con ? (puede llevar una nota entre paréntesis).`);
      if (!q.evidencia || !String(q.evidencia).trim()) p.push(`${q.id}: falta evidencia sugerida.`);
    });
  }
  for (const r of REQUERIDAS) if (!numeros.has(r)) p.push(`Falta la cláusula requerida ${r}.`);
  for (const n of numeros) if (!REQUERIDAS.includes(n)) p.push(`Cláusula fuera del alcance acordado: ${n}.`);
  return p;
}

module.exports = { validarCatalogo, REQUERIDAS };

if (require.main === module) {
  const ruta = path.resolve(process.argv[2] ?? path.join(__dirname, '../app/assets/catalogo_iso14001.json'));
  let c;
  try { c = JSON.parse(fs.readFileSync(ruta, 'utf8')); } catch (e) { console.error(`No pude leer ${ruta}: ${e.message}`); process.exit(2); }
  const p = validarCatalogo(c);
  if (p.length) { p.forEach((x) => console.log('ERROR', x)); process.exitCode = 1; }
  else console.log(`Catálogo válido: ${c.clausulas.length} cláusulas, ${c.clausulas.reduce((n, x) => n + x.preguntas.length, 0)} preguntas.`);
}
