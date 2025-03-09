import SwiftUI

struct RegistrationView: View {
    @Binding var isRegistering: Bool
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole = "patient" 
    @State private var showMessage = false
    @State private var message = ""
    
    var body: some View {
        VStack {
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Picker("Role", selection: $selectedRole) {
                Text("Patient").tag("patient")
                Text("Therapist").tag("therapist")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Button("Register") {
                guard password == confirmPassword else {
                    message = "Passwords do not match"
                    showMessage = true
                    return
                }
                
                APIService.shared.register(name: name, email: email, password: password, role: selectedRole) { result in
                    switch result {
                    case .success:
                        message = "Registration successful! Please log in."
                        isRegistering = false
                    case .failure(let error):
                        message = "Registration failed: \(error.localizedDescription)"
                    }
                    showMessage = true
                }
            }
            .padding()
            
            Button("Back to Login") {
                isRegistering = false
            }
            .padding()
        }
        .alert(isPresented: $showMessage) {
            Alert(title: Text("Message"), message: Text(message), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Register")
    }
}
