//
//  LogMoodView.swift
//  CalmOrbit
//
//  Sheet for logging a mood entry. Reused by the dashboard, mood tab and
//  calendar.
//

import SwiftUI

struct LogMoodView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @Environment(\.presentationMode) private var presentationMode

    var date: Date = Date()
    var onSaved: (() -> Void)?

    @State private var mood: MoodType?
    @State private var note = ""

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ScreenHeader(title: "How do you feel?", leading: .close)

                    ZStack {
                        Circle()
                            .fill((mood?.color ?? p.accent).opacity(0.18))
                            .frame(width: 120, height: 120)
                        Text(mood?.emoji ?? "🫧")
                            .font(.system(size: 56))
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: mood)

                    Text(mood?.title ?? "Pick a mood")
                        .font(AppFont.headline)
                        .foregroundColor(p.textPrimary)

                    MoodPicker(selection: $mood)

                    NotesField(title: "Note", placeholder: "What's on your mind?", text: $note)

                    Button("Save Mood") { save() }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(mood == nil)

                    Color.clear.frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
            .onTapGesture { dismissKeyboard() }
        }
    }

    private func save() {
        guard let mood = mood else { return }
        dismissKeyboard()
        store.addMood(MoodEntry(date: date, mood: mood, note: note))
        Haptics.shared.notify(.success)
        onSaved?()
        presentationMode.wrappedValue.dismiss()
    }
}
