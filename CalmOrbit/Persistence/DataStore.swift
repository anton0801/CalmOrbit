//
//  DataStore.swift
//  CalmOrbit
//
//  Single source of truth for the whole app. Holds every collection as a
//  @Published array, persists each to UserDefaults as JSON on mutation, and
//  exposes the derived analytics used by the dashboard, reports and streak.
//

import SwiftUI
import Combine

final class DataStore: ObservableObject {

    // MARK: Persisted collections

    @Published var patterns: [BreathingPattern] { didSet { persist(patterns, Keys.patterns) } }
    @Published var programs: [Program] { didSet { persist(programs, Keys.programs) } }
    @Published var records: [SessionRecord] { didSet { persist(records, Keys.records) } }
    @Published var moods: [MoodEntry] { didSet { persist(moods, Keys.moods) } }
    @Published var tasks: [HabitTask] { didSet { persist(tasks, Keys.tasks) } }
    @Published var recommendations: [Recommendation] { didSet { persist(recommendations, Keys.recs) } }
    @Published var sounds: [SoundOption] { didSet { persist(sounds, Keys.sounds) } }

    @Published var lastPatternID: UUID? {
        didSet { UserDefaults.standard.set(lastPatternID?.uuidString, forKey: Keys.lastPattern) }
    }

    private enum Keys {
        static let patterns = "store_patterns"
        static let programs = "store_programs"
        static let records = "store_records"
        static let moods = "store_moods"
        static let tasks = "store_tasks"
        static let recs = "store_recommendations"
        static let sounds = "store_sounds"
        static let lastPattern = "store_last_pattern"
        static let backup = "store_backup_snapshot"
        static let seeded = "store_did_seed"
    }

    // MARK: Init

    init() {
        let didSeed = UserDefaults.standard.bool(forKey: Keys.seeded)
        patterns = DataStore.load([BreathingPattern].self, Keys.patterns) ?? SeedData.patterns
        programs = DataStore.load([Program].self, Keys.programs) ?? SeedData.programs
        records = DataStore.load([SessionRecord].self, Keys.records) ?? []
        moods = DataStore.load([MoodEntry].self, Keys.moods) ?? []
        tasks = DataStore.load([HabitTask].self, Keys.tasks) ?? []
        recommendations = DataStore.load([Recommendation].self, Keys.recs) ?? SeedData.recommendations
        sounds = DataStore.load([SoundOption].self, Keys.sounds) ?? SeedData.sounds
        if let raw = UserDefaults.standard.string(forKey: Keys.lastPattern) {
            lastPatternID = UUID(uuidString: raw)
        }
        if !didSeed {
            UserDefaults.standard.set(true, forKey: Keys.seeded)
            persistAll()
        }
    }

    // MARK: Persistence helpers

    private static func load<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func persist<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func persistAll() {
        persist(patterns, Keys.patterns)
        persist(programs, Keys.programs)
        persist(records, Keys.records)
        persist(moods, Keys.moods)
        persist(tasks, Keys.tasks)
        persist(recommendations, Keys.recs)
        persist(sounds, Keys.sounds)
    }

    // MARK: - Patterns

    var activePatterns: [BreathingPattern] { patterns.filter { !$0.isArchived } }

    func pattern(_ id: UUID?) -> BreathingPattern? {
        guard let id = id else { return nil }
        return patterns.first { $0.id == id }
    }

    func addPattern(_ pattern: BreathingPattern) { patterns.insert(pattern, at: 0) }

    func updatePattern(_ pattern: BreathingPattern) {
        if let idx = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[idx] = pattern
        }
    }

    func deletePattern(_ pattern: BreathingPattern) {
        patterns.removeAll { $0.id == pattern.id }
    }

    func toggleArchivePattern(_ pattern: BreathingPattern) {
        if let idx = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[idx].isArchived.toggle()
        }
    }

    // MARK: - Programs

    var activePrograms: [Program] { programs.filter { !$0.isArchived } }

    func program(_ id: UUID?) -> Program? {
        guard let id = id else { return nil }
        return programs.first { $0.id == id }
    }

    func addProgram(_ program: Program) { programs.insert(program, at: 0) }

    func updateProgram(_ program: Program) {
        if let idx = programs.firstIndex(where: { $0.id == program.id }) {
            programs[idx] = program
        }
    }

    func deleteProgram(_ program: Program) {
        programs.removeAll { $0.id == program.id }
        // Detach records pointing at the deleted program.
        for idx in records.indices where records[idx].programID == program.id {
            records[idx].programID = nil
        }
    }

    func toggleArchiveProgram(_ program: Program) {
        if let idx = programs.firstIndex(where: { $0.id == program.id }) {
            programs[idx].isArchived.toggle()
        }
    }

    func sessionsCount(for program: Program) -> Int {
        records.filter { $0.programID == program.id && $0.category == .session }.count
    }

    func minutes(for program: Program) -> Double {
        records.filter { $0.programID == program.id && $0.category == .session }
            .reduce(0) { $0 + $1.valueMinutes }
    }

    // MARK: - Records

    var recordsSorted: [SessionRecord] { records.sorted { $0.date > $1.date } }

    func record(_ id: UUID?) -> SessionRecord? {
        guard let id = id else { return nil }
        return records.first { $0.id == id }
    }

    func addRecord(_ record: SessionRecord) {
        records.insert(record, at: 0)
        if let mood = record.mood {
            // Log a matching mood entry so the mood tracker reflects sessions.
            addMood(MoodEntry(date: record.date, mood: mood,
                              note: "After \(record.title)"))
        }
    }

    func updateRecord(_ record: SessionRecord) {
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records[idx] = record
        }
    }

    func deleteRecord(_ record: SessionRecord) {
        records.removeAll { $0.id == record.id }
    }

    func duplicate(_ record: SessionRecord) {
        var copy = record
        copy.id = UUID()
        copy.title = record.title + " (copy)"
        copy.date = Date()
        copy.createdAt = Date()
        records.insert(copy, at: 0)
    }

    // MARK: - Moods

    var moodsSorted: [MoodEntry] { moods.sorted { $0.date > $1.date } }

    func addMood(_ entry: MoodEntry) { moods.insert(entry, at: 0) }

    func deleteMood(_ entry: MoodEntry) { moods.removeAll { $0.id == entry.id } }

    var moodToday: MoodEntry? {
        let cal = Calendar.current
        return moodsSorted.first { cal.isDateInToday($0.date) }
    }

    func mood(on date: Date) -> MoodType? {
        let cal = Calendar.current
        return moodsSorted.first { cal.isDate($0.date, inSameDayAs: date) }?.mood
    }

    func moments(for mood: MoodType?) -> [MoodEntry] {
        guard let mood = mood else { return moodsSorted }
        return moodsSorted.filter { $0.mood == mood }
    }

    // MARK: - Tasks

    var tasksSorted: [HabitTask] { tasks.sorted { $0.dueDate < $1.dueDate } }

    func addTask(_ task: HabitTask) { tasks.append(task) }

    func updateTask(_ task: HabitTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        }
    }

    func toggleTaskDone(_ task: HabitTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isDone.toggle()
        }
    }

    func deleteTask(_ task: HabitTask) { tasks.removeAll { $0.id == task.id } }

    func tasks(filter: TaskFilter, reference: Date = Date()) -> [HabitTask] {
        let cal = Calendar.current
        switch filter {
        case .all:    return tasksSorted
        case .today:  return tasksSorted.filter { cal.isDate($0.dueDate, inSameDayAs: reference) }
        case .missed: return tasksSorted.filter { $0.isMissed(reference: reference) }
        case .done:   return tasksSorted.filter { $0.isDone }
        }
    }

    // MARK: - Recommendations

    var activeRecommendations: [Recommendation] { recommendations.filter { !$0.isDismissed } }
    var savedRecommendations: [Recommendation] { recommendations.filter { $0.isSaved && !$0.isDismissed } }

    func toggleSaveRecommendation(_ rec: Recommendation) {
        if let idx = recommendations.firstIndex(where: { $0.id == rec.id }) {
            recommendations[idx].isSaved.toggle()
        }
    }

    func dismissRecommendation(_ rec: Recommendation) {
        if let idx = recommendations.firstIndex(where: { $0.id == rec.id }) {
            recommendations[idx].isDismissed = true
        }
    }

    func taskFromRecommendation(_ rec: Recommendation) {
        let due = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        addTask(HabitTask(title: rec.title, detail: rec.body, dueDate: due, reminderEnabled: false))
    }

    // MARK: - Analytics

    func isToday(_ date: Date) -> Bool { Calendar.current.isDateInToday(date) }

    var todayCalmMinutes: Double {
        records.filter { $0.category == .session && isToday($0.date) }
            .reduce(0) { $0 + $1.valueMinutes }
    }

    var totalCalmMinutes: Double {
        records.filter { $0.category == .session }.reduce(0) { $0 + $1.valueMinutes }
    }

    var totalSessions: Int { records.filter { $0.category == .session }.count }

    func minutes(on date: Date) -> Double {
        records.filter { $0.category == .session && Calendar.current.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.valueMinutes }
    }

    /// Calm minutes for the last `days` days, oldest first.
    func minutesByDay(days: Int) -> [DayValue] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            return DayValue(date: day, value: minutes(on: day))
        }
    }

    /// Average mood score per day for the last `days` days, oldest first.
    func moodTrend(days: Int) -> [DayValue] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let entries = moods.filter { cal.isDate($0.date, inSameDayAs: day) }
            let avg = entries.isEmpty ? 0 : entries.reduce(0.0) { $0 + $1.mood.score } / Double(entries.count)
            return DayValue(date: day, value: avg)
        }
    }

    func sessionsByProgram() -> [ProgramCount] {
        activePrograms.map { program in
            ProgramCount(program: program, count: sessionsCount(for: program))
        }
    }

    private var sessionDays: Set<Date> {
        let cal = Calendar.current
        return Set(records.filter { $0.category == .session }.map { cal.startOfDay(for: $0.date) })
    }

    var currentStreak: Int {
        let cal = Calendar.current
        let days = sessionDays
        if days.isEmpty { return 0 }
        var cursor = cal.startOfDay(for: Date())
        if !days.contains(cursor) {
            // Today not active yet — count the run ending yesterday.
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
            if !days.contains(cursor) { return 0 }
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    var bestStreak: Int {
        let cal = Calendar.current
        let sorted = sessionDays.sorted()
        guard !sorted.isEmpty else { return 0 }
        var best = 1
        var run = 1
        for i in 1..<sorted.count {
            if let prev = cal.date(byAdding: .day, value: 1, to: sorted[i - 1]),
               cal.isDate(prev, inSameDayAs: sorted[i]) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    func isStreakDay(_ date: Date) -> Bool {
        sessionDays.contains(Calendar.current.startOfDay(for: date))
    }

    var suggestedPattern: BreathingPattern? {
        let hour = Calendar.current.component(.hour, from: Date())
        let preferredName: String
        switch hour {
        case 5..<11:  preferredName = "Quick Reset"
        case 11..<17: preferredName = "Box Breathing"
        case 17..<21: preferredName = "Calm Wave"
        default:      preferredName = "4-7-8 Relax"
        }
        return activePatterns.first { $0.name == preferredName } ?? activePatterns.first
    }

    // MARK: - Backup / export / reset

    func makeBackup() -> AppBackup {
        AppBackup(patterns: patterns, programs: programs, records: records,
                  moods: moods, tasks: tasks, recommendations: recommendations, sounds: sounds)
    }

    func exportData() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(makeBackup())
    }

    func saveBackupSnapshot() {
        if let data = try? JSONEncoder().encode(makeBackup()) {
            UserDefaults.standard.set(data, forKey: Keys.backup)
        }
    }

    var hasBackup: Bool { UserDefaults.standard.data(forKey: Keys.backup) != nil }

    func restoreBackupSnapshot() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Keys.backup),
              let backup = try? JSONDecoder().decode(AppBackup.self, from: data) else { return false }
        apply(backup)
        return true
    }

    func apply(_ backup: AppBackup) {
        patterns = backup.patterns
        programs = backup.programs
        records = backup.records
        moods = backup.moods
        tasks = backup.tasks
        recommendations = backup.recommendations
        sounds = backup.sounds.isEmpty ? SeedData.sounds : backup.sounds
    }

    func resetAll() {
        patterns = SeedData.patterns
        programs = SeedData.programs
        records = []
        moods = []
        tasks = []
        recommendations = SeedData.recommendations
        sounds = SeedData.sounds
        lastPatternID = nil
    }
}

// MARK: - Supporting value types

struct DayValue: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

struct ProgramCount: Identifiable {
    let program: Program
    let count: Int
    var id: UUID { program.id }
}

enum TaskFilter: String, CaseIterable, Identifiable {
    case all, today, missed, done
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all:    return "All"
        case .today:  return "Today"
        case .missed: return "Missed"
        case .done:   return "Done"
        }
    }
}

struct AppBackup: Codable {
    var patterns: [BreathingPattern]
    var programs: [Program]
    var records: [SessionRecord]
    var moods: [MoodEntry]
    var tasks: [HabitTask]
    var recommendations: [Recommendation]
    var sounds: [SoundOption]
}
