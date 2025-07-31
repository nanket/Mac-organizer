import SwiftUI
import AppKit

@main
struct SmartFileOrganizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var fileOrganizer = FileOrganizer()
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        // Hide the main window since this is a menu bar app
        Settings {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

// MARK: - App Settings
class AppSettings: ObservableObject {
    @Published var isFirstLaunch: Bool = true
    @Published var enableNotifications: Bool = true
    @Published var autoStartOnLogin: Bool = false
    @Published var organizationInterval: TimeInterval = 300 // 5 minutes
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        isFirstLaunch = UserDefaults.standard.object(forKey: "isFirstLaunch") as? Bool ?? true
        enableNotifications = UserDefaults.standard.object(forKey: "enableNotifications") as? Bool ?? true
        autoStartOnLogin = UserDefaults.standard.object(forKey: "autoStartOnLogin") as? Bool ?? false
        organizationInterval = UserDefaults.standard.object(forKey: "organizationInterval") as? TimeInterval ?? 300
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isFirstLaunch, forKey: "isFirstLaunch")
        UserDefaults.standard.set(enableNotifications, forKey: "enableNotifications")
        UserDefaults.standard.set(autoStartOnLogin, forKey: "autoStartOnLogin")
        UserDefaults.standard.set(organizationInterval, forKey: "organizationInterval")
    }
}

// MARK: - App Delegate for additional lifecycle management
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon since this is a menu bar only app
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup before termination
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Handle app reopen events
        return false
    }
}
