//
//  TasksView.swift
//  CalmOrbit
//
//  Habit/reminder tasks with filters and an add sheet. Marking done can cancel
//  a scheduled reminder.
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p

    @State private var filter: TaskFilter = .all
    @State private var showAdd = false
    @State private var toast: String?

    private var tasks: [HabitTask] { store.tasks(filter: filter) }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ScreenHeader(title: "Tasks",
                                 subtitle: "Reminders & habits",
                                 leading: .back,
                                 trailingSystemImage: "plus",
                                 trailingAction: { showAdd = true })

                    SegmentedPicker(items: TaskFilter.allCases, selection: $filter) { $0.title }

                    if tasks.isEmpty {
                        EmptyStateView(icon: "checklist",
                                       title: "No tasks",
                                       message: "Add a reminder to build a calm habit.")
                    } else {
                        ForEach(tasks) { task in
                            taskRow(task)
                        }
                    }
                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAdd) {
            AddTaskView().environmentObject(store).environment(\.palette, p)
        }
        .toast($toast)
    }

    private func taskRow(_ task: HabitTask) -> some View {
        let missed = task.isMissed()
        return HStack(spacing: 12) {
            Button {
                store.toggleTaskDone(task)
                if !task.isDone {
                    Haptics.shared.notify(.success)
                    NotificationManager.shared.cancel(id: task.notificationID)
                } else {
                    Haptics.shared.selection()
                }
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.isDone ? p.success : p.textMuted)
            }
            .buttonStyle(PressableStyle())

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(AppFont.callout)
                    .foregroundColor(task.isDone ? p.textMuted : p.textPrimary)
                    .strikethrough(task.isDone)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Image(systemName: task.repeatsDaily ? "repeat" : "clock")
                        .font(.system(size: 11))
                    Text(dueString(task.dueDate))
                        .font(AppFont.caption)
                    if missed {
                        Text("Missed")
                            .font(AppFont.tiny)
                            .foregroundColor(p.danger)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(p.danger.opacity(0.15)))
                    }
                    if task.reminderEnabled {
                        Image(systemName: "bell.fill").font(.system(size: 10)).foregroundColor(p.cyan)
                    }
                }
                .foregroundColor(p.textMuted)
            }
            Spacer()
            Menu {
                Button {
                    store.deleteTask(task)
                    NotificationManager.shared.cancel(id: task.notificationID)
                    Haptics.shared.notify(.warning)
                    toast = "Deleted"
                } label: { Label("Delete", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(p.textMuted)
                    .frame(width: 34, height: 34)
            }
        }
        .cardStyle(padding: 14)
    }

    private func dueString(_ date: Date) -> String {
        let f = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            f.dateFormat = "'Today' HH:mm"
        } else if Calendar.current.isDateInTomorrow(date) {
            f.dateFormat = "'Tomorrow' HH:mm"
        } else {
            f.dateFormat = "MMM d · HH:mm"
        }
        return f.string(from: date)
    }
}

// MARK: - Add task

struct AddTaskView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @Environment(\.presentationMode) private var presentationMode

    @State private var title = ""
    @State private var detail = ""
    @State private var dueDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var repeatsDaily = false
    @State private var reminder = true

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: "New Task", leading: .close)

                    AppTextField(title: "Title", placeholder: "e.g. Evening breathing", text: $title)
                    AppTextField(title: "Detail", placeholder: "Optional detail", text: $detail)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("When")
                            .font(AppFont.subhead)
                            .foregroundColor(p.textSecondary)
                        DatePicker("", selection: $dueDate)
                            .labelsHidden()
                            .datePickerStyle(CompactDatePickerStyle())
                            .accentColor(p.accent)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.card))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(p.divider, lineWidth: 1))
                    }

                    toggleRow(title: "Repeat daily", isOn: $repeatsDaily, icon: "repeat")
                    toggleRow(title: "Reminder notification", isOn: $reminder, icon: "bell.fill")

                    Button("Save Task") { save() }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!isValid)

                    Color.clear.frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
            .onTapGesture { dismissKeyboard() }
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(p.accentHi).frame(width: 24)
            Text(title).font(AppFont.callout).foregroundColor(p.textPrimary)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().toggleStyle(SwitchToggleStyle(tint: p.accent))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.card))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(p.divider, lineWidth: 1))
    }

    private func save() {
        guard isValid else { return }
        dismissKeyboard()
        let task = HabitTask(title: title.trimmingCharacters(in: .whitespaces),
                             detail: detail, dueDate: dueDate,
                             repeatsDaily: repeatsDaily, reminderEnabled: reminder)
        store.addTask(task)

        if reminder {
            NotificationManager.shared.requestAuthorization { granted in
                guard granted else { return }
                if repeatsDaily {
                    let (h, m) = NotificationManager.hourMinute(from: dueDate)
                    NotificationManager.shared.scheduleDaily(id: task.notificationID,
                                                             title: "Calm Orbit +",
                                                             body: task.title, hour: h, minute: m)
                } else {
                    NotificationManager.shared.scheduleAt(id: task.notificationID,
                                                          title: "Calm Orbit +",
                                                          body: task.title, date: dueDate)
                }
            }
        }
        Haptics.shared.notify(.success)
        presentationMode.wrappedValue.dismiss()
    }
}
