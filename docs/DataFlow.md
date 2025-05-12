# Data Flow Documentation

## Authentication Flow

1. User enters credentials in SignInEmailView
2. SignInEmailViewModel calls AuthenticationManager to authenticate
3. AuthenticationManager communicates with Firebase Auth
4. Upon successful authentication, AuthenticationManager updates its @Published authState
5. RootViewController observes the authState changes via Combine
6. Based on the auth state, RootViewController shows either MainTabBarController or authentication flow
7. CurrentUserService also observes auth state and provides current user ID to other services

## Data Persistence Flow

1. Core Data Entities:

- TodoTask, Hobby, HobbyEntry store user data
- Each entity includes a userId field for multi-user support

2. Managers (TodoTaskManager, HobbyManager) handle CRUD operations

- Create, update, delete operations update both memory and persistence
- Read operations fetch from CoreData with appropriate filters

3. CoreDataService provides the shared persistence container
4. User-specific settings are stored in UserDefaults through the UserDefaultsManager

- Each key is prefixed with user ID for multi-user support

5. PomodoroSettingsManager handles serialization/deserialization of Pomodoro settings

## External API Integration

- QuotesService fetches motivational quotes from the ZenQuotes API
- Results are cached in memory to minimize network requests
- NotificationService schedules notifications with quotes from the service
