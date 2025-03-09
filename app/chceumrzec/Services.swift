import Foundation

class APIService {
    static let shared = APIService()
    let baseURL = "http://127.0.0.1:5000"
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "authToken"
    var authToken: String?

    private init() {}

    var token: String? {
        get {
            userDefaults.string(forKey: tokenKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: tokenKey)
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, let response = try? JSONDecoder().decode(LoginResponse.self, from: data) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }

            self.token = response.access_token
            completion(.success(response))
        }.resume()
    }

    func register(name: String, email: String, password: String, role: String = "patient", completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["name": name, "email": email, "password": password, "role": role]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to register"])
                completion(.failure(error))
                return
            }

            completion(.success(()))
        }.resume()
    }

    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        guard let token = token else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No token available"])))
            return
        }
        guard let url = URL(string: "\(baseURL)/get_users") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let response = try JSONDecoder().decode(UsersResponse.self, from: data)
                completion(.success(response.users))
            } catch {
                print("Error decoding users: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }


    struct UsersResponse: Codable {
        let users: [User]
    }



    func assignExercise(exercise: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = token else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No token available"])))
            return
        }
        guard let url = URL(string: "\(baseURL)/add_exercise") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: exercise)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to assign exercise"])
                completion(.failure(error))
                return
            }

            completion(.success(()))
        }.resume()
    }

    func fetchExercises(for userID: String, date: String, completion: @escaping (Result<[Exercise], Error>) -> Void) {
        guard let token = token else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No token available"])))
            return
        }
        guard let url = URL(string: "\(baseURL)/get_exercises/\(userID)?date=\(date)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let exercises = try JSONDecoder().decode([Exercise].self, from: data)
                completion(.success(exercises))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }


    func fetchGeneralExercises(completion: @escaping (Result<[GeneralExercise], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/get_general_exercises") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let response = try JSONDecoder().decode(GeneralExercisesResponse.self, from: data)
                completion(.success(response.exercises))
            } catch {
                print("Error decoding general exercises: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }


    struct GeneralExercisesResponse: Codable {
        let exercises: [GeneralExercise]
    }

    func addExerciseToDo(for userId: String, date: String, exercise: GeneralExercise, repetitions: Int, sets: Int, weight: Float?, restTime: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = token else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No token available"])))
            return
        }
        guard let url = URL(string: "\(baseURL)/add_exercise_todo") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "user_id": userId,
            "date": date,
            "name": exercise.name,
            "repetitions": repetitions,
            "sets": sets,
            "weight": weight ?? 0.0,
            "rest_time": restTime
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to add exercise"])))
                return
            }

            completion(.success(()))
        }.resume()
    }

    func fetchExercisesToDo(for userId: String, date: String, completion: @escaping (Result<[ExercisesToDo], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/get_exercises/\(userId)?date=\(date)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No token available"])))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([String: [ExercisesToDo]].self, from: data)
                if let exercises = decodedResponse["exercises"] {
                    completion(.success(exercises))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])))
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "Invalid JSON")")
                completion(.failure(error))
            }
        }.resume()
    }



    func updateExerciseToDo(exerciseID: Int, updatedExercise: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = token else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No token available"])))
            return
        }
        guard let url = URL(string: "\(baseURL)/update_exercise_todo/\(exerciseID)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: updatedExercise, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update exercise"])))
                return
            }

            completion(.success(()))
        }.resume()
    }


    func deleteExerciseToDo(exerciseID: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = token else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No token available"])))
            return
        }
        guard let url = URL(string: "\(baseURL)/delete_exercise_todo/\(exerciseID)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to delete exercise"])))
                return
            }

            completion(.success(()))
        }.resume()
    }
    
    func updateExerciseCompletionState(exerciseID: Int, updatedData: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/update_exercise_completion_state/\(exerciseID)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updatedData)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            completion(.success(()))
        }.resume()
    }





    


}
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
}

extension APIService {
    func fetchExercisesWithDetails(for userId: String, date: String, completion: @escaping (Result<[ExercisesToDo], Error>) -> Void) {
        fetchGeneralExercises { generalResult in
            switch generalResult {
            case .success(let generalExercises):
                self.fetchExercisesToDo(for: userId, date: date) { exerciseResult in
                    switch exerciseResult {
                    case .success(let exercisesToDo):
                        let mergedExercises = exercisesToDo.map { exercise -> ExercisesToDo in
                            if let match = generalExercises.first(where: { $0.name == exercise.name }) {
                                return ExercisesToDo(
                                    id: exercise.id,
                                    name: exercise.name,
                                    repetitions: exercise.repetitions,
                                    sets: exercise.sets,
                                    weight: exercise.weight,
                                    rest_time: exercise.rest_time,
                                    completionState: exercise.completionState,
                                    description: match.description,
                                    video_url: match.video_url
                                )
                            }
                            return exercise
                        }
                        completion(.success(mergedExercises))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension APIService {
    func generateReport(userId: String, startDate: String, endDate: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = token else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No token available"])))
            return
        }

        guard let url = URL(string: "\(baseURL)/generate_report/\(userId)?start_date=\(startDate)&end_date=\(endDate)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let reportPath = json["report_path"] as? String {
                    completion(.success(reportPath))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
