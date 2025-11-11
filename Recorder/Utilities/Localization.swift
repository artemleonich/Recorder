import Foundation
import SwiftUI

enum LocalizationHelper {
    static func key(_ rawValue: String) -> LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    static func string(_ key: String, locale: Locale) -> String {
        String(localized: key, bundle: .main, locale: locale)
    }

    static func formattedString(_ key: String, locale: Locale, _ arguments: CVarArg...) -> String {
        let format = string(key, locale: locale)
        return String(format: format, locale: locale, arguments: arguments)
    }
}
