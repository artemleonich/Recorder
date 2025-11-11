import Foundation
import SwiftUI

enum LocalizationHelper {
    static func key(_ rawValue: String) -> LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    static func string(_ key: String, locale: Locale) -> String {
        if let bundle = bundle(for: locale) {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }

    static func formattedString(_ key: String, locale: Locale, _ arguments: CVarArg...) -> String {
        let format = string(key, locale: locale)
        return String(format: format, locale: locale, arguments: arguments)
    }

    private static func bundle(for locale: Locale) -> Bundle? {
        for identifier in candidateIdentifiers(for: locale) {
            if let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return nil
    }

    private static func candidateIdentifiers(for locale: Locale) -> [String] {
        var identifiers: [String] = []
        let localeIdentifier = locale.identifier
        identifiers.append(localeIdentifier)

        let components = localeIdentifier.split(separator: "_")
        if let languageCode = components.first {
            let code = String(languageCode)
            if !identifiers.contains(code) {
                identifiers.append(code)
            }
        }

        if let explicitLanguageCode = locale.languageCode,
           !identifiers.contains(explicitLanguageCode) {
            identifiers.append(explicitLanguageCode)
        }

        return identifiers
    }
}
