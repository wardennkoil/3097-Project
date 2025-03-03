import SwiftUI

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
        NavigationView {
            VStack(spacing: 20) {
                Text("Student 1: Michael Mocioiu - ID: 101459108")
                Text("Student 2: Leonid Serebryannikov - ID: 101468805")
                Text("Student 3: Ivan Zakrevskyi - ID: 987654")
                
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


struct Task: Identifiable {
    let id = UUID()
    var title: String
    var dueDate: Date
}

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = [
        Task(title: "Buy groceries", dueDate: Date().addingTimeInterval(3600)),
        Task(title: "Finish assignment", dueDate: Date().addingTimeInterval(-3600))
    ]
    
    func deleteTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
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
            NavigationLink(destination: TaskCreateView()) {
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
            Text(task.title)
            Spacer()
            Text(task.dueDate, style: .time)
                .foregroundColor(.gray)
            
            Button(action: {
                viewModel.deleteTask(task)
            }) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
            }
            .buttonStyle(BorderlessButtonStyle()) // Ensures only button triggers action
        }
    }
}

struct TaskCreateView: View {
    
    var body: some View {
        Form {
            
        }
        .navigationTitle("New Task")
    }
}
