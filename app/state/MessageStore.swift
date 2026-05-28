//
//  MessageStore.swift
//  parkeerassistent
//

import Foundation
import SwiftUI

@MainActor
class MessageStore: ObservableObject {

    static let shared = MessageStore()

    @Published var message: Message? = nil

    private init() {}

    nonisolated func addMessage(_ message: String?, type: Type, ok: (() -> Void)? = nil) {
        guard let message = message else {
            Log.warning("MessageStore.addMessage called with nil message")
            return
        }
        Task { @MainActor in
            self.message = Message(message: message, type: type, ok: ok)
        }
    }

}

struct Message {
    var message: String
    var type: Type
    var ok: (() -> Void)?
}

enum Type {
    case SUCCESS
    case INFO
    case WARN
    case ERROR

    func color() -> Color {
        switch self {
        case .SUCCESS:
            return Color.ui.success
        case .INFO:
            return Color.ui.info
        case .WARN:
            return Color.ui.warning
        case .ERROR:
            return Color.ui.danger
        }
    }
}
