//
//  RecommendationsView.swift
//  CalmOrbit
//
//  Curated tips. Each can be added to tasks, saved or dismissed — all of
//  which mutate the store.
//

import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @State private var toast: String?

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ScreenHeader(title: "Recommendations", subtitle: "Tips for calmer days", leading: .back)

                    if store.activeRecommendations.isEmpty {
                        EmptyStateView(icon: "lightbulb",
                                       title: "All caught up",
                                       message: "You've reviewed every tip. New ideas will appear here.")
                    } else {
                        ForEach(store.activeRecommendations) { rec in
                            recCard(rec)
                        }
                    }
                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .toast($toast)
    }

    private func recCard(_ rec: Recommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(p.accent.opacity(0.16)).frame(width: 44, height: 44)
                    Image(systemName: rec.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(p.accentHi)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(rec.category.uppercased())
                        .font(AppFont.tiny)
                        .foregroundColor(p.cyan)
                    Text(rec.title)
                        .font(AppFont.headline)
                        .foregroundColor(p.textPrimary)
                }
                Spacer()
                Button {
                    store.toggleSaveRecommendation(rec)
                    Haptics.shared.impact(.light)
                    toast = rec.isSaved ? "Removed from saved" : "Saved"
                } label: {
                    Image(systemName: rec.isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(rec.isSaved ? p.warning : p.textMuted)
                }
                .buttonStyle(PressableStyle())
            }

            Text(rec.body)
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)

            if let pattern = rec.suggestedPattern {
                HStack(spacing: 6) {
                    Image(systemName: "wind").font(.system(size: 12, weight: .semibold))
                    Text(pattern).font(AppFont.caption)
                }
                .foregroundColor(p.accentHi)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(p.accent.opacity(0.14)))
            }

            HStack(spacing: 12) {
                Button {
                    store.taskFromRecommendation(rec)
                    Haptics.shared.notify(.success)
                    toast = "Added to tasks"
                } label: { Label("Add to Tasks", systemImage: "checklist") }
                    .buttonStyle(SoftButtonStyle())

                Button {
                    withAnimation { store.dismissRecommendation(rec) }
                    Haptics.shared.selection()
                    toast = "Dismissed"
                } label: {
                    Text("Dismiss")
                        .font(AppFont.subhead)
                        .foregroundColor(p.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.divider, lineWidth: 1))
                }
                .buttonStyle(PressableStyle())
            }
        }
        .cardStyle()
    }
}
