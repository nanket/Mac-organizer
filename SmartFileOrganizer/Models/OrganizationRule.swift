import Foundation

// MARK: - Organization Rule
struct OrganizationRule: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var isEnabled: Bool
    var priority: Int
    var conditions: [RuleCondition]
    var actions: [RuleAction]
    var createdDate: Date
    var lastModified: Date
    
    init(name: String, conditions: [RuleCondition], actions: [RuleAction], priority: Int = 0) {
        self.name = name
        self.isEnabled = true
        self.priority = priority
        self.conditions = conditions
        self.actions = actions
        self.createdDate = Date()
        self.lastModified = Date()
    }
    
    func matches(file: FileInfo) -> Bool {
        guard isEnabled else { return false }
        
        // All conditions must be met for the rule to match
        return conditions.allSatisfy { condition in
            condition.evaluate(for: file)
        }
    }
}

// MARK: - Rule Condition
struct RuleCondition: Identifiable, Codable, Hashable {
    let id = UUID()
    var type: ConditionType
    var `operator`: ConditionOperator
    var value: String
    var caseSensitive: Bool

    init(type: ConditionType, operator: ConditionOperator, value: String, caseSensitive: Bool = false) {
        self.type = type
        self.`operator` = `operator`
        self.value = value
        self.caseSensitive = caseSensitive
    }
    
    func evaluate(for file: FileInfo) -> Bool {
        let fileValue = type.getValue(from: file)
        let compareValue = caseSensitive ? value : value.lowercased()
        let targetValue = caseSensitive ? fileValue : fileValue.lowercased()
        
        switch self.`operator` {
        case .equals:
            return targetValue == compareValue
        case .contains:
            return targetValue.contains(compareValue)
        case .startsWith:
            return targetValue.hasPrefix(compareValue)
        case .endsWith:
            return targetValue.hasSuffix(compareValue)
        case .matches:
            return targetValue.range(of: compareValue, options: .regularExpression) != nil
        case .greaterThan:
            return compareNumericValues(targetValue, compareValue, >)
        case .lessThan:
            return compareNumericValues(targetValue, compareValue, <)
        case .greaterThanOrEqual:
            return compareNumericValues(targetValue, compareValue, >=)
        case .lessThanOrEqual:
            return compareNumericValues(targetValue, compareValue, <=)
        }
    }
    
    private func compareNumericValues(_ target: String, _ compare: String, _ operation: (Double, Double) -> Bool) -> Bool {
        guard let targetNum = Double(target),
              let compareNum = Double(compare) else {
            return false
        }
        return operation(targetNum, compareNum)
    }
}

// MARK: - Rule Action
struct RuleAction: Identifiable, Codable, Hashable {
    let id = UUID()
    var type: ActionType
    var parameters: [String: String]
    
    init(type: ActionType, parameters: [String: String] = [:]) {
        self.type = type
        self.parameters = parameters
    }
}

// MARK: - Condition Types
enum ConditionType: String, CaseIterable, Codable {
    case fileName = "fileName"
    case fileExtension = "fileExtension"
    case fileSize = "fileSize"
    case creationDate = "creationDate"
    case modificationDate = "modificationDate"
    case filePath = "filePath"
    case fileType = "fileType"
    
    var displayName: String {
        switch self {
        case .fileName: return "File Name"
        case .fileExtension: return "File Extension"
        case .fileSize: return "File Size"
        case .creationDate: return "Creation Date"
        case .modificationDate: return "Modification Date"
        case .filePath: return "File Path"
        case .fileType: return "File Type"
        }
    }
    
    func getValue(from file: FileInfo) -> String {
        switch self {
        case .fileName:
            return file.name
        case .fileExtension:
            return file.fileExtension
        case .fileSize:
            return String(file.size)
        case .creationDate:
            return ISO8601DateFormatter().string(from: file.creationDate)
        case .modificationDate:
            return ISO8601DateFormatter().string(from: file.modificationDate)
        case .filePath:
            return file.path
        case .fileType:
            return file.fileType.rawValue
        }
    }
}

// MARK: - Condition Operators
enum ConditionOperator: String, CaseIterable, Codable {
    case equals = "equals"
    case contains = "contains"
    case startsWith = "startsWith"
    case endsWith = "endsWith"
    case matches = "matches"
    case greaterThan = "greaterThan"
    case lessThan = "lessThan"
    case greaterThanOrEqual = "greaterThanOrEqual"
    case lessThanOrEqual = "lessThanOrEqual"
    
    var displayName: String {
        switch self {
        case .equals: return "Equals"
        case .contains: return "Contains"
        case .startsWith: return "Starts With"
        case .endsWith: return "Ends With"
        case .matches: return "Matches (Regex)"
        case .greaterThan: return "Greater Than"
        case .lessThan: return "Less Than"
        case .greaterThanOrEqual: return "Greater Than or Equal"
        case .lessThanOrEqual: return "Less Than or Equal"
        }
    }
    
    func isApplicable(to conditionType: ConditionType) -> Bool {
        switch conditionType {
        case .fileName, .fileExtension, .filePath:
            return [.equals, .contains, .startsWith, .endsWith, .matches].contains(self)
        case .fileSize:
            return [.equals, .greaterThan, .lessThan, .greaterThanOrEqual, .lessThanOrEqual].contains(self)
        case .creationDate, .modificationDate:
            return [.equals, .greaterThan, .lessThan, .greaterThanOrEqual, .lessThanOrEqual].contains(self)
        case .fileType:
            return [.equals].contains(self)
        }
    }
}

// MARK: - Action Types
enum ActionType: String, CaseIterable, Codable {
    case moveToFolder = "moveToFolder"
    case copyToFolder = "copyToFolder"
    case renameFile = "renameFile"
    case addToTrash = "addToTrash"
    case createFolder = "createFolder"
    case addTag = "addTag"
    
    var displayName: String {
        switch self {
        case .moveToFolder: return "Move to Folder"
        case .copyToFolder: return "Copy to Folder"
        case .renameFile: return "Rename File"
        case .addToTrash: return "Move to Trash"
        case .createFolder: return "Create Folder"
        case .addTag: return "Add Tag"
        }
    }
    
    var requiredParameters: [String] {
        switch self {
        case .moveToFolder, .copyToFolder:
            return ["destinationPath"]
        case .renameFile:
            return ["newName"]
        case .addToTrash:
            return []
        case .createFolder:
            return ["folderName", "parentPath"]
        case .addTag:
            return ["tagName"]
        }
    }
}

// MARK: - File Info
struct FileInfo: Identifiable, Codable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let creationDate: Date
    let modificationDate: Date
    let fileType: FileType
    
    var fileExtension: String {
        return (name as NSString).pathExtension.lowercased()
    }
    
    var url: URL {
        return URL(fileURLWithPath: path)
    }
}

// MARK: - File Type
enum FileType: String, CaseIterable, Codable {
    case document = "document"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case archive = "archive"
    case executable = "executable"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .document: return "Document"
        case .image: return "Image"
        case .video: return "Video"
        case .audio: return "Audio"
        case .archive: return "Archive"
        case .executable: return "Executable"
        case .other: return "Other"
        }
    }
    
    static func from(fileExtension: String) -> FileType {
        let ext = fileExtension.lowercased()
        
        let documentExtensions = ["pdf", "doc", "docx", "txt", "rtf", "pages", "odt", "xls", "xlsx", "ppt", "pptx", "csv"]
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "svg", "webp", "heic", "raw"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v"]
        let audioExtensions = ["mp3", "wav", "aac", "flac", "ogg", "m4a", "wma"]
        let archiveExtensions = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz"]
        let executableExtensions = ["app", "dmg", "pkg", "deb", "exe", "msi"]
        
        if documentExtensions.contains(ext) { return .document }
        if imageExtensions.contains(ext) { return .image }
        if videoExtensions.contains(ext) { return .video }
        if audioExtensions.contains(ext) { return .audio }
        if archiveExtensions.contains(ext) { return .archive }
        if executableExtensions.contains(ext) { return .executable }
        
        return .other
    }
}

// MARK: - File Operation
struct FileOperation: Identifiable, Codable {
    let id = UUID()
    let fileName: String
    let sourcePath: String
    let destinationPath: String?
    let type: OperationType
    let timestamp: Date
    let success: Bool
    let errorMessage: String?
    
    var description: String {
        switch type {
        case .move:
            return success ? "Moved to \(destinationPath ?? "unknown")" : "Failed to move: \(errorMessage ?? "Unknown error")"
        case .copy:
            return success ? "Copied to \(destinationPath ?? "unknown")" : "Failed to copy: \(errorMessage ?? "Unknown error")"
        case .rename:
            return success ? "Renamed to \(destinationPath ?? "unknown")" : "Failed to rename: \(errorMessage ?? "Unknown error")"
        case .delete:
            return success ? "Moved to trash" : "Failed to delete: \(errorMessage ?? "Unknown error")"
        }
    }
}

// MARK: - Operation Type
enum OperationType: String, CaseIterable, Codable {
    case move = "move"
    case copy = "copy"
    case rename = "rename"
    case delete = "delete"
    
    var icon: String {
        switch self {
        case .move: return "arrow.right.circle.fill"
        case .copy: return "doc.on.doc.fill"
        case .rename: return "pencil.circle.fill"
        case .delete: return "trash.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .move: return .blue
        case .copy: return .green
        case .rename: return .orange
        case .delete: return .red
        }
    }
}

import SwiftUI

extension Color {
    static let blue = Color.blue
    static let green = Color.green
    static let orange = Color.orange
    static let red = Color.red
}
