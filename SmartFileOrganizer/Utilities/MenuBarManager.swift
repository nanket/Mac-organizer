import SwiftUI
import AppKit

class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    @Published var isPopoverShown = false
    
    override init() {
        super.init()
        setupMenuBar()
        setupPopover()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Set the menu bar icon
            if let image = NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: "Smart File Organizer") {
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            }
            
            button.action = #selector(togglePopover)
            button.target = self
            button.toolTip = "Smart File Organizer"
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 720, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView())
        popover?.delegate = self
    }
    
    @objc private func togglePopover() {
        guard let popover = popover else { return }
        
        if popover.isShown {
            hidePopover()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let popover = popover,
              let button = statusItem?.button else { return }
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        isPopoverShown = true
        
        // Activate the app to ensure proper focus
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func hidePopover() {
        popover?.performClose(nil)
        isPopoverShown = false
    }
    
    func updateMenuBarIcon(organizing: Bool) {
        guard let button = statusItem?.button else { return }
        
        let iconName = organizing ? "folder.badge.gearshape.fill" : "folder.badge.gearshape"
        
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Smart File Organizer") {
            image.size = NSSize(width: 18, height: 18)
            button.image = image
        }
    }
    
    func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - NSPopoverDelegate
extension MenuBarManager: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        isPopoverShown = false
    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return true
    }
}

// MARK: - Menu Bar Context Menu
extension MenuBarManager {
    func setupContextMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Quick Organize
        let organizeItem = NSMenuItem(title: "Organize Now", action: #selector(quickOrganize), keyEquivalent: "")
        organizeItem.target = self
        menu.addItem(organizeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Show Main Window
        let showItem = NSMenuItem(title: "Show Smart File Organizer", action: #selector(showMainWindow), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)
        
        // Preferences
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // About
        let aboutItem = NSMenuItem(title: "About Smart File Organizer", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Smart File Organizer", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc private func quickOrganize() {
        // Trigger quick organization
        NotificationCenter.default.post(name: .quickOrganize, object: nil)
    }
    
    @objc private func showMainWindow() {
        showPopover()
    }
    
    @objc private func showPreferences() {
        showPopover()
        // Navigate to settings tab
        NotificationCenter.default.post(name: .showSettings, object: nil)
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Smart File Organizer"
        alert.informativeText = "Version 1.0\n\nA smart file organization tool for macOS that helps you keep your files organized automatically."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let quickOrganize = Notification.Name("quickOrganize")
    static let showSettings = Notification.Name("showSettings")
}
