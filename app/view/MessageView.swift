//
//  MessageView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 03/07/2021.
//

import SwiftUI

@MainActor
struct MessageView: ViewModifier {

    private static let displayDuration: TimeInterval = 3

    @Binding var message: Message?

    @State private var dismissTask: Task<Void, Never>? = nil

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if let msg = message {
                Toast(message: msg, onTap: dismiss)
                    .id(msg.id)
                    .padding(.horizontal)
                    .padding(.bottom, Constants.spacing.small)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message?.id)
        .onChange(of: message?.id) { _, newId in
            dismissTask?.cancel()
            guard newId != nil else { return }
            dismissTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(MessageView.displayDuration * 1_000_000_000))
                if !Task.isCancelled {
                    dismiss()
                }
            }
        }
    }

    private func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        if let ok = message?.ok {
            ok()
        }
        message = nil
    }

}

@MainActor
private struct Toast: View {

    let message: Message
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Constants.spacing.small) {
            Text(message.message)
                .accessibilityIdentifier("message")
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, Constants.padding.normal)
        .background(
            RoundedRectangle(cornerRadius: Constants.radius.normal, style: .continuous)
                .fill(message.type.color())
        )
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
        .onTapGesture {
            onTap()
        }
    }

}

extension View {
    func message(message: Binding<Message?>) -> some View {
        modifier(MessageView(message: message))
    }
}
