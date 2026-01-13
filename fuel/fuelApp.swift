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
                    .environment(\.authService, authService)
            } else {
                LoginView()
                    .environment(\.authService, authService)
            }
        }
    }
}
