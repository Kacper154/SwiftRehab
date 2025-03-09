import SwiftUI

struct TherapistDashboardView: View {
    @Binding var isLoggedIn: Bool
    @State private var users: [User] = []
    @State private var isLoading = true
    @State private var selectedUser: User?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading users...")
                        .padding()
                } else if users.isEmpty {
                    Text("No users found")
                        .padding()
                } else {
                    List(users) { user in
                        Button(action: {
                            selectedUser = user
                        }) {
                            VStack(alignment: .leading) {
                                Text("Name: \(user.name)")
                                Text("Email: \(user.email)")
                            }
                        }
                    }
                }

                Button("Logout") {
                    isLoggedIn = false
                }
                .padding()
            }
            .onAppear(perform: fetchUsers)
            .sheet(item: $selectedUser) { user in
                AssignExercisesView(user: user)
            }
        }
    }

    private func fetchUsers() {
        APIService.shared.fetchUsers { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedUsers):
                    users = fetchedUsers
                    print("Fetched users in view: \(users)")
                case .failure(let error):
                    print("Error fetching users: \(error)")
                }
            }
        }
    }
}
