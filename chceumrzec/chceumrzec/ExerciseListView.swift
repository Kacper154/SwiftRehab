import SwiftUI

struct ExerciseListView: View {
    @Binding var isLoggedIn: Bool
    @State private var exercises: [Exercise] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading exercises...")
                        .padding()
                } else if exercises.isEmpty {
                    Text("No exercises available")
                        .padding()
                } else {
                    List(exercises, id: \.id) { exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)
                            Text("Repetitions: \(exercise.repetitions)")
                                .font(.caption)
                        }
                    }
                }

                Button("Logout") {
                    isLoggedIn = false
                }
                .padding()
                .navigationTitle("Your Exercises")
            }
            .onAppear(perform: loadExercises)
        }
    }

    private func loadExercises() {
        isLoading = true
        let userId = "current_user_id_placeholder"

        APIService.shared.fetchExercises(for: userId, date: "2024-12-30") { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedExercises):
                    exercises = fetchedExercises
                case .failure(let error):
                    print("Failed to load exercises: \(error.localizedDescription)")
                }
            }
        }
    }
}
