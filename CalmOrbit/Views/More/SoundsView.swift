//
//  SoundsView.swift
//  CalmOrbit
//
//  Ambient sound player. Generates audio in real time via SoundManager and
//  respects the global sound setting.
//

import SwiftUI

struct SoundsView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @ObservedObject private var sound = SoundManager.shared
    @AppStorage(SoundPref.key) private var soundEnabled = true

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ScreenHeader(title: "Sounds", subtitle: "Ambient calm", leading: .back)

                    if !soundEnabled {
                        infoBanner
                    }

                    volumeCard

                    ForEach(store.sounds) { option in
                        soundRow(option)
                    }
                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .onDisappear { sound.stop() }
    }

    private var infoBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.slash.fill").foregroundColor(p.warning)
            Text("Sound is off. Enable it in Settings to play.")
                .font(AppFont.caption)
                .foregroundColor(p.textSecondary)
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.warning.opacity(0.12)))
    }

    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Volume")
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill").foregroundColor(p.textMuted)
                Slider(value: $sound.volume, in: 0...1)
                    .accentColor(p.accent)
                Image(systemName: "speaker.wave.3.fill").foregroundColor(p.textMuted)
            }
        }
        .cardStyle()
    }

    private func soundRow(_ option: SoundOption) -> some View {
        let isPlaying = sound.currentSoundID == option.id
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(option.color.opacity(0.2)).frame(width: 50, height: 50)
                Image(systemName: option.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(option.color)
                if isPlaying {
                    Circle()
                        .stroke(option.color, lineWidth: 2)
                        .frame(width: 58, height: 58)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(option.name)
                    .font(AppFont.headline)
                    .foregroundColor(p.textPrimary)
                Text(isPlaying ? "Playing…" : option.subtitle)
                    .font(AppFont.caption)
                    .foregroundColor(isPlaying ? option.color : p.textSecondary)
            }
            Spacer()
            Button {
                Haptics.shared.impact(.light)
                sound.toggle(option)
            } label: {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(soundEnabled ? p.onAccent : p.textMuted)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(soundEnabled ? option.color : p.cardElevated))
            }
            .buttonStyle(PressableStyle())
            .disabled(!soundEnabled)
        }
        .cardStyle(padding: 14)
        .opacity(soundEnabled ? 1 : 0.6)
    }
}
