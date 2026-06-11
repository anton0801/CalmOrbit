//
//  ReportsViewModel.swift
//  CalmOrbit
//
//  Holds the selected reporting range. Series are computed from the DataStore
//  in the view so they always reflect the latest data.
//

import SwiftUI
import Combine

enum ReportRange: Int, CaseIterable, Identifiable {
    case week = 7
    case twoWeeks = 14
    case month = 30
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .week:     return "7 days"
        case .twoWeeks: return "14 days"
        case .month:    return "30 days"
        }
    }
    var days: Int { rawValue }
}

final class ReportsViewModel: ObservableObject {
    @Published var range: ReportRange = .week
    @Published var shareURL: URL?
    @Published var isSharing = false

    func exportPDF(store: DataStore) {
        if let url = Exporter.makeReportPDF(store: store) {
            shareURL = url
            isSharing = true
        }
    }

    func shareData(store: DataStore) {
        if let data = store.exportData(), let url = Exporter.writeJSON(data) {
            shareURL = url
            isSharing = true
        }
    }
}
