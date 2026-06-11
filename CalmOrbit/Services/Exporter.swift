//
//  Exporter.swift
//  CalmOrbit
//
//  Builds shareable artifacts: a one-page PDF calm report and a JSON data
//  export. Both return a temporary file URL to feed into the share sheet.
//

import UIKit

enum Exporter {

    static func writeJSON(_ data: Data, name: String = "CalmOrbit-Data.json") -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    static func makeReportPDF(store: DataStore) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CalmOrbit-Report.pdf")

        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: UIColor(red: 0.545, green: 0.361, blue: 0.965, alpha: 1)
        ]
        let headAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        let bodyAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.black
        ]

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                var y: CGFloat = 56
                let x: CGFloat = 48

                ("Calm Orbit + — Calm Report" as NSString)
                    .draw(at: CGPoint(x: x, y: y), withAttributes: titleAttr)
                y += 44

                let df = DateFormatter(); df.dateStyle = .long
                ("Generated \(df.string(from: Date()))" as NSString)
                    .draw(at: CGPoint(x: x, y: y), withAttributes: bodyAttr)
                y += 40

                ("Overview" as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: headAttr)
                y += 26

                let rows: [(String, String)] = [
                    ("Total calm minutes", String(format: "%.0f", store.totalCalmMinutes)),
                    ("Total sessions", "\(store.totalSessions)"),
                    ("Current streak", "\(store.currentStreak) days"),
                    ("Best streak", "\(store.bestStreak) days"),
                    ("Today's calm minutes", String(format: "%.0f", store.todayCalmMinutes)),
                    ("Mood today", store.moodToday?.mood.title ?? "Not logged"),
                    ("Active programs", "\(store.activePrograms.count)"),
                    ("Breathing patterns", "\(store.activePatterns.count)")
                ]
                for (label, value) in rows {
                    ("• \(label): \(value)" as NSString)
                        .draw(at: CGPoint(x: x, y: y), withAttributes: bodyAttr)
                    y += 24
                }

                y += 16
                ("Last 7 days" as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: headAttr)
                y += 26
                let df2 = DateFormatter(); df2.dateFormat = "EEE d MMM"
                for day in store.minutesByDay(days: 7) {
                    let line = "\(df2.string(from: day.date)) — \(Int(day.value)) min"
                    (line as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: bodyAttr)
                    y += 22
                }

                y += 20
                ("Keep breathing. Slow down." as NSString)
                    .draw(at: CGPoint(x: x, y: y), withAttributes: headAttr)
            }
            return url
        } catch {
            return nil
        }
    }
}
