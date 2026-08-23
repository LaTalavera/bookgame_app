
## El Eco que faltaba, y el libro sin descanso (§18/§22/§25 y §1006)

Dos huecos reales del libro que dejaban al Penitente sin poder usar su
propio hechizo antimuerto:

- **Ecos iniciales del Penitente: 1 → 2.** Con 1 Eco y *Luz de Cadena
  Rota* a coste 2, era matemáticamente imposible lanzarlo sin forzar el
  don. Con 2 puede, una vez, entre descansos — y sigue por debajo de los 3
  de la Vidente Rota, así que no le arrebata su lugar como la lanzadora más
  frágil de Ecos. Página 17 del PDF, `Vocaciones.swift::ecosIniciales`.

- **Libro II no tenía ni un Punto de Descanso.** §1006, «La Corona
  Partida» — la posada la noche antes de la Convocatoria, de paso
  obligado para cualquier camino — es ahora `🕯 Punto de Descanso`. Cae
  antes de los siete combates del libro (§1022–§1143), así que por
  primera vez los Ecos se recargan y el hechizo avanzado (`repertorio`)
  se puede aprender dentro del Libro II. Página 103 del PDF, sección 1006
  en `saga.json` (las dos copias: `CenizaYCorona/Resources/` y
  `ceniza-y-corona-app/public/data/`).

Ninguno de los dos cambios es una regla nueva: el Penitente ya tenía el
hechizo escrito en la Parte V, y §18 ya decía que los descansos existen.
Lo que faltaba era que la aritmética del libro se lo permitiera al menos
una vez por libro.

## Eco Profundo, dos veces por combate (Vidente Rota)

A diferencia de los dos cambios de arriba, este sí es una decisión mía, no
una corrección de una imposibilidad del libro — documentado aparte por eso.

Simulando partidas al azar por vocación con `scripts/balance-por-vocacion.mjs`
(en `ceniza-y-corona-app/`), la Vidente moría en el 82-83% de las partidas
con recursos, la más frágil de las cuatro con diferencia. La causa no es la
Vida (16, la más baja) ni la Defensa: subirlas 4 puntos en simulación no
movía la tasa de muerte ni un punto. La causa es que con 3 Ecos totales
gasta su magia en las dos primeras rondas de cada combate y el resto del
libro pelea con un bastón y FUE 3 contra enemigos de 20-60 de Vida.

Probé tres palancas aisladas en simulación antes de tocar nada: subir el
daño de Chispa Negra, subir los Ecos iniciales, y permitir el don **Eco
Profundo** dos veces por combate en vez de una. Las tres ayudan en el Libro
I-II; ninguna arregla el Libro III (9 combates, solo 4 descansos, enemigos
de hasta 60 de Vida — eso necesitaría una intervención mayor, no un ajuste
de un número). Elegido: **Eco Profundo dos veces por combate**, porque es
el cambio más pequeño de los tres con más efecto medido — baja la muerte en
el Libro I de 71.7% a 54.5% y dobla su daño mágico disponible en cualquier
combate sin tocar Vida, Defensa ni el resto de vocaciones. La Vidente sigue
siendo la más frágil de las cuatro en el Libro III — eso se queda así,
consciente, por ahora.

Cada uso sigue constando 1 Corrupción por separado (2 usos = 2 Corrupción
como máximo). Cambiado en `Vocaciones.swift::don`, `CombatSession.swift`
(`ecoProfundoUsado: Bool` → `ecoProfundoUsos: Int`, tope 2),
`ceniza-y-corona-app/lib/full-rules.ts` (texto del don),
`ceniza-y-corona-app/lib/game-engine.ts` (nuevo `CombatState.deepEchoUses`,
antes compartía el campo `vocationGiftUsed` de la Cuchilla) y
`ceniza-y-corona-app/app/page.tsx` (botón de combate). Página 17 del PDF:
«una vez por combate» → «dos veces por combate», editado en sitio
reutilizando fuente y códigos de carácter, verificado con render antes/después
antes de guardar (no cambia el resto del documento; el PDF resultante pesa
menos por recompresión sin pérdida de pikepdf, no por tocar imágenes —
comprobado por hash, byte a byte idénticas).
