import SwiftUI

// MARK: - Task Type Model and ViewModel

struct TaskTypeModel: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
}

class TaskTypeViewModel: ObservableObject {
    @Published var types: [TaskTypeModel] = [] {
        didSet { saveTypes() }
    }
    
    private let typesFile = "taskTypes.json"
    
    init() {
        loadTypes()
        if types.isEmpty {
            types = [
                TaskTypeModel(id: UUID(), name: "Personal"),
                TaskTypeModel(id: UUID(), name: "Work"),
                TaskTypeModel(id: UUID(), name: "Urgent")
            ]
            saveTypes()
        }
    }
    
    func addType(name: String) {
        let newType = TaskTypeModel(id: UUID(), name: name)
        types.append(newType)
    }
    
    private func getTypesFileURL() -> URL? {
        let manager = FileManager.default
        if let documents = manager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return documents.appendingPathComponent(typesFile)
        }
        return nil
    }
    
    private func saveTypes() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(types)
            if let url = getTypesFileURL() {
                try data.write(to: url)
            }
        } catch {
            print("Error saving task types: \(error)")
        }
    }
    
    private func loadTypes() {
        do {
            if let url = getTypesFileURL(), FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                types = try decoder.decode([TaskTypeModel].self, from: data)
            }
        } catch {
            print("Error loading task types: \(error)")
        }
    }
}

// MARK: - Updated Task Model

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var dueDate: Date
    var isCompleted: Bool = false
    var type: TaskTypeModel  // New property for task categorization
    
    var isOverdue: Bool {
        return !isCompleted && Date() > dueDate
    }
    
    var isDueSoon: Bool {
        return !isCompleted && dueDate > Date() && dueDate.timeIntervalSince(Date()) < 3600
    }
}

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = [] {
        didSet { saveTasks() }
    }
    
    private let tasksFile = "tasks.json"
    
    init() {
        loadTasks()
        if tasks.isEmpty {
            // Create a default type for legacy tasks.
            let defaultType = TaskTypeModel(id: UUID(), name: "General")
            tasks = [
                Task(id: UUID(), title: "Buy groceries", dueDate: Date().addingTimeInterval(3600), type: defaultType),
                Task(id: UUID(), title: "Finish assignment", dueDate: Date().addingTimeInterval(-3600), type: defaultType)
            ]
        }
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func deleteTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
        }
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    private func saveTasks() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(tasks)
            if let url = getTasksFileURL() {
                try data.write(to: url)
            }
        } catch {
            print("Error saving tasks: \(error)")
        }
    }
    
    private func loadTasks() {
        do {
            if let url = getTasksFileURL(), FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                tasks = try decoder.decode([Task].self, from: data)
            }
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    private func getTasksFileURL() -> URL? {
        let manager = FileManager.default
        if let documents = manager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return documents.appendingPathComponent(tasksFile)
        }
        return nil
    }
}

struct LaunchScreenView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Student 1: Michael Mocioiu - ID: 101459108")
                Text("Student 2: Leonid Serebryannikov - ID: 101468805")
                Text("Student 3: Ivan Zakrevskyi - ID: 101419665")
                
                NavigationLink(destination: TaskListView()) {
                    Text("Go to App")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Welcome")
        }
    }
}

struct TaskListView: View {
    @StateObject var viewModel = TaskViewModel()
    
    var groupedTasks: [String: [Task]] {
        Dictionary(grouping: viewModel.tasks) { task in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: task.dueDate)
        }
    }
    
    var body: some View {
        List {
            ForEach(groupedTasks.keys.sorted(), id: \.self) { date in
                Section(header: Text(date).font(.headline)) {
                    ForEach(groupedTasks[date] ?? []) { task in
                        TaskRow(task: task, viewModel: viewModel)
                    }
                }
            }
        }
        .navigationTitle("To-Do List")
        .toolbar {
            NavigationLink(destination: TaskCreateView(viewModel: viewModel, typeViewModel: TaskTypeViewModel())) {
                Image(systemName: "plus")
            }
        }
    }
}

struct TaskRow: View {
    var task: Task
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                Text(task.type.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(task.dueDate, style: .time)
                .foregroundColor(task.isDueSoon ? .orange : .gray)
            Button(action: {
                viewModel.toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

struct TaskCreateView: View {
    @ObservedObject var viewModel: TaskViewModel
    @ObservedObject var typeViewModel: TaskTypeViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var selectedType: TaskTypeModel

    init(viewModel: TaskViewModel, typeViewModel: TaskTypeViewModel) {
        self.viewModel = viewModel
        self.typeViewModel = typeViewModel
        _selectedType = State(initialValue: typeViewModel.types.first ?? TaskTypeModel(id: UUID(), name: "Default"))
    }

    var body: some View {
        Form {
            Section(header: Text("Task Info")) {
                TextField("Task Title", text: $title)
                DatePicker("Due Date & Time", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                Picker("Task Type", selection: $selectedType) {
                    ForEach(typeViewModel.types) { type in
                        Text(type.name).tag(type)
                    }
                }
                NavigationLink("Add New Task Type", destination: AddTaskTypeView(typeViewModel: typeViewModel))
            }
            Button("Save") {
                let newTask = Task(id: UUID(), title: title, dueDate: dueDate, type: selectedType)
                viewModel.addTask(newTask)
                presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationTitle("New Task")
    }
}

struct AddTaskTypeView: View {
    @ObservedObject var typeViewModel: TaskTypeViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var typeName: String = ""
    
    var body: some View {
        Form {
            TextField("New Task Type", text: $typeName)
            Button("Save") {
                if !typeName.isEmpty {
                    typeViewModel.addType(name: typeName)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle("Add Task Type")
    }
}
