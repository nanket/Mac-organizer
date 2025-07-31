# Smart File Organizer

A native macOS menu bar application built with SwiftUI that automatically organizes files based on configurable rules.

## Features

### Core Functionality
- **Menu Bar Integration**: One-click access from the macOS menu bar
- **Rule-Based Organization**: Flexible file organization using customizable rules
- **Real-Time Monitoring**: Automatic file organization as files are added to watched directories
- **Multiple Organization Strategies**:
  - By file type (documents, images, videos, etc.)
  - By date created/modified
  - By file size ranges
  - Custom naming patterns and regex rules

### User Interface
- **Clean SwiftUI Interface**: Modern design following macOS Human Interface Guidelines
- **Dashboard**: Overview of organization statistics and recent activity
- **Rules Management**: Easy-to-use interface for creating and managing organization rules
- **Activity Log**: Track all file operations with detailed history
- **Settings Panel**: Configure app preferences and automation options

### Smart Features
- **Duplicate Detection**: Identify and handle duplicate files
- **Undo Functionality**: Reverse recent organization operations
- **Scheduled Organization**: Automatic organization at specified intervals
- **File Preview**: Preview files within the application interface

## System Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later for development

## Installation

### From Source
1. Clone this repository
2. Open `SmartFileOrganizer.xcodeproj` in Xcode
3. Build and run the project

### Permissions
The app requires the following permissions:
- **File System Access**: To read and organize files in selected directories
- **Full Disk Access**: For comprehensive file organization capabilities
- **Notifications**: To inform users about organization activities

## Usage

### Getting Started
1. Launch Smart File Organizer
2. Click the menu bar icon (folder with gear)
3. Add directories to watch using "Add Directory"
4. Configure organization rules in the Rules tab
5. Click "Organize Now" or enable automatic organization

### Creating Organization Rules
1. Go to the Rules tab
2. Click "Add Rule"
3. Define conditions (file type, name pattern, size, etc.)
4. Set actions (move to folder, rename, etc.)
5. Set rule priority and enable/disable as needed

### Supported File Types
- **Documents**: PDF, DOC, DOCX, TXT, RTF, Pages, etc.
- **Images**: JPG, PNG, GIF, TIFF, HEIC, RAW, etc.
- **Videos**: MP4, MOV, AVI, MKV, etc.
- **Audio**: MP3, WAV, AAC, FLAC, etc.
- **Archives**: ZIP, RAR, 7Z, TAR, etc.

## Architecture

### Project Structure
```
SmartFileOrganizer/
├── SmartFileOrganizerApp.swift     # Main app entry point
├── Views/                          # SwiftUI views
│   └── ContentView.swift          # Main interface
├── Models/                         # Data models
│   └── OrganizationRule.swift     # Rule and file models
├── Services/                       # Business logic
│   └── FileOrganizer.swift        # Core organization logic
└── Utilities/                      # Helper classes
    └── MenuBarManager.swift        # Menu bar integration
```

### Key Components
- **MenuBarManager**: Handles menu bar integration and popover display
- **FileOrganizer**: Core service for file organization and rule processing
- **OrganizationRule**: Data models for rules, conditions, and actions
- **ContentView**: Main SwiftUI interface with tabbed navigation

## Development

### Building the Project
1. Open `SmartFileOrganizer.xcodeproj` in Xcode
2. Select the SmartFileOrganizer target
3. Build and run (⌘+R)

### Code Signing
For distribution, you'll need:
- Apple Developer Account
- Code signing certificate
- Proper entitlements configuration

### Testing
- Unit tests for core functionality
- UI tests for interface interactions
- File system operation safety tests

## Security & Privacy

### Sandboxing
The app uses macOS App Sandbox with the following entitlements:
- User-selected file read/write access
- Downloads folder access
- File bookmarks for persistent access
- Apple Events for system integration

### Data Storage
- User preferences stored in UserDefaults
- No personal data transmitted externally
- All file operations performed locally

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Roadmap

### Phase 1 (Current)
- [x] Basic project structure
- [x] Menu bar integration
- [x] Core file organization
- [x] Rule-based system
- [ ] File system monitoring
- [ ] Complete UI implementation

### Phase 2 (Planned)
- [ ] Advanced rule conditions
- [ ] Duplicate file detection
- [ ] Undo functionality
- [ ] Scheduled organization
- [ ] File preview

### Phase 3 (Future)
- [ ] Smart folder suggestions
- [ ] Machine learning integration
- [ ] Cloud storage support
- [ ] Advanced analytics

## Support

For issues, feature requests, or questions:
1. Check existing GitHub issues
2. Create a new issue with detailed description
3. Include system information and steps to reproduce

## Acknowledgments

- Built with SwiftUI and AppKit
- Uses macOS native APIs for file system operations
- Follows Apple's Human Interface Guidelines
