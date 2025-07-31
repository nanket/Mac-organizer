import SwiftUI

struct ContentView: View {
    @StateObject private var fileOrganizer = FileOrganizer()
    @StateObject private var appSettings = AppSettings()
    @State private var selectedTab: TabSelection = .dashboard
    
    enum TabSelection: String, CaseIterable {
        case dashboard = "Dashboard"
        case rules = "Rules"
        case settings = "Settings"
        case logs = "Activity"
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .rules: return "list.bullet.rectangle"
            case .settings: return "gearshape.fill"
            case .logs: return "clock.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            VStack(spacing: 0) {
                // App Title
                HStack {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    Text("Smart File Organizer")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                
                Divider()
                
                // Navigation Tabs
                VStack(spacing: 4) {
                    ForEach(TabSelection.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            HStack {
                                Image(systemName: tab.icon)
                                    .frame(width: 20)
                                Text(tab.rawValue)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedTab == tab ? 
                                Color.accentColor.opacity(0.1) : 
                                Color.clear
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                Spacer()
                
                // Quick Actions
                VStack(spacing: 8) {
                    Button("Organize Now") {
                        Task {
                            await fileOrganizer.organizeAllDirectories()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Add Directory") {
                        fileOrganizer.showDirectoryPicker()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Main Content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .rules:
                    RulesView()
                case .settings:
                    SettingsView()
                case .logs:
                    ActivityLogView()
                }
            }
            .frame(minWidth: 500, minHeight: 400)
        }
        .navigationTitle("")
        .toolbar(.hidden)
        .environmentObject(fileOrganizer)
        .environmentObject(appSettings)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var fileOrganizer: FileOrganizer
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Statistics Cards
                HStack(spacing: 16) {
                    StatCard(
                        title: "Files Organized",
                        value: "\(fileOrganizer.statistics.filesOrganized)",
                        icon: "doc.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Active Rules",
                        value: "\(fileOrganizer.organizationRules.count)",
                        icon: "list.bullet",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Watched Folders",
                        value: "\(fileOrganizer.watchedDirectories.count)",
                        icon: "folder.fill",
                        color: .orange
                    )
                }
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if fileOrganizer.recentOperations.isEmpty {
                        Text("No recent activity")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(fileOrganizer.recentOperations.prefix(5), id: \.id) { operation in
                            RecentOperationRow(operation: operation)
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct RecentOperationRow: View {
    let operation: FileOperation
    
    var body: some View {
        HStack {
            Image(systemName: operation.type.icon)
                .foregroundColor(operation.type.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(operation.fileName)
                    .font(.body)
                    .lineLimit(1)
                Text(operation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(operation.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// Placeholder views for other tabs
struct RulesView: View {
    var body: some View {
        Text("Rules Configuration")
            .navigationTitle("Organization Rules")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .navigationTitle("Settings")
    }
}

struct ActivityLogView: View {
    var body: some View {
        Text("Activity Log")
            .navigationTitle("Activity Log")
    }
}

#Preview {
    ContentView()
}
