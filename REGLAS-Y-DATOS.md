# Ceniza y Corona — app para iPhone y iPad

App nativa en SwiftUI que juega la saga a partir de `saga.json`, siguiendo las
reglas de la Parte II y la Parte III del libro maquetado.

## Cómo abrirla

```bash
open CenizaYCorona.xcodeproj
```

Destino mínimo iOS 17, familia 1,2 (iPhone y iPad). **Compilada y ejecutada** en
Xcode 26.6 con el SDK de iOS 26.5: Debug y Release pasan sin errores ni avisos,
y se ha revisado pantalla a pantalla en el simulador de iPhone 17 y de iPad Air.

### Atajo de desarrollo

Solo en Debug, la app admite variables de entorno para abrir cualquier pantalla
sin jugar hasta ella. En Xcode se ponen en *Edit Scheme › Run › Arguments*, o
desde la terminal:

```bash
SIMCTL_CHILD_CYC_SECCION=122 xcrun simctl launch booted com.jesusfernandez.cenizaycorona
```

Admite `CYC_SECCION`, `CYC_VOCACION`, `CYC_NOMBRE`, `CYC_FLAGS` (separadas por
comas), `CYC_REP` (`los_libres:3,favor:2`), `CYC_CORRUPCION` y `CYC_VIDA`.
La app publicada no lleva nada de esto.

## Qué sale del libro y qué he escrito yo

Todo lo que sigue está **transcrito del libro**, no inventado:

| Regla | Origen |
|---|---|
| Atributos FUE / AGI / VOL | Parte II, §11 |
| Vida, Ecos, Corrupción 0-10 | Parte II, §11 y §16 |
| Dificultades 7 / 9 / 11 / 13 | Parte II, §12 |
| Combate por rondas, iniciativa por AGI, daño fijo, +1 si el atributo es 7+ | Parte II, §13 |
| Defensa base 8 + armadura + escudo | Parte II, §13 |
| Armas, armaduras y mochila de 6 espacios | Parte II, §14 |
| Umbrales de Corrupción, mutación -1 VOL / +1 FUE a los 7 | Parte II, §16 |
| Reputación de -5 a +5 | Parte II, §17 |
| Puntos de Descanso (Ecos al completo, media Vida) | Parte II, §18 |
| Las cuatro vocaciones con sus cifras y equipo | Parte III, §20 |
| 3 puntos de personalización, máximo +2 por atributo | Parte III, §21 |
| Hechizos y Dones Forzados | Parte V, §24-26 |
| Las 33 fichas de enemigo | La línea `◈ … Defensa · Vida · Ataque · Daño` de cada sección de combate |
| Las tablas de finales | §133, §1145 y §2150 |
| Las 20 pruebas de habilidad con sus dos ramas | El bloque `**Prueba de X (Dif, N+)**` del texto de cada sección |

Decisiones mías, no del libro, todas en `Rules/`:

- En cada Punto de Descanso se ofrece una **decisión de expedición** gratuita:
  *Vigilar la ruta* da −2 al primer ataque enemigo del próximo combate y
  *Leer el camino* da +2 a la próxima prueba con dados. Ambas se consumen solo
  cuando ayudan, no gastan recursos ni cierran rutas.
- La interfaz muestra en cada combate su **objetivo** y la **intención** del
  enemigo. Es una explicación de las reglas especiales que ya aplica el motor;
  no altera el texto, los destinos ni las condiciones de final.

## Correcciones aplicadas al libro (21 de agosto de 2026)

Se corrigieron tres cosas **en el PDF y en el JSON a la vez**, para que libro y
app cuenten lo mismo:

| Dónde | Qué | Página del PDF |
|---|---|---|
| §1143 | Rama diplomática nueva: si la Vida de Ordaz baja de 6 puedes parlamentar con una prueba de VOL (Difícil, 11+); al superarla anotas `ORDAZ CONVENCIDA`. Sin esto, §1902 —que narra «no la derrotaste, la convenciste»— era inalcanzable. | 153 |
| §1145 | Los umbrales de §1903 y §1904 bajan de **+4 a +3**, que es el máximo que el Libro II reparte de verdad. | 155 |
| §122 | Las dos elecciones ya conceden `PADRE CENIZA CAPTURADO` / `PADRE CENIZA CAÍDO`. El PDF ya lo decía; era el JSON el que no lo recogía. | — |

Y un fallo de la app que salió al verificar: §38 y §122 son las dos únicas
secciones con **combate y elecciones propias**, y la app saltaba directa a
`on_win` sin enseñarlas nunca. Ahora aparecen dentro del combate como "otra
salida" —la de §122 solo cuando la Vida del Padre Ceniza baja de 8, como dice
el texto—. Sin esto, §901 seguía siendo inalcanzable aunque el dato estuviera
bien.

Ficheros:

- `CenizaYCorona_SAGA_COMPLETA_ILUSTRADA_corregida.pdf` — el libro ilustrado con
  las páginas 153 y 155 corregidas. Se editó en sitio, reutilizando las fuentes
  y los códigos de carácter del propio PDF, así que la tipografía es idéntica.
  Ninguna otra página cambia y el documento sigue teniendo 260 páginas.
- `../bookgame_web/public/data/saga.json` — **el maestro de datos**. Está
  bajo git, así que tiene historial y se puede revertir. De aquí se copia a la
  app iOS.

## Fallos en los datos

**§134** — está marcada "(reservada)". La app la excluye del recuento de
finales.

### El cálculo que destapó el problema

Recorriendo el grafo de secciones, la reputación **máxima** que se puede llevar
a cada tabla de finales era:

| Tabla | Orden | Secta | Los Libres | Favor | Vínculo |
|---|---|---|---|---|---|
| §133 · Libro I | 5 | 1 | 5 | 0 | 0 |
| §1145 · Libro II | **3** | 1 | **3** | 5 | 0 |
| §2150 · Libro III | **3** | 2 | 5 | **3** | 24 |

Contrastado con lo que pedía cada tabla, **tres de los siete finales de El
Trono Roto no se podían alcanzar jamás**: §1903 pedía Los Libres +4 con un
máximo de +3, §1904 pedía Orden +4 con un máximo de +3, y §1902 pedía una
palabra clave que ninguna sección concedía. Los tres están corregidos arriba.

### §2904 — la bifurcación de los voluntarios

§2904 exige *«reforjar la cadena sin voluntarios informados»*, pero **§2101 era
paso obligado** y concedía `VOLUNTARIOS DEL VALLE` sin condición, así que esa
rama no existía. Arreglado en el libro (página 225): al final de §2101, cuando
las treinta y siete personas se ofrecen, ahora hay una decisión de verdad.

> **1. Anotar sus nombres.** Uno por uno, y prometerles que bajarán sabiendo
> exactamente a qué se ofrecen. Anota la palabra clave `VOLUNTARIOS DEL VALLE`.
>
> **2. Decirles que no.** Esto no se decide en un campamento, a la luz de una
> hoguera. El anclaje quedará en manos del Consejo.

Es la misma disyuntiva que ya narran los dos finales: §2901 son los treinta y
siete con nombre y apellidos; §2904 es la Oficina del Ligamen.

Además, la tabla de §2150 pedía para §2904 un Favor +3 o una Orden +3 que en
esa ruta concreta son inalcanzables (el máximo real ahí es Favor 1 y Orden 2).
Como la reputación no aportaba nada al relato, la condición quedó en lo que el
final narra: **«Si elegiste reforjar la cadena sin voluntarios informados, ve a
la sección 2904.»**

Con esto, **los 24 finales de la saga son alcanzables**.

## Garantía de alcanzabilidad (web e iOS)

Las condiciones ejecutables de las tres tablas viven en `ending-rules.json`,
con una copia idéntica en la web y en el bundle iOS. Es la fuente de verdad
para el orden de los finales; `saga.json` sigue siendo la fuente narrativa. La
web verifica las dos copias, recorre los estados condicionales y exige
**24/24 finales**, **494/494 decisiones** alcanzables y **4/4 vocaciones** con
una ruta a un final. Los preparativos de marcha se prueban como efectos
consumibles que no crean bloqueos.

La app iOS usa el mismo JSON en tiempo de ejecución y el objetivo
`CenizaYCoronaTests` verifica cada desenlace, sus prioridades, los dos
preparativos de marcha, las cuatro vocaciones y que toda sección alcanzable
conserve una ruta a un final. Para comprobar ambos lados:

```bash
cd ../bookgame_web && npm run build
cd ../bookgame_app && xcodebuild -project CenizaYCorona.xcodeproj \
  -scheme CenizaYCorona -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Equilibrio

### Ajuste de supervivencia de las vocaciones

La simulación por vocación mostró que la Cuchilla resolvía los combates con un
margen que las otras tres no tenían. Esta edición equilibra el punto de partida
sin cambiar atributos ni elecciones narrativas:

| Vocación | Ajuste |
|---|---|
| Vigía | 22 Vida, cuero reforzado, arco corto de daño 3 y una venda. |
| Vidente | 22 Vida, 5 Ecos, cuero reforzado con foco protector, Chispa Negra de daño 4 y una venda. |
| Penitente | 24 Vida, escudo, maza de daño 4 y una venda. |

La Cuchilla permanece en 24 Vida, Defensa 10 y daño 4, pero ya no es la única
vocación con una combinación de supervivencia y daño viable. Las pruebas de
web e iOS bloquean regresiones por debajo de 22 Vida máxima, Defensa 9 y un
modo de ataque de daño 3 para cualquiera de las cuatro vocaciones.

### Escudo y Vida para la Vigía (24 de agosto de 2026)

Una simulación de 100 partidas completas (Libro I a III) por vocación, con un
motor que gasta recursos con criterio, mostró que la Vigía Errante moría el
73% de las veces y no llegaba a un final del Libro III ni una sola vez en 100
intentos — frente a un 37% de muertes de la Cuchilla. La causa: la Vigía era
la única de las cuatro vocaciones sin escudo (Defensa 9 en vez de 10) y
arrancaba con 22 de Vida en vez de 24, sin ningún recurso de combate que lo
compensara — Ojo de Vardo repite una prueba de habilidad, no una tirada de
ataque, así que no ayuda en los combates largos que la estaban matando.

Se le da escudo (Defensa 9→10) y se sube su Vida de 22 a 24, igualándola con
la Cuchilla y el Penitente. El daño del arco corto (3) y el propio Ojo de
Vardo no se tocan: son un cambio de diseño más profundo que este ajuste no
cubre. Repitiendo la simulación tras el cambio, la Vigía pasa a morir el 47%
de las veces (Cuchilla: 46%) y `scripts/balance-por-vocacion.mjs`, con 3.000
partidas por libro, confirma la paridad: 9,9% de muertes para la Cuchilla
frente a 10,0% para la Vigía jugando con recursos.

Simulando 7.200 partidas con el motor de la app, ya con pruebas de habilidad:

- 0 fallos estructurales: toda partida termina en un final real.
- 19.489 pruebas de habilidad tiradas, sin bucles ni destinos rotos.
- Tras las correcciones, **los 24 finales se alcanzan** jugando por simulación,
  con 0 fallos estructurales. §2905 es el más raro: exige no reforjar ni romper
  la cadena y llegar a la tabla con la Corrupción justo entre 7 y 9.
- Jugando al azar **sin usar recursos**, se muere en el 88-99% de las partidas.
- Jugando al azar **usando vendas, pociones y Dones Forzados**, se muere en el
  45-56%, y se alcanzan 5-7 finales distintos por libro.
- Los finales de Corrupción (§950, §1950, §2950) salen en un 10-20% de las
  partidas: la Sangre Vieja se cobra lo suyo, como manda la §16.

Los números son los del libro. El combate más duro (§126, Quebrado Mayor:
Defensa 12, Vida 40, Daño 6) lo gana un personaje fresco un 27% de las veces
sin gastar nada, tal y como avisa el propio texto de la sección.

## Estructura

```
CenizaYCorona/
  Model/       Section, Book, Atributos, Dice, GameState, CombatSession,
               SagaLibrary, SaveStore
  Rules/       Bestiario (extraído), PruebasDeHabilidad (extraídas), Equipo,
               Grimorio, Vocaciones, TablaDeFinales + ParchesDeDatos
  Theme/       Palette, Pergamino (fondo y grano), Ornamentos (marcos y florones)
  Views/       Biblioteca, Creacion, Lectura, Combate, Hoja, Final,
               CarrilPersonaje, Components/ (incluye PanelDePrueba)
  Resources/   saga.json
```

Las partidas se guardan en Application Support, una por ámbito: los tres libros
sueltos y la saga completa no se pisan.

## De dónde salen los datos

Solo existen dos copias de `saga.json`, y son idénticas (SHA-256 `cc893dcf…`):

| Ruta | Papel |
|---|---|
| `~/Desktop/GitHub/bookgame_web/public/data/saga.json` | **maestro**, versionado en git; es lo que sirve la web en `/data/saga.json` |
| `~/Desktop/GitHub/bookgame_app/CenizaYCorona/Resources/saga.json` | copia empaquetada dentro del `.app` de iOS |

Al editar el maestro hay que copiarlo a la app iOS:

```bash
cp ~/Desktop/GitHub/bookgame_web/public/data/saga.json \
   ~/Desktop/GitHub/bookgame_app/CenizaYCorona/Resources/saga.json
```

La app iOS lo lee en un solo sitio, `SagaLibrary.swift`, con el nombre fijo
`saga.json`; la web, con un solo `fetch('/data/saga.json')` en `app/page.tsx`.

## Detalles pulidos al verlo funcionar

- El texto de las secciones viene en Markdown ligero (`**negrita**`,
  `` `PALABRAS CLAVE` ``, listas con guion) y salía en crudo. Ahora se compone
  con estilo: negritas, viñetas y las palabras clave en versalitas granate.
  Está en `Views/Components/TextoDelLibro.swift`.
- El campo `notes` de los combates son anotaciones tuyas de maquetación
  («A Vida<=8 ofrece tregua; el jugador elige...»). Ya no se le enseñan al
  jugador.

## Tipografía

La identidad del libro es serif tipo Cambria/Garamond. En iOS eso es **New
York**, que viene con el sistema. Si añades Cinzel o EB Garamond al bundle,
el único sitio que hay que tocar es `Theme/Palette.swift`.

## Salidas de vocación (§19 bis del libro)

Catorce combates admiten una salida que los evita enteros. Es contenido
**nuevo**, escrito para esta edición: está en la página 15 del PDF y en
`Rules/ReglasEspeciales.swift` como el campo `salida` de `ReglaDeCombate`.

- **Vigía Errante** (AGI, «no ser vista»): §20, §33, §42, §59, §86, §1046,
  §1127, §2033, §2052.
- **Vidente Rota** (VOL, «hablarle»): §14, §94, §1118, §2068, §2115.

Una sola tentativa, solo antes del primer golpe, y al superarla la historia
sigue por `on_win`. Quien no es de esa vocación puede intentarlo un peldaño
de dificultad más arriba: nada queda cerrado a nadie.

Las otras 24 reglas de la tabla no son nuevas — son las líneas `*Especial:*`
que el propio libro ya escribía en cada combate y que la app ignoraba.

`../bookgame_web/lib/combat-rules.ts` se **genera** desde este archivo
Swift. Si tocas uno, regenera el otro; si no, las dos apps divergen.
