import SwiftUI

struct AssignExercisesView: View {
    let user: User
    @State private var selectedDate = Date()
    @State private var exercises: [ExercisesToDo] = []
    @State private var isLoading = false
    @State private var showAddExerciseView = false
    @State private var exerciseToEdit: ExercisesToDo? = nil

    var body: some View {
        VStack {
            Text("Manage Exercises for \(user.name)")
                .font(.headline)
                .padding()

            DatePicker("Select a date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()

            Button("Load Exercises") {
                loadExercises(for: selectedDate)
            }
            .padding()

            if isLoading {
                ProgressView("Loading exercises...")
                    .padding()
            } else if exercises.isEmpty {
                Text("No exercises for this date")
                    .padding()
            } else {
                List {
                    ForEach(exercises, id: \ExercisesToDo.id) { exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)
                            Text("Repetitions: \(exercise.repetitions)")
                                .font(.subheadline)
                            Text("Sets: \(exercise.sets)")
                                .font(.subheadline)
                            if let weight = exercise.weight {
                                Text("Weight: \(weight) kg")
                                    .font(.subheadline)
                            }
                            Text("Rest Time: \(exercise.rest_time) seconds")
                                .font(.subheadline)
                            Text("Completion State: \(exercise.completionState.map { $0 ? "✔️" : "❌" }.joined(separator: ", "))")
                                .font(.caption)

                            HStack {
                                Text("Edit")
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                        exerciseToEdit = exercise
                                    }

                                Spacer()

                                Text("Delete")
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        deleteExercise(exerciseID: exercise.id)
                                    }
                            }
                            .padding(.top, 5)
                        }
                    }
                }
            }

            Button("Add Exercise") {
                showAddExerciseView = true
            }
            .padding()
            .sheet(isPresented: $showAddExerciseView) {
                AddExerciseView(user: user, selectedDate: selectedDate, onExerciseAdded: {
                    loadExercises(for: selectedDate)
                })
            }
            .sheet(item: $exerciseToEdit) { exercise in
                EditExerciseView(user: user, exercise: exercise, onExerciseUpdated: {
                    loadExercises(for: selectedDate)
                })
            }
        }
        .padding()
        .onAppear {
            loadExercises(for: selectedDate)
        }
    }

    private func loadExercises(for date: Date) {
        isLoading = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: date)

        APIService.shared.fetchExercisesToDo(for: user.id, date: formattedDate) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedExercises):
                    print("Fetched exercises: \(fetchedExercises)")
                    exercises = fetchedExercises
                case .failure(let error):
                    print("Failed to load exercises: \(error.localizedDescription)")
                }
            }
        }
    }

    private func deleteExercise(exerciseID: Int) {
        APIService.shared.deleteExerciseToDo(exerciseID: exerciseID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    exercises.removeAll { $0.id == exerciseID }
                case .failure(let error):
                    print("Failed to delete exercise: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct EditExerciseView: View {
    let user: User
    @State var exercise: ExercisesToDo
    var onExerciseUpdated: () -> Void

    @State private var repetitionsInput: String = ""
    @State private var setsInput: String = ""
    @State private var weightInput: String = ""
    @State private var restTimeInput: String = ""
    @State private var showConfirmation = false
    @State private var message = ""

    var body: some View {
        VStack {
            Text("Edit Exercise")
                .font(.headline)
                .padding()

            TextField("Repetitions", text: $repetitionsInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()

            TextField("Sets", text: $setsInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()

            TextField("Weight (optional)", text: $weightInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding()

            TextField("Rest Time (seconds)", text: $restTimeInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()

            Button("Save Changes") {
                saveExercise()
            }
            .padding()
            .alert(isPresented: $showConfirmation) {
                Alert(title: Text("Message"), message: Text(message), dismissButton: .default(Text("OK"), action: {
                    if message == "Exercise updated successfully!" {
                        onExerciseUpdated()
                    }
                }))
            }
        }
        .padding()
        .onAppear {
            repetitionsInput = "\(exercise.repetitions)"
            setsInput = "\(exercise.sets)"
            weightInput = "\(exercise.weight ?? 0.0)"
            restTimeInput = "\(exercise.rest_time)"
        }
    }

    private func saveExercise() {
        guard let repetitions = Int(repetitionsInput),
              let sets = Int(setsInput),
              let restTime = Int(restTimeInput) else {
            print("Invalid input values")
            return
        }
        let weight = Float(weightInput) ?? 0.0


        var updatedCompletionState = exercise.completionState
        if sets > updatedCompletionState.count {
            updatedCompletionState.append(contentsOf: Array(repeating: false, count: sets - updatedCompletionState.count))
        } else if sets < updatedCompletionState.count {
            updatedCompletionState = Array(updatedCompletionState.prefix(sets))
        }

        let updatedExercise = [
            "repetitions": repetitions,
            "sets": sets,
            "weight": weight,
            "rest_time": restTime,
            "completion_state": updatedCompletionState
        ] as [String: Any]

        APIService.shared.updateExerciseToDo(exerciseID: exercise.id, updatedExercise: updatedExercise) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    message = "Exercise updated successfully!"
                case .failure(let error):
                    message = "Failed to update exercise: \(error.localizedDescription)"
                }
                showConfirmation = true
            }
        }
    }
}





struct AddExerciseView: View {
    let user: User
    let selectedDate: Date
    var onExerciseAdded: () -> Void

    @State private var generalExercises: [GeneralExercise] = []
    @State private var selectedExercise: GeneralExercise? = nil
    @State private var repetitionsInput: String = ""
    @State private var setsInput: String = ""
    @State private var weightInput: String = ""
    @State private var restTimeInput: String = ""
    @State private var isLoading = true
    @State private var showConfirmation = false
    @State private var message = ""

    var body: some View {
        VStack {
            Text("Add Exercise for \(user.name)")
                .font(.headline)
                .padding()

            if isLoading {
                ProgressView("Loading exercises...")
                    .padding()
            } else if generalExercises.isEmpty {
                Text("No exercises available")
                    .padding()
            } else {
                Picker("Select an exercise", selection: $selectedExercise) {
                    ForEach(generalExercises, id: \GeneralExercise.id) { exercise in
                        Text(exercise.name).tag(exercise as GeneralExercise?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
            }

            TextField("Repetitions", text: $repetitionsInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()

            TextField("Sets", text: $setsInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()

            TextField("Weight (optional)", text: $weightInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding()

            TextField("Rest Time (seconds)", text: $restTimeInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()

            Button("Save Exercise") {
                saveExercise()
            }
            .padding()
            .disabled(selectedExercise == nil)
            .alert(isPresented: $showConfirmation) {
                Alert(title: Text("Message"), message: Text(message), dismissButton: .default(Text("OK"), action: {
                    if message == "Exercise added successfully!" {
                        onExerciseAdded()
                    }
                }))
            }
        }
        .padding()
        .onAppear(perform: loadGeneralExercises)
    }

    private func loadGeneralExercises() {
        APIService.shared.fetchGeneralExercises { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedExercises):
                    generalExercises = fetchedExercises
                case .failure(let error):
                    print("Failed to load general exercises: \(error.localizedDescription)")
                }
            }
        }
    }

    private func saveExercise() {
        guard let selectedExercise = selectedExercise else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: selectedDate)

        guard let repetitions = Int(repetitionsInput), let sets = Int(setsInput), let restTime = Int(restTimeInput) else {
            print("Invalid input values")
            return
        }
        let weight = Float(weightInput) ?? 0.0

        let exercise = [
            "name": selectedExercise.name,
            "description": selectedExercise.description,
            "repetitions": repetitions,
            "sets": sets,
            "weight": weight,
            "rest_time": restTime,
            "patient_id": user.id,
            "date": formattedDate
        ] as [String: Any]

        APIService.shared.addExerciseToDo(for: user.id, date: formattedDate, exercise: selectedExercise, repetitions: repetitions, sets: sets, weight: weight, restTime: restTime) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    message = "Exercise added successfully!"
                case .failure(let error):
                    message = "Failed to add exercise: \(error.localizedDescription)"
                }
                showConfirmation = true
            }
        }
    }
}

extension Date {
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

struct ExercisesToDo: Identifiable, Codable {
    let id: Int
    let name: String
    let repetitions: Int
    let sets: Int
    let weight: Float?
    let rest_time: Int
    var completionState: [Bool]
    var description: String? = nil
    var video_url: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case repetitions
        case sets
        case weight
        case rest_time
        case completionState = "completion_state"
        case description
        case video_url
    }
}


