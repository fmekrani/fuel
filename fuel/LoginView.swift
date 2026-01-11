import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false
    
    var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !username.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.86, green: 0.18, blue: 0.18).opacity(0.1),
                    Color(red: 1.0, green: 0.34, blue: 0.28).opacity(0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Blur effect
            VStack {}
                .blur(radius: 40)
                .opacity(0.3)
            
            // Content
            VStack(spacing: 0) {
                // Top Section - Branding
                VStack(spacing: 8) {
                    Text("🔥")
                        .font(.system(size: 48))
                        .padding(.bottom, 8)
                    
                    Text(isSignUp ? "Join Fuel" : "Welcome Back")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(isSignUp ? "Start your fitness journey" : "Continue your progress")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 40)
                
                // Form Section
                VStack(spacing: 16) {
                    // Username (Sign Up only)
                    if isSignUp {
                        TextField("Username", text: $username)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground).opacity(0.7))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Email
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground).opacity(0.7))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    // Password
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground).opacity(0.7))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    // Password requirement hint (Sign Up only)
                    if isSignUp && !password.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: password.count >= 6 ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(password.count >= 6 ? .green : .secondary)
                            Text("At least 6 characters")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                    .frame(height: 24)
                
                // Error Message
                if !authService.errorMessage.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                        
                        Text(authService.errorMessage)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.red)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Forgot Password (Sign In only)
                if !isSignUp {
                    HStack {
                        Spacer()
                        Button(action: { showForgotPassword = true }) {
                            Text("Forgot Password?")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(red: 0.86, green: 0.18, blue: 0.18))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                
                Spacer()
                
                // Primary Button
                Button(action: {
                    if isSignUp {
                        authService.signUp(email: email, password: password, username: username)
                    } else {
                        authService.signIn(email: email, password: password)
                    }
                }) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(red: 0.86, green: 0.18, blue: 0.18))
                            .cornerRadius(12)
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.86, green: 0.18, blue: 0.18),
                                        Color(red: 1.0, green: 0.34, blue: 0.28)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .opacity(isFormValid ? 1.0 : 0.5)
                    }
                }
                .disabled(!isFormValid || authService.isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .scaleEffect(authService.isLoading ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: authService.isLoading)
                
                // Toggle Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSignUp.toggle()
                        authService.errorMessage = ""
                        email = ""
                        password = ""
                        username = ""
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        Text(isSignUp ? "Sign In" : "Sign Up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.86, green: 0.18, blue: 0.18))
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(isPresented: $showForgotPassword)
                .environmentObject(authService)
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var isLoading = false
    @State private var successMessage = ""
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Reset Password")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Enter your email and we'll send a password reset link")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                
                // Email Input
                TextField("Email", text: $email)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .regular))
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                
                // Success Message
                if !successMessage.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                        
                        Text(successMessage)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }
                
                // Error Message
                if !errorMessage.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }
                
                Spacer()
                
                // Send Button
                Button(action: {
                    isLoading = true
                    successMessage = ""
                    errorMessage = ""
                    
                    authService.resetPassword(email: email) { success, message in
                        isLoading = false
                        if success {
                            successMessage = message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isPresented = false
                            }
                        } else {
                            errorMessage = message
                        }
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Reset Link")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.86, green: 0.18, blue: 0.18),
                            Color(red: 1.0, green: 0.34, blue: 0.28)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .opacity(email.isEmpty ? 0.5 : 1.0)
                .disabled(email.isEmpty || isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
