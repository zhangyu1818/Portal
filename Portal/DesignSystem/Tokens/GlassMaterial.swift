import SwiftUI

enum GlassMaterial {
    static let chrome: Glass = .clear
    static let surface: Glass = .regular
    static let card: Glass = .regular
    static let popover: Glass = .regular
    static let interactive: Glass = .regular.interactive()
    static let inlineRow: Glass = .regular.interactive()
}
