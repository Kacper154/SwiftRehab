import SwiftUI

struct PatientView: View {
    @Binding var isLoggedIn: Bool
    @State private var currentUserID: String = "CURRENT_USER_ID"
    @State private var selectedDate = Date()
    @State private var exercises: [ExercisesToDo] = []
    @State private var isLoading = false
    @State private var timers: [Int: Int] = [:]
    @State private var reportStartDate = Date()
    @State private var reportEndDate = Date()
    @State private var reportStatus = ""

    var body: some View {
        VStack {
            Button("Logout") {
                isLoggedIn = false
            }
            .padding()
            .foregroundColor(.red)

            DatePicker("Start Date", selection: $reportStartDate, displayedComponents: .date)
                .padding()
            DatePicker("End Date", selection: $reportEndDate, displayedComponents: .date)
                .padding()

            Button("Generate Report") {
                generateReport()
            }
            .padding()

            if !reportStatus.isEmpty {
                Text(reportStatus)
                    .padding()
                    .foregroundColor(.green)
            }

            if exercises.isEmpty {
                DatePicker("Select a date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()

                Button("Load Exercises") {
                    loadExercises(for: selectedDate)
                }
                .padding()
            } else {
                Button("Back to Calendar") {
                    exercises = []
                }
                .padding()

                List {
                    ForEach(exercises.indices, id: \.self) { index in
                        Section(header: Text(exercises[index].name).font(.headline)) {
                            Text("Repetitions: \(exercises[index].repetitions)")
                            Text("Sets: \(exercises[index].sets)")
                            if let weight = exercises[index].weight {
                                Text("Weight: \(weight) kg")
                            }
                            Text("Rest Time: \(exercises[index].rest_time) seconds")

                            if let description = exercises[index].description {
                                Text("Description: \(description)")
                            }
                            if let videoURL = exercises[index].video_url, let url = URL(string: videoURL) {
                                Link("Watch Video", destination: url)
                                    .foregroundColor(.blue)
                            }

                            HStack {
                                Text("Completion State:")
                                ForEach(0..<exercises[index].completionState.count, id: \.self) { stateIndex in
                                    Toggle("", isOn: Binding(
                                        get: { exercises[index].completionState[stateIndex] },
                                        set: { newValue in
                                            exercises[index].completionState[stateIndex] = newValue
                                            updateCompletionState(for: exercises[index])
                                        }
                                    ))
                                    .labelsHidden()
                                }
                            }

                       
                            HStack {
                                if let remainingTime = timers[exercises[index].id], remainingTime > 0 {
                                    Text("Rest Time Remaining: \(remainingTime) seconds")
                                } else {
                                    Text("Ready for next set!")
                                }

                                Button(timers[exercises[index].id] ?? 0 > 0 ? "" : "Start Timer") {
                                    startTimer(for: exercises[index])
                                }
                                .padding(.leading, 10)
                                .disabled(timers[exercises[index].id] ?? 0 > 0)
                            }
                        }
                    }
                }
            }

            if isLoading {
                ProgressView("Loading exercises...")
                    .padding()
            }
        }
        .padding()
    }

    private func loadExercises(for date: Date) {
        isLoading = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = formatter.string(from: date)

        APIService.shared.fetchExercisesWithDetails(for: currentUserID, date: formattedDate) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let exercises):
                    self.exercises = exercises
                    self.timers = exercises.reduce(into: [:]) { result, exercise in
                        result[exercise.id] = 0
                    }
                case .failure(let error):
                    print("Failed to load exercises: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateCompletionState(for exercise: ExercisesToDo) {
        let payload: [String: Any] = ["completion_state": exercise.completionState]
        
        APIService.shared.updateExerciseCompletionState(exerciseID: exercise.id, updatedData: payload) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Completion state updated.")
                case .failure(let error):
                    print("Failed to update state: \(error.localizedDescription)")
                }
            }
        }
    }

    private func startTimer(for exercise: ExercisesToDo) {
        guard timers[exercise.id] == 0 else {
            print("Timer is already running.")
            return
        }

        
        timers[exercise.id] = exercise.rest_time

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                if let remainingTime = self.timers[exercise.id], remainingTime > 0 {
                    self.timers[exercise.id] = remainingTime - 1
                } else {
                    self.timers[exercise.id] = 0
                    timer.invalidate()
                }
            }
        }
    }

    private func generateReport() {
        print("Current User ID: \(currentUserID)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: reportStartDate)
        let endDateString = dateFormatter.string(from: reportEndDate)

        APIService.shared.generateReport(userId: currentUserID, startDate: startDateString, endDate: endDateString) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let filePath):
                    reportStatus = "Report generated successfully: \(filePath)"
                case .failure(let error):
                    reportStatus = "Failed to generate report: \(error.localizedDescription)"
                }
            }
        }
    }


}
