import SwiftUI
import WebKit

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.palette) private var p

    @AppStorage(SoundPref.key) private var soundEnabled = true
    @AppStorage(HapticPref.key) private var hapticsEnabled = true
    @AppStorage("user_display_name") private var name = ""

    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var showResetAlert = false
    @State private var toast: String?

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: "Settings", leading: .back)

                    nameCard
                    themeCard
                    togglesCard
                    patternsLink
                    dataCard
                    aboutCard

                    Button("Save") {
                        dismissKeyboard()
                        Haptics.shared.notify(.success)
                        toast = "Settings saved"
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
            .onTapGesture { dismissKeyboard() }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [shareURL].compactMap { $0 })
        }
        .alert(isPresented: $showResetAlert) {
            Alert(title: Text("Reset all data?"),
                  message: Text("This removes every session, mood, task and custom pattern. This can't be undone."),
                  primaryButton: .destructive(Text("Reset")) {
                      store.resetAll()
                      Haptics.shared.notify(.warning)
                      toast = "Data reset"
                  },
                  secondaryButton: .cancel())
        }
        .toast($toast)
    }

    // MARK: Name

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your name")
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)
            TextField("Used for your greeting", text: $name)
                .font(AppFont.body)
                .foregroundColor(p.textPrimary)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.cardElevated))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(p.divider, lineWidth: 1))
        }
        .cardStyle()
    }

    // MARK: Theme

    private var themeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Appearance")
            HStack(spacing: 10) {
                ForEach(AppTheme.allCases) { option in
                    let selected = theme.theme == option
                    Button {
                        Haptics.shared.selection()
                        withAnimation(.easeInOut(duration: 0.3)) { theme.theme = option }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: option.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(selected ? p.onAccent : p.textSecondary)
                            Text(option.title)
                                .font(AppFont.caption)
                                .foregroundColor(selected ? p.onAccent : p.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(selected ? p.accent : p.cardElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(selected ? Color.clear : p.divider, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        .cardStyle()
    }

    // MARK: Toggles

    private var togglesCard: some View {
        VStack(spacing: 4) {
            toggleRow(icon: "speaker.wave.2.fill", title: "Sound", tint: p.cyan, isOn: $soundEnabled)
                .onChange(of: soundEnabled) { enabled in
                    if !enabled { SoundManager.shared.stop() }
                }
            Rectangle().fill(p.divider).frame(height: 1)
            toggleRow(icon: "iphone.radiowaves.left.and.right", title: "Haptics", tint: p.accentHi, isOn: $hapticsEnabled)
                .onChange(of: hapticsEnabled) { enabled in
                    if enabled { Haptics.shared.impact(.light) }
                }
        }
        .cardStyle(padding: 14)
    }

    private func toggleRow(icon: String, title: String, tint: Color, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.16)).frame(width: 38, height: 38)
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundColor(tint)
            }
            Text(title).font(AppFont.callout).foregroundColor(p.textPrimary)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().toggleStyle(SwitchToggleStyle(tint: p.accent))
        }
        .padding(.vertical, 6)
    }

    // MARK: Patterns link

    private var patternsLink: some View {
        NavigationLink(destination: PatternsView()) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(p.accent.opacity(0.16)).frame(width: 38, height: 38)
                    Image(systemName: "wind").font(.system(size: 15, weight: .semibold)).foregroundColor(p.accentHi)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Breathing Patterns").font(AppFont.callout).foregroundColor(p.textPrimary)
                    Text("\(store.activePatterns.count) active").font(AppFont.caption).foregroundColor(p.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(p.textMuted)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Data

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Data")
            HStack(spacing: 12) {
                dataButton(icon: "arrow.down.doc.fill", title: "Backup") {
                    store.saveBackupSnapshot()
                    toast = "Backup saved"
                }
                dataButton(icon: "arrow.uturn.backward", title: "Restore") {
                    toast = store.restoreBackupSnapshot() ? "Restored" : "No backup yet"
                }
            }
            Button {
                if let data = store.exportData(), let url = Exporter.writeJSON(data) {
                    shareURL = url
                    showShare = true
                } else {
                    toast = "Export failed"
                }
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                showResetAlert = true
            } label: {
                Label("Reset All Data", systemImage: "trash")
                    .font(AppFont.callout)
                    .foregroundColor(p.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.danger.opacity(0.12)))
            }
            .buttonStyle(PressableStyle())
        }
        .cardStyle()
    }

    private func dataButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.impact(.light)
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundColor(p.accentHi)
                Text(title).font(AppFont.subhead).foregroundColor(p.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.cardElevated))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.divider, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: About

    private var aboutCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Calm Orbit +").font(AppFont.callout).foregroundColor(p.textPrimary)
                Text("Version \(appVersion)").font(AppFont.caption).foregroundColor(p.textMuted)
            }
            Spacer()
            Image(systemName: "circle.hexagonpath.fill").font(.system(size: 24)).foregroundColor(p.accentHi)
        }
        .cardStyle()
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

extension CupolaPilot: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}
