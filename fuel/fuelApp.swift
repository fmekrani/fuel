import SwiftUI
import FirebaseCore

@main
struct fuelApp: App {
    @StateObject private var authService = AuthService()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isLoggedIn {
                ContentView()
                    .environmentObject(authService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}
