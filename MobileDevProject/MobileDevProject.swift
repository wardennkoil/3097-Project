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


struct TaskListView: View {
    var body: some View {
        List {
        }
        .navigationTitle("To-Do List")
        .toolbar {
            NavigationLink(destination: TaskCreateView()) {
                Image(systemName: "plus")
            }
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
