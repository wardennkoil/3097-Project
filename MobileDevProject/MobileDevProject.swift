import SwiftUI

// MARK: - Task Type Model and ViewModel

struct TaskTypeModel: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
}

class TaskTypeViewModel: ObservableObject {
    @Published var types: [TaskTypeModel] = [] {
        didSet {
            saveTypes()
        }
    }
    
    private let typesFile = "taskTypes.json"
    
    init() {
        loadTypes()
        if types.isEmpty {
            // Prepopulate with default types if no file exists
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


// MARK: - Task Model

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var dueDate: Date
    var type: TaskTypeModel
    var isCompleted: Bool = false
    
    // Computed property to check if the task is overdue.
    var isOverdue: Bool {
        return !isCompleted && Date() > dueDate
    }
    
    // Computed property to check if the task is due soon (e.g., within the next hour)
    var isDueSoon: Bool {
        return !isCompleted && dueDate > Date() && dueDate.timeIntervalSince(Date()) < 3600
    }
}

// MARK: - TaskViewModel with Persistence

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = [] {
        didSet {
            saveTasks()
        }
    }
    
    private let tasksFile = "tasks.json"
    
    init() {
        loadTasks()
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
    
    func updateTask(_ task: Task, title: String, dueDate: Date, type: TaskTypeModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].title = title
            tasks[index].dueDate = dueDate
            tasks[index].type = type
        }
    }
    
    // Save tasks to persistent storage
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
    
    // Load tasks from persistent storage
    private func loadTasks() {
        do {
            if let url = getTasksFileURL(), FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                tasks = try decoder.decode([Task].self, from: data)
            } else {
                // Preload with sample tasks if file does not exist
                tasks = [
                    Task(id: UUID(), title: "Buy groceries", dueDate: Date().addingTimeInterval(3600), type: TaskTypeModel(id: UUID(), name: "Personal")),
                    Task(id: UUID(), title: "Finish assignment", dueDate: Date().addingTimeInterval(-3600), type: TaskTypeModel(id: UUID(), name: "Urgent"))
                ]
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

// MARK: - Launch Screen

@main
struct ToDoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                LaunchScreenView()
            }
        }
    }
}

struct LaunchScreenView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Student 1: Michael Mocioiu - ID: 101459108")
            Text("Student 2: Leonid Serebryannikov - ID: 101468805")
            Text("Student 3: Ivan Zakrevskyi - ID: 101419665")
            
            NavigationLink(destination: MainTasksView()) {
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

// MARK: - Main Tasks View with TabView

struct MainTasksView: View {
    @StateObject var taskViewModel = TaskViewModel()
    @StateObject var taskTypeViewModel = TaskTypeViewModel()

    var body: some View {
        TabView {
            ActiveTasksView(viewModel: taskViewModel, typeViewModel: taskTypeViewModel)
                .tabItem {
                    Label("Active", systemImage: "list.bullet")
                }
            CompletedTasksView(viewModel: taskViewModel, typeViewModel: taskTypeViewModel)
                .tabItem {
                    Label("Completed", systemImage: "checkmark.circle")
                }
        }
    }
}

// MARK: - Active Tasks View

struct ActiveTasksView: View {
    @ObservedObject var viewModel: TaskViewModel
    @ObservedObject var typeViewModel: TaskTypeViewModel

    var activeTasks: [Task] { viewModel.tasks.filter { !$0.isCompleted } }

    var body: some View {
        NavigationView {
            List {
                ForEach(activeTasks) { task in
                    NavigationLink(destination: EditTaskView(task: task, viewModel: viewModel, typeViewModel: typeViewModel)) {
                        TaskRow(task: task, viewModel: viewModel)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteTask(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Active Tasks")
            .toolbar {
                NavigationLink(destination: TaskCreateView(viewModel: viewModel, typeViewModel: typeViewModel)) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - Completed Tasks View

struct CompletedTasksView: View {
    @ObservedObject var viewModel: TaskViewModel
    @ObservedObject var typeViewModel: TaskTypeViewModel

    var completedTasks: [Task] { viewModel.tasks.filter { $0.isCompleted } }

    var body: some View {
        NavigationView {
            List {
                ForEach(completedTasks) { task in
                    NavigationLink(destination: EditTaskView(task: task, viewModel: viewModel, typeViewModel: typeViewModel)) {
                        TaskRow(task: task, viewModel: viewModel)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteTask(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            viewModel.toggleTaskCompletion(task) // Restore the task
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("Completed Tasks")
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    var task: Task
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isOverdue ? .red : .primary)
                Text(task.type.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(task.dueDate, style: .time)
                    .foregroundColor(task.isDueSoon ? .orange : .gray)
                if task.isOverdue {
                    Text("Past Due")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
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

// MARK: - Task Creation View

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

// MARK: - Edit Task View

struct EditTaskView: View {
    var task: Task
    @ObservedObject var viewModel: TaskViewModel
    @ObservedObject var typeViewModel: TaskTypeViewModel
    @State private var title: String
    @State private var dueDate: Date
    @State private var selectedType: TaskTypeModel
    @Environment(\.presentationMode) var presentationMode
    
    init(task: Task, viewModel: TaskViewModel, typeViewModel: TaskTypeViewModel) {
        self.task = task
        self.viewModel = viewModel
        self.typeViewModel = typeViewModel
        _title = State(initialValue: task.title)
        _dueDate = State(initialValue: task.dueDate)
        _selectedType = State(initialValue: task.type)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Edit Task Info")) {
                TextField("Task Title", text: $title)
                DatePicker("Due Date & Time", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                Picker("Task Type", selection: $selectedType) {
                    ForEach(typeViewModel.types) { type in
                        Text(type.name).tag(type)
                    }
                }
            }
            Button("Save") {
                viewModel.updateTask(task, title: title, dueDate: dueDate, type: selectedType)
                presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationTitle("Edit Task")
    }
}

// MARK: - Add New Task Type View

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
