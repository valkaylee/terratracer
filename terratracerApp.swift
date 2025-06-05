import SwiftUI

@main
struct terratracerApp: App {
    // Create a shared view model instance
    @StateObject private var terraTracerViewModel = TerraTracerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(vm: terraTracerViewModel)
        }
    }
}
