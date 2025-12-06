# Knovator
This application fetches and displays posts from the JSONPlaceholder API, providing a seamless user experience with offline support, local caching, and a beautiful Gmail-inspired UI design.

## ✨ Features

### Core Features
- **Posts List View**: Display all posts in a Gmail-style list interface
- **Post Details**: View detailed information for each post
- **Mark as Read**: Track read/unread status for posts
- **Offline Support**: Full offline functionality with local data persistence
- **Pull to Refresh**: Refresh posts list with pull-to-refresh gesture
- **Swipe to Open**: Swipe on post cards to navigate to detail page

### Layer Responsibilities

1. **Domain Layer**: Business logic, entities, and use cases
2. **Data Layer**: API calls, local storage, and data models
3. **Presentation Layer**: UI, BLoC state management, and user interactions

## 🛠️ Tech Stack

### Core Dependencies
- **Flutter**: Latest stable version
- **Dio** : HTTP client for API calls
- **Hive** : Fast, lightweight NoSQL database for local storage
- **Hive Flutter** : Flutter bindings for Hive
- **Flutter BLoC** : State management using BLoC pattern
- **Equatable** : Value equality for state objects

### Development Dependencies
- **Hive Generator** : Code generation for Hive adapters
- **Build Runner** : Code generation tool
- **Flutter Lints** : Linting rules for Flutter

## 📦 Project Structure

```
lib/
├── core/                           # Core utilities and shared code
│   └── errors/                     # Custom exceptions
│       └── exceptions.dart         # NoInternetException
│
├── features/                       # Feature modules
│   └── posts/                      # Posts feature
│       ├── data/                   # Data layer
│       │   ├── datasources/        # Data sources
│       │   │   ├── post_remote_datasource.dart  # API calls
│       │   │   └── post_local_datasource.dart   # Hive operations
│       │   ├── models/             # Data models
│       │   │   ├── post_model.dart # PostModel with Hive annotations
│       │   │   └── post_model.g.dart # Generated Hive adapter
│       │   └── repositories/      # Repository implementations
│       │       └── post_repository_impl.dart
│       │
│       ├── domain/                 # Domain layer
│       │   ├── entities/           # Business entities
│       │   │   └── post.dart       # Post entity
│       │   ├── repositories/       # Repository contracts
│       │   │   └── post_repository.dart
│       │   └── usecases/          # Business logic
│       │       ├── get_posts.dart
│       │       └── get_post_detail.dart
│       │
│       └── presentation/          # Presentation layer
│           ├── bloc/              # State management
│           │   ├── posts_bloc.dart
│           │   ├── posts_event.dart
│           │   └── posts_state.dart
│           └── pages/             # UI screens
│               ├── splash_screen.dart
│               ├── posts_page.dart
│               └── post_detail_page.dart
│
└── main.dart                       # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK 
- Android Studio / VS Code with Flutter extensions
- iOS Simulator / Android Emulator or physical device

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/UKbhatt/Knovator
   cd knovator
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters** (if needed)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**
   ```bash
   flutter run
   ```



## 🔄 State Management (BLoC)

The app uses **BLoC (Business Logic Component)** pattern for state management:

### Events
- `LoadPostsEvent`: Load posts from local/remote
- `SyncPostsEvent`: Background sync with API
- `MarkAsReadEvent`: Mark a post as read
- `RefreshPostsEvent`: Refresh posts list

### States
- `PostsInitial`: Initial state
- `PostsLoading`: Loading state
- `PostsLoaded`: Posts loaded successfully
- `PostsSyncing`: Background sync in progress
- `PostsError`: Error state

## 🌐 API Integration

### Endpoints Used
- **Get All Posts**: `GET https://jsonplaceholder.typicode.com/posts`
- **Get Post Detail**: `GET https://jsonplaceholder.typicode.com/posts/{postId}`

### Error Handling
- Network errors are caught and handled gracefully
- `NoInternetException` is thrown for connection issues
- Offline mode automatically falls back to cached data

## 💾 Local Storage (Hive)

### Data Storage
- **Posts Box**: Stores all post data locally
- **Read Status Box**: Tracks read/unread status for each post

### Features
- Automatic caching of posts
- Persistent read/unread status
- Fast local data retrieval
- Background synchronization

## 📱 Offline-First Implementation

### Behavior
1. **On App Launch**: Loads data from Hive first (if available)
2. **Background Sync**: Silently syncs with API in the background
3. **Offline Mode**: 
   - Shows cached data if available
   - Displays non-intrusive offline indicator
   - Allows reading cached post details
   - Mark-as-read works offline
4. **Pull to Refresh**: Shows snackbar if offline, doesn't clear list

### Post Card Features
- User avatar with blue dot indicator for unread posts
- Title and body preview
- Read/unread visual distinction
- Swipe to open functionality
- Tap to navigate to detail

## 📝 Key Implementation Details

### Repository Pattern
- `PostRepository`: Abstract contract for data operations
- `PostRepositoryImpl`: Concrete implementation combining remote and local sources

### Use Cases
- `GetPosts`: Fetches list of posts
- `GetPostDetail`: Fetches individual post details

### Data Flow
1. UI triggers event → BLoC
2. BLoC calls use case
3. Use case calls repository
4. Repository fetches from local/remote
5. Data flows back through layers
6. BLoC emits new state
7. UI rebuilds with new state

## 🐛 Error Handling

### Custom Exceptions
- `NoInternetException`: Thrown when network is unavailable

### Error States
- Network errors show retry button
- Offline errors show cached data if available
- User-friendly error messages

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 👨‍💻 Development

### Code Style
- Follows Flutter/Dart style guidelines
- Uses `flutter_lints` for code quality
- Clean Architecture principles
- SOLID principles

