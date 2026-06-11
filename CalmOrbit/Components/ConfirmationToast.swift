//
//  ConfirmationToast.swift
//  CalmOrbit
//
//  A lightweight confirmation toast + a `.toast(_:)` modifier. Bind an
//  optional String; setting it shows the toast which auto-dismisses.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    @Environment(\.palette) private var p

    func body(content: Content) -> some View {
        ZStack {
            content
            if let message = message {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(p.success)
                        Text(message)
                            .font(AppFont.callout)
                            .foregroundColor(p.textPrimary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .background(Capsule().fill(p.cardElevated))
                    .overlay(Capsule().stroke(p.divider, lineWidth: 1))
                    .shadow(color: p.shadow, radius: 14, x: 0, y: 6)
                    .padding(.bottom, 110)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                self.message = nil
                            }
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
