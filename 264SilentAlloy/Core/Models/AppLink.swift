import Foundation

enum AppLink: String {
    case privacyPolicy = "https://silent264alloy.site/privacy/344"
    case termsOfUse = "https://silent264alloy.site/terms/344"

    var url: URL? {
        URL(string: rawValue)
    }
}
