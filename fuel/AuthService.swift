import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - User Model
struct AppUser: Identifiable, Codable {
    let id = UUID()
    let uid: String
    let email: String
    let username: String
    let bio: String
    let profileImage: String
    let createdAt: Date
}

// MARK: - Auth Service
class AuthService: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: AppUser?
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private var db: Firestore?
    private let isPreview: Bool
    
    init(isPreview: Bool = false) {
        self.isPreview = isPreview
        if !isPreview {
            self.db = Firestore.firestore()
            checkIfUserIsLoggedIn()
        }
    }
    
    // MARK: - Check Existing Session
    func checkIfUserIsLoggedIn() {
        guard !isPreview else { return }
        if let user = Auth.auth().currentUser {
            self.isLoggedIn = true
            fetchUserProfile(uid: user.uid)
        } else {
            self.isLoggedIn = false
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, username: String) {
        guard !isPreview else { return }
        isLoading = true
        errorMessage = ""
        
        // Validate inputs
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty else {
            errorMessage = "All fields are required"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("❌ Firebase Auth Error: \(error.localizedDescription)")
                print("Error Code: \((error as NSError).code)")
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
                return
            }
            
            guard let uid = result?.user.uid else {
                self?.errorMessage = "Failed to create user"
                self?.isLoading = false
                return
            }
            
            // Create user document in Firestore
            let userData: [String: Any] = [
                "uid": uid,
                "email": email,
                "username": username,
                "bio": "",
                "profileImage": "",
                "createdAt": Date()
            ]
            
            self?.db?.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    print("❌ Firestore Error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                } else {
                    print("✅ User account created successfully!")
                    self?.isLoggedIn = true
                    self?.isLoading = false
                    self?.fetchUserProfile(uid: uid)
                }
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) {
        guard !isPreview else { return }
        isLoading = true
        errorMessage = ""
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required"
            isLoading = false
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
                return
            }
            
            guard let uid = result?.user.uid else {
                self?.errorMessage = "Failed to sign in"
                self?.isLoading = false
                return
            }
            
            self?.isLoggedIn = true
            self?.isLoading = false
            self?.fetchUserProfile(uid: uid)
        }
    }
    
    // MARK: - Fetch User Profile
    func fetchUserProfile(uid: String) {
        guard !isPreview, let db = db else { return }
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            guard let data = document?.data() else {
                self?.errorMessage = "Could not fetch user profile"
                return
            }
            
            let user = AppUser(
                uid: uid,
                email: data["email"] as? String ?? "",
                username: data["username"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                profileImage: data["profileImage"] as? String ?? "",
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
            
            self?.currentUser = user
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        guard !isPreview else {
            self.isLoggedIn = false
            self.currentUser = nil
            return
        }
        do {
            try Auth.auth().signOut()
            print("✅ Signed out successfully")
        } catch let error {
            print("❌ Sign out error: \(error.localizedDescription)")
        }
        self.isLoggedIn = false
        self.currentUser = nil
        self.errorMessage = ""
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String, completion: @escaping (Bool, String) -> Void) {
        guard !isPreview else {
            completion(true, "Preview mode")
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, "Password reset email sent to \(email)")
            }
        }
    }
    
    // MARK: - Update Profile
    func updateProfile(username: String, bio: String) {
        guard var user = currentUser else { return }
        guard !isPreview, let db = db else { return }
        
        db.collection("users").document(user.uid).updateData([
            "username": username,
            "bio": bio
        ]) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                user = AppUser(uid: user.uid, email: user.email, username: username, bio: bio, profileImage: user.profileImage, createdAt: user.createdAt)
                self?.currentUser = user
            }
        }
    }
}

// MARK: - Environment Key for Previews
private struct AuthServiceKey: EnvironmentKey {
    static let defaultValue: AuthService = {
        let service = AuthService(isPreview: true)
        service.isLoggedIn = true
        service.currentUser = AppUser(
            uid: "preview-user",
            email: "preview@example.com",
            username: "Preview User",
            bio: "This is a preview user",
            profileImage: "",
            createdAt: Date()
        )
        return service
    }()
}

extension EnvironmentValues {
    var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}
