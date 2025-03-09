import SwiftUI

struct ContentView: View {
    @State private var isRegistering = false
    @State private var isLoggedIn = false
    @State private var userRole: String? = nil

    var body: some View {
        NavigationView {
            if isLoggedIn {
                if userRole == "patient" {
                    PatientView(isLoggedIn: $isLoggedIn)
                } else if userRole == "therapist" {
                    TherapistDashboardView(isLoggedIn: $isLoggedIn)
                }
            } else if isRegistering {
                RegistrationView(isRegistering: $isRegistering)
            } else {
                LoginView(isLoggedIn: $isLoggedIn, isRegistering: $isRegistering, userRole: $userRole)
            }
        }
    }
}
