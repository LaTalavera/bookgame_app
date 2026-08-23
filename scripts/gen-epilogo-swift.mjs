/* Genera CenizaYCorona/Rules/Epilogo.swift a partir de la fuente unica de
   verdad, ceniza-y-corona-app/lib/epilogue.ts, para que el texto del epilogo
   no pueda divergir entre la web y la app movil.

   Uso:  node CenizaYCorona/scripts/gen-epilogo-swift.mjs            */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const aqui = path.dirname(fileURLToPath(import.meta.url));
const raiz = path.resolve(aqui, "..", "..");
const ORIGEN = path.join(raiz, "ceniza-y-corona-app", "lib", "epilogue.ts");
const DESTINO = path.join(raiz, "CenizaYCorona", "CenizaYCorona", "Rules", "Epilogo.swift");

const src = fs.readFileSync(ORIGEN, "utf8");
const inicio = src.indexOf("EPILOGUE_LINES: EpilogueLine[] = [");
if (inicio < 0) throw new Error("No encuentro EPILOGUE_LINES en epilogue.ts");
const body = src.slice(inicio, src.indexOf("\n];", inicio));

const lineas = [];
const re = /\{ flag: '([A-Z0-9_]+)', text: '((?:[^'\\]|\\.)*)' \}/g;
let m;
while ((m = re.exec(body))) lineas.push({ flag: m[1], text: m[2].replace(/\\'/g, "'") });
if (lineas.length === 0) throw new Error("No he podido leer ninguna linea de epilogo.");

const titulos = [];
for (const raw of body.split("\n")) {
	const c = raw.match(/\/\* ─+ (.*?) ─+ \*\//);
	if (c) titulos.push({ antesDe: lineas.length, titulo: c[1] });
}

let out = `import Foundation

/// EPÍLOGO POR PALABRAS CLAVE
///
/// La crónica registra 122 palabras clave, pero la mayoría no abre ni cierra
/// ninguna puerta: son memoria, no mecánica. Este fichero las convierte en lo
/// único que necesitaban, consecuencia narrativa. Al llegar a un final, el
/// texto añade las líneas de cierre que te hayas ganado.
///
/// Regla de oro: aquí no hay reglas. Nada de esto se anota en la ficha, nada
/// de esto cambia un número. Si una palabra clave necesitase una tirada,
/// estaría en ReglasEspeciales.swift, no aquí.
///
/// GENERADO desde ceniza-y-corona-app/lib/epilogue.ts. No editar a mano:
/// cambia el TypeScript y ejecuta CenizaYCorona/scripts/gen-epilogo-swift.mjs.
enum Epilogo {
    struct Linea: Hashable, Identifiable {
        var id: String { flag }
        let flag: String
        let texto: String
    }

    /// Cuántas líneas se leen como máximo al cerrar una partida.
    static let maximoDeLineas = 6

    static let lineas: [Linea] = [
`;

let i = 0;
for (const linea of lineas) {
	for (const t of titulos) if (t.antesDe === i) out += `        // ── ${t.titulo} ──\n`;
	const texto = linea.text.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
	out += `        Linea(flag: "${linea.flag}",\n              texto: "${texto}"),\n`;
	i++;
}

out += `    ]

    private static let indice: [String: String] = Dictionary(uniqueKeysWithValues: lineas.map { ($0.flag, $0.texto) })

    /// Las líneas de epílogo ganadas, en orden de lectura.
    static func para(_ flags: Set<String>, maximo: Int = maximoDeLineas) -> [String] {
        var resultado: [String] = []
        for linea in lineas where flags.contains(linea.flag) {
            resultado.append(linea.texto)
            if resultado.count >= maximo { break }
        }
        return resultado
    }

    static func linea(para flag: String) -> String? { indice[flag] }
}
`;

fs.writeFileSync(DESTINO, out, "utf8");
console.log(`Epilogo.swift generado con ${lineas.length} lineas desde epilogue.ts`);
