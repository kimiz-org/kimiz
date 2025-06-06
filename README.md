# Kimiz - Epic Games Library Manager for macOS

A simple macOS application for managing Epic Games library with Wine/Game Porting Toolkit integration.

## Features

- Connect to Epic Games (simplified connection)
- Browse Epic Games library
- Install and manage games
- Integration with Wine and Game Porting Toolkit
- Modern SwiftUI interface

## Setup

1. Clone this repository
2. Open `kimiz.xcodeproj` in Xcode
3. Build and run the project

## Usage

1. Launch the app
2. Click "Connect" to connect to Epic Games
3. Browse your game library
4. Install and play games using Wine or Game Porting Toolkit

## Requirements

- macOS 12.0+
- Xcode 14.0+
- Swift 5.7+

## License

This project is open source.

### Environment Configuration

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Get Epic Games OAuth credentials:**
   - Visit [Epic Games Developer Portal](https://dev.epicgames.com/portal/)
   - Create a new application or use an existing one
   - Configure OAuth settings:
     - **Redirect URI**: `kimiz://oauth/epic`
     - **Scopes**: `basic_profile`
     - **Application Type**: Native/Desktop application

3. **Update your `.env` file:**
   ```env
   EPIC_CLIENT_ID=your_actual_client_id_here
   EPIC_CLIENT_SECRET=your_actual_client_secret_here
   ```

### Building

1. **Install dependencies:**
   ```bash
   # Game Porting Toolkit dependencies will be installed automatically
   # through the app's onboarding process
   ```

2. **Build the project:**
   ```bash
   xcodebuild -project kimiz.xcodeproj -scheme kimiz build
   ```

   Or open `kimiz.xcodeproj` in Xcode and build normally.

## Features

- 🎮 **Epic Games Integration**: Connect your Epic Games account to access your library
- 🍷 **Wine Compatibility**: Run Windows games using optimized Wine configuration
- 🛠 **Game Porting Toolkit**: Leverage Apple's official gaming compatibility layer
- 🎯 **Modern UI**: Beautiful, native macOS interface with glassmorphism effects
- ⚙️ **Advanced Options**: Fine-tune graphics, performance, and compatibility settings

## Security

- **Environment Variables**: All sensitive credentials are stored in `.env` file (never committed)
- **Local Storage**: User authentication tokens stored securely in UserDefaults
- **No Keychain**: Eliminates permission prompts while maintaining security

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Copy `.env.example` to `.env` and add your Epic Games credentials
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Apple's Game Porting Toolkit team
- Epic Games for their developer API
- The Wine project and community
