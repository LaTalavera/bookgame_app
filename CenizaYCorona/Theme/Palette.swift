import SwiftUI
import CoreText

enum TipografiaCeniza {
    private static var registrada = false

    static func registrar() {
        guard !registrada else { return }
        registrada = true
        for nombre in ["EBGaramond-Variable", "Cinzel-Variable"] {
            let url = Bundle.main.url(forResource: nombre, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: nombre, withExtension: "ttf")
            if let url { CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) }
        }
    }
}

extension Color {
    static let cyGranate      = Color(red: 110/255, green:  20/255, blue:  35/255)
    static let cyGranateOsc   = Color(red:  68/255, green:  16/255, blue:  27/255)
    static let cyGranateCla   = Color(red: 139/255, green:  34/255, blue:  51/255)

    static let cyOro          = Color(red: 201/255, green: 162/255, blue:  75/255)
    static let cyOroClaro     = Color(red: 227/255, green: 199/255, blue: 126/255)
    static let cyOroOscuro    = Color(red: 138/255, green: 107/255, blue:  38/255)

    static let cyTinta        = Color(red:  42/255, green:  33/255, blue:  27/255)
    static let cyTintaSuave   = Color(red:  90/255, green:  75/255, blue:  60/255)
    static let cyTintaTenue   = Color(red: 122/255, green: 106/255, blue:  85/255)
    static let cyApagado      = Color(red: 140/255, green: 128/255, blue: 113/255)

    static let cyPergamino    = Color(red: 233/255, green: 221/255, blue: 193/255)
    static let cyPergaminoOsc = Color(red: 220/255, green: 203/255, blue: 166/255)
    static let cyPergaminoCla = Color(red: 244/255, green: 236/255, blue: 216/255)

    static let cyVida         = Color(red: 122/255, green:  21/255, blue:  32/255)
    static let cyCorrupcion   = Color(red:  76/255, green:  42/255, blue:  82/255)
    static let cyNoche        = Color(red:  26/255, green:  12/255, blue:  12/255)
}

extension Font {
    /// Las mismas familias abiertas que usa la edición web.
    static func cyDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom("Cinzel", fixedSize: size).weight(weight)
    }

    static func cyBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("EB Garamond", fixedSize: size).weight(weight)
    }
}
