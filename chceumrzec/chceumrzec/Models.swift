import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
}

struct Exercise: Identifiable, Codable {
    let id: Int
    let name: String
    let repetitions: Int
    let sets: Int
    let weight: Float
    let rest_time: Int
    let completion_state: [Bool]
}


struct LoginResponse: Codable {
    let access_token: String
    let role: String
}

struct Report: Codable {
    let completedExercises: [Int]
}

struct GeneralExercise: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String
    let video_url: String?
}

