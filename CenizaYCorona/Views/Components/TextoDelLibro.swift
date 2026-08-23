import SwiftUI

/// El texto de las secciones viene en Markdown ligero: **negrita**,
/// `PALABRAS CLAVE` entre acentos graves y listas con guion. Esto lo convierte
/// en texto con estilo en vez de enseñar los asteriscos en crudo.
enum TextoDelLibro {

    static func atribuido(_ texto: String,
                          tamano: CGFloat,
                          color: Color = .cyTinta,
                          cursiva: Bool = false,
                          versalesIniciales: Bool = false) -> AttributedString {

        let cuerpo = versalesIniciales ? sinApertura(texto) : texto
        var salida = AttributedString()

        if versalesIniciales, let apertura = aperturaEnVersales(texto, tamano: tamano) {
            salida.append(apertura)
        }

        var parseado = parsear(normalizarListas(cuerpo))
        parseado.font = fuenteBase(tamano, cursiva: cursiva)
        parseado.foregroundColor = color
        aplicarEstilos(&parseado, tamano: tamano, cursiva: cursiva)
        salida.append(parseado)
        return salida
    }

    // ── Piezas ──────────────────────────────────────────────────────────────

    private static func fuenteBase(_ tamano: CGFloat, cursiva: Bool) -> Font {
        cursiva ? .cyBody(tamano).italic() : .cyBody(tamano)
    }

    /// Las tres primeras palabras, en versales granate.
    private static func aperturaEnVersales(_ texto: String, tamano: CGFloat) -> AttributedString? {
        guard let primera = texto.first, primera.isLetter || primera == "¿" || primera == "«" else { return nil }
        let partes = texto.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
        guard partes.count == 4 else { return nil }
        var apertura = AttributedString(partes.prefix(3).joined(separator: " ").uppercased() + " ")
        apertura.font = .cyDisplay(tamano * 0.94, weight: .semibold)
        apertura.foregroundColor = .cyGranate
        apertura.tracking = 1.1
        return apertura
    }

    private static func sinApertura(_ texto: String) -> String {
        guard let primera = texto.first, primera.isLetter || primera == "¿" || primera == "«" else { return texto }
        let partes = texto.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
        guard partes.count == 4 else { return texto }
        return String(partes[3])
    }

    /// Los guiones de lista del libro pasan a viñetas de verdad.
    private static func normalizarListas(_ texto: String) -> String {
        texto.split(separator: "\n", omittingEmptySubsequences: false)
            .map { linea -> String in
                let limpia = linea.drop { $0 == " " }
                return limpia.hasPrefix("- ") ? "•\u{2002}" + limpia.dropFirst(2) : String(linea)
            }
            .joined(separator: "\n")
    }

    private static func parsear(_ texto: String) -> AttributedString {
        let opciones = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible)
        return (try? AttributedString(markdown: texto, options: opciones)) ?? AttributedString(texto)
    }

    private static func aplicarEstilos(_ s: inout AttributedString, tamano: CGFloat, cursiva: Bool) {
        // Se recogen primero los rangos y después se aplican, para no mutar
        // la cadena mientras se recorre.
        var negrita: [Range<AttributedString.Index>] = []
        var italica: [Range<AttributedString.Index>] = []
        var claves: [Range<AttributedString.Index>] = []

        for run in s.runs {
            guard let intent = run.inlinePresentationIntent else { continue }
            if intent.contains(.stronglyEmphasized) { negrita.append(run.range) }
            if intent.contains(.emphasized) { italica.append(run.range) }
            if intent.contains(.code) { claves.append(run.range) }
        }

        for r in negrita { s[r].font = .cyBody(tamano, weight: .semibold) }
        for r in italica { s[r].font = .cyBody(tamano).italic() }
        for r in claves {
            // Se limpia la intención de "código" para que SwiftUI no imponga
            // su monoespaciada: las palabras clave van en versalitas serif.
            s[r].inlinePresentationIntent = nil
            s[r].font = .cyDisplay(tamano * 0.86, weight: .semibold)
            s[r].foregroundColor = .cyGranate
            s[r].tracking = 0.5
        }
        if cursiva {
            for r in negrita { s[r].font = .cyBody(tamano, weight: .semibold).italic() }
        }
    }
}
