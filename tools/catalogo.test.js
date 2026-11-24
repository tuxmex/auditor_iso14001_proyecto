'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { validarCatalogo, REQUERIDAS } = require('./validar_catalogo');

const real = JSON.parse(fs.readFileSync(path.join(__dirname, '../app/assets/catalogo_iso14001.json'), 'utf8'));
const copia = () => JSON.parse(JSON.stringify(real));

test('el catálogo real es válido', () => assert.deepEqual(validarCatalogo(real), []));
test('tiene exactamente las 13 cláusulas pedidas, en orden', () => assert.deepEqual(real.clausulas.map((c) => c.numero), REQUERIDAS));
test('cada cláusula tiene entre 4 y 5 preguntas', () => {
  for (const c of real.clausulas) assert.ok(c.preguntas.length >= 4 && c.preguntas.length <= 5, c.numero);
});
test('hay una pregunta sobre cambio climático en 4.1 y 4.2 (Enmienda 1:2024)', () => {
  for (const n of ['4.1', '4.2']) {
    const c = real.clausulas.find((x) => x.numero === n);
    assert.ok(c.preguntas.some((q) => /clim/i.test(q.texto)), n);
  }
});
test('detecta cláusula faltante', () => {
  const c = copia(); c.clausulas = c.clausulas.filter((x) => x.numero !== '9.1');
  assert.ok(validarCatalogo(c).some((m) => m.includes('9.1')));
});
test('detecta cláusula fuera de alcance', () => {
  const c = copia(); c.clausulas.push({ ...c.clausulas[0], numero: '9.2' });
  assert.ok(validarCatalogo(c).some((m) => m.includes('fuera del alcance')));
});
test('detecta ids repetidos o mal numerados', () => {
  const c = copia(); c.clausulas[0].preguntas[1].id = '4.1-1';
  const p = validarCatalogo(c);
  assert.ok(p.some((m) => m.includes('Id repetido')));
  assert.ok(p.some((m) => m.includes('debe llamarse 4.1-2')));
});
test('detecta texto vacío, sin signos de pregunta o sin evidencia', () => {
  const c = copia();
  c.clausulas[0].preguntas[0].texto = '';
  c.clausulas[0].preguntas[1].texto = 'Esto no es pregunta';
  c.clausulas[0].preguntas[2].evidencia = '  ';
  const p = validarCatalogo(c);
  assert.ok(p.some((m) => m.includes('4.1-1: falta texto')));
  assert.ok(p.some((m) => m.includes('4.1-2: la pregunta debe iniciar')));
  assert.ok(p.some((m) => m.includes('4.1-3: falta evidencia')));
});
test('menos de 3 preguntas en una cláusula es error', () => {
  const c = copia(); c.clausulas[2].preguntas = c.clausulas[2].preguntas.slice(0, 2);
  assert.ok(validarCatalogo(c).some((m) => m.includes('al menos 3')));
});
test('entradas que no son catálogo', () => {
  assert.equal(validarCatalogo(null).length, 1);
  assert.ok(validarCatalogo({}).length >= 1);
  assert.ok(validarCatalogo({ version: 1, norma: 'x', clausulas: [] }).length >= 1);
});
test('el número de cláusula inválido se reporta sin romper', () => {
  const c = copia(); c.clausulas[0].numero = 'cuatro';
  assert.ok(validarCatalogo(c).some((m) => m.includes('número inválido')));
});
