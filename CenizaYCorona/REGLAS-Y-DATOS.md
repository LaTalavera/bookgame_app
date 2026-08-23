
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
  `../bookgame_web/public/data/`).

Ninguno de los dos cambios es una regla nueva: el Penitente ya tenía el
hechizo escrito en la Parte V, y §18 ya decía que los descansos existen.
Lo que faltaba era que la aritmética del libro se lo permitiera al menos
una vez por libro.

## Eco Profundo, dos veces por combate (Vidente Rota)

A diferencia de los dos cambios de arriba, este sí es una decisión mía, no
una corrección de una imposibilidad del libro — documentado aparte por eso.

Simulando partidas al azar por vocación con `scripts/balance-por-vocacion.mjs`
(en `../bookgame_web/`), la Vidente moría en el 82-83% de las partidas
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
`../bookgame_web/lib/full-rules.ts` (texto del don),
`../bookgame_web/lib/game-engine.ts` (nuevo `CombatState.deepEchoUses`,
antes compartía el campo `vocationGiftUsed` de la Cuchilla) y
`../bookgame_web/app/page.tsx` (botón de combate). Página 17 del PDF:
«una vez por combate» → «dos veces por combate», editado en sitio
reutilizando fuente y códigos de carácter, verificado con render antes/después
antes de guardar (no cambia el resto del documento; el PDF resultante pesa
menos por recompresión sin pérdida de pikepdf, no por tocar imágenes —
comprobado por hash, byte a byte idénticas).

## Escudo y Vida para la Vigía Errante (24 de agosto de 2026)

Simulando 100 partidas completas (Libro I a III) por vocación con un motor
que gasta recursos con criterio (curar cuando conviene, guardar los dones
para los combates duros), la Vigía Errante moría el 73% de las veces y no
llegó a un final del Libro III ni una sola vez en 100 intentos — la Cuchilla,
con el mismo criterio de juego, moría el 37%.

La causa no es el arco corto (daño 3, igual que el bastón de la Vidente) ni
la iniciativa (AGI 7 ya supera el Ataque de los dos jefes que más la
mataban, §126 y §1137, igual que la Cuchilla). Es que la Vigía era la única
de las cuatro vocaciones sin escudo — Defensa 9 en vez de 10 — y arrancaba
con 22 de Vida en vez de 24, sin ningún recurso que lo compensara: Ojo de
Vardo repite una prueba de habilidad fallida, nunca una tirada de ataque,
así que no aporta nada en los combates largos de desgaste que la estaban
matando (a diferencia de la Furia de la Cuchilla, el Eco Profundo de la
Vidente o el Voto de Ceniza del Penitente, los tres útiles dentro del
combate).

Cambiado: **escudo** para la Vigía (Defensa 9→10) y **Vida inicial 22→24**,
igualándola con la Cuchilla y el Penitente en sus dos números de
supervivencia física. No se toca el daño del arco ni el propio Ojo de
Vardo — redecidir cómo el don ayuda en combate es una intervención mayor
que este ajuste no cubre. Repitiendo la simulación tras el cambio, la
Vigía pasa a morir el 47% de las veces (Cuchilla: 46%), y
`scripts/balance-por-vocacion.mjs` (3.000 partidas por libro) confirma la
paridad: 9,9% de muertes para la Cuchilla frente a 10,0% para la Vigía
jugando con recursos.

Cambiado en `Vocaciones.swift::vidaInicial` y `Vocaciones.swift::escudo`,
y en `../bookgame_web/lib/full-rules.ts` (`VOCATIONS.vigia.maxLife` y
`.shield`). Un test de `test-engine.mjs` que reescala una partida antigua
en proporción a la Vida máxima de la vocación cambió su valor esperado de
11 a 12 como consecuencia directa (no es una regresión: el propio cálculo
no cambió, solo la constante de la que depende).
