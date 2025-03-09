import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var isRegistering: Bool
    @Binding var userRole: String?
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Login") {
                APIService.shared.login(email: email, password: password) { result in
                    switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            isLoggedIn = true
                            userRole = response.role 
                        }
                    case .failure(let error):
                        print("Login failed: \(error)")
                    }
                }
            }
            .padding()

            Button("Register") {
                isRegistering = true
            }
            .padding()
        }
        .navigationTitle("Login")
    }
}
