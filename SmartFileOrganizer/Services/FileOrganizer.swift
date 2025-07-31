import Foundation
import AppKit
import Combine

class FileOrganizer: ObservableObject {
    @Published var organizationRules: [OrganizationRule] = []
    @Published var watchedDirectories: [URL] = []
    @Published var recentOperations: [FileOperation] = []
    @Published var statistics = OrganizationStatistics()
    @Published var isOrganizing = false
    
    private var fileSystemWatcher: FileSystemWatcher?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSettings()
        setupNotificationObservers()
        loadDefaultRules()
    }
    
    // MARK: - Public Methods
    
    func addWatchedDirectory(_ url: URL) {
        guard !watchedDirectories.contains(url) else { return }
        
        watchedDirectories.append(url)
        saveSettings()
        
        // Start watching this directory
        startWatching(directory: url)
    }
    
    func removeWatchedDirectory(_ url: URL) {
        watchedDirectories.removeAll { $0 == url }
        saveSettings()
        
        // Stop watching this directory
        stopWatching(directory: url)
    }
    
    func addOrganizationRule(_ rule: OrganizationRule) {
        organizationRules.append(rule)
        saveSettings()
    }
    
    func updateOrganizationRule(_ rule: OrganizationRule) {
        if let index = organizationRules.firstIndex(where: { $0.id == rule.id }) {
            organizationRules[index] = rule
            saveSettings()
        }
    }
    
    func removeOrganizationRule(_ rule: OrganizationRule) {
        organizationRules.removeAll { $0.id == rule.id }
        saveSettings()
    }
    
    @MainActor
    func organizeAllDirectories() async {
        guard !isOrganizing else { return }
        
        isOrganizing = true
        defer { isOrganizing = false }
        
        for directory in watchedDirectories {
            await organizeDirectory(directory)
        }
    }
    
    @MainActor
    func organizeDirectory(_ directory: URL) async {
        do {
            let files = try getFilesInDirectory(directory)
            
            for file in files {
                await organizeFile(file)
            }
        } catch {
            print("Error organizing directory \(directory.path): \(error)")
        }
    }
    
    func showDirectoryPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Select Directories to Watch"
        panel.message = "Choose directories that you want Smart File Organizer to monitor and organize."
        
        panel.begin { [weak self] response in
            if response == .OK {
                for url in panel.urls {
                    self?.addWatchedDirectory(url)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .quickOrganize)
            .sink { [weak self] _ in
                Task {
                    await self?.organizeAllDirectories()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadDefaultRules() {
        if organizationRules.isEmpty {
            // Create some default rules
            let documentsRule = OrganizationRule(
                name: "Documents",
                conditions: [
                    RuleCondition(type: .fileType, operator: .equals, value: "document")
                ],
                actions: [
                    RuleAction(type: .moveToFolder, parameters: ["destinationPath": "~/Documents/Organized/Documents"])
                ]
            )
            
            let imagesRule = OrganizationRule(
                name: "Images",
                conditions: [
                    RuleCondition(type: .fileType, operator: .equals, value: "image")
                ],
                actions: [
                    RuleAction(type: .moveToFolder, parameters: ["destinationPath": "~/Documents/Organized/Images"])
                ]
            )
            
            let videosRule = OrganizationRule(
                name: "Videos",
                conditions: [
                    RuleCondition(type: .fileType, operator: .equals, value: "video")
                ],
                actions: [
                    RuleAction(type: .moveToFolder, parameters: ["destinationPath": "~/Documents/Organized/Videos"])
                ]
            )
            
            organizationRules = [documentsRule, imagesRule, videosRule]
            saveSettings()
        }
    }
    
    private func getFilesInDirectory(_ directory: URL) throws -> [FileInfo] {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .isDirectoryKey
        ])
        
        var files: [FileInfo] = []
        
        for url in contents {
            let resourceValues = try url.resourceValues(forKeys: [
                .fileSizeKey,
                .creationDateKey,
                .contentModificationDateKey,
                .isDirectoryKey
            ])
            
            // Skip directories
            if resourceValues.isDirectory == true {
                continue
            }
            
            let fileInfo = FileInfo(
                name: url.lastPathComponent,
                path: url.path,
                size: Int64(resourceValues.fileSize ?? 0),
                creationDate: resourceValues.creationDate ?? Date(),
                modificationDate: resourceValues.contentModificationDate ?? Date(),
                fileType: FileType.from(fileExtension: url.pathExtension)
            )
            
            files.append(fileInfo)
        }
        
        return files
    }
    
    @MainActor
    private func organizeFile(_ file: FileInfo) async {
        // Find the first matching rule
        guard let matchingRule = organizationRules
            .filter({ $0.isEnabled })
            .sorted(by: { $0.priority > $1.priority })
            .first(where: { $0.matches(file: file) }) else {
            return
        }
        
        // Execute the rule's actions
        for action in matchingRule.actions {
            await executeAction(action, on: file)
        }
    }
    
    @MainActor
    private func executeAction(_ action: RuleAction, on file: FileInfo) async {
        let sourceURL = URL(fileURLWithPath: file.path)
        
        do {
            switch action.type {
            case .moveToFolder:
                if let destinationPath = action.parameters["destinationPath"] {
                    let expandedPath = NSString(string: destinationPath).expandingTildeInPath
                    let destinationURL = URL(fileURLWithPath: expandedPath).appendingPathComponent(file.name)
                    
                    // Create destination directory if it doesn't exist
                    try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    
                    // Move the file
                    try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                    
                    recordOperation(
                        fileName: file.name,
                        sourcePath: file.path,
                        destinationPath: destinationURL.path,
                        type: .move,
                        success: true
                    )
                }
                
            case .copyToFolder:
                if let destinationPath = action.parameters["destinationPath"] {
                    let expandedPath = NSString(string: destinationPath).expandingTildeInPath
                    let destinationURL = URL(fileURLWithPath: expandedPath).appendingPathComponent(file.name)
                    
                    // Create destination directory if it doesn't exist
                    try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    
                    // Copy the file
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                    
                    recordOperation(
                        fileName: file.name,
                        sourcePath: file.path,
                        destinationPath: destinationURL.path,
                        type: .copy,
                        success: true
                    )
                }
                
            case .addToTrash:
                try FileManager.default.trashItem(at: sourceURL, resultingItemURL: nil)
                
                recordOperation(
                    fileName: file.name,
                    sourcePath: file.path,
                    destinationPath: nil,
                    type: .delete,
                    success: true
                )
                
            case .renameFile:
                if let newName = action.parameters["newName"] {
                    let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newName)
                    try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                    
                    recordOperation(
                        fileName: file.name,
                        sourcePath: file.path,
                        destinationPath: destinationURL.path,
                        type: .rename,
                        success: true
                    )
                }
                
            case .createFolder, .addTag:
                // These actions would require additional implementation
                break
            }
        } catch {
            recordOperation(
                fileName: file.name,
                sourcePath: file.path,
                destinationPath: nil,
                type: .move,
                success: false,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    private func recordOperation(fileName: String, sourcePath: String, destinationPath: String?, type: OperationType, success: Bool, errorMessage: String? = nil) {
        let operation = FileOperation(
            fileName: fileName,
            sourcePath: sourcePath,
            destinationPath: destinationPath,
            type: type,
            timestamp: Date(),
            success: success,
            errorMessage: errorMessage
        )
        
        recentOperations.insert(operation, at: 0)
        
        // Keep only the last 100 operations
        if recentOperations.count > 100 {
            recentOperations = Array(recentOperations.prefix(100))
        }
        
        // Update statistics
        if success {
            statistics.filesOrganized += 1
        } else {
            statistics.errors += 1
        }
        
        saveSettings()
    }
    
    private func startWatching(directory: URL) {
        // File system watching implementation would go here
        // This would use FSEvents or similar to monitor directory changes
    }
    
    private func stopWatching(directory: URL) {
        // Stop watching implementation would go here
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        let encoder = JSONEncoder()
        
        if let rulesData = try? encoder.encode(organizationRules) {
            UserDefaults.standard.set(rulesData, forKey: "organizationRules")
        }
        
        if let directoriesData = try? encoder.encode(watchedDirectories.map { $0.path }) {
            UserDefaults.standard.set(directoriesData, forKey: "watchedDirectories")
        }
        
        if let operationsData = try? encoder.encode(recentOperations) {
            UserDefaults.standard.set(operationsData, forKey: "recentOperations")
        }
        
        if let statisticsData = try? encoder.encode(statistics) {
            UserDefaults.standard.set(statisticsData, forKey: "statistics")
        }
    }
    
    private func loadSettings() {
        let decoder = JSONDecoder()
        
        if let rulesData = UserDefaults.standard.data(forKey: "organizationRules"),
           let rules = try? decoder.decode([OrganizationRule].self, from: rulesData) {
            organizationRules = rules
        }
        
        if let directoriesData = UserDefaults.standard.data(forKey: "watchedDirectories"),
           let directoryPaths = try? decoder.decode([String].self, from: directoriesData) {
            watchedDirectories = directoryPaths.map { URL(fileURLWithPath: $0) }
        }
        
        if let operationsData = UserDefaults.standard.data(forKey: "recentOperations"),
           let operations = try? decoder.decode([FileOperation].self, from: operationsData) {
            recentOperations = operations
        }
        
        if let statisticsData = UserDefaults.standard.data(forKey: "statistics"),
           let stats = try? decoder.decode(OrganizationStatistics.self, from: statisticsData) {
            statistics = stats
        }
    }
}

// MARK: - Organization Statistics
struct OrganizationStatistics: Codable {
    var filesOrganized: Int = 0
    var errors: Int = 0
    var lastOrganizationDate: Date?
    
    mutating func reset() {
        filesOrganized = 0
        errors = 0
        lastOrganizationDate = nil
    }
}

// MARK: - File System Watcher (Placeholder)
class FileSystemWatcher {
    // This would implement FSEvents-based directory monitoring
    // For now, it's a placeholder for the file system watching functionality
}
