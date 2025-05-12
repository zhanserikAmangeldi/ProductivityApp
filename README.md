# ProductivityApp

A comprehensive iOS productivity application built with SwiftUI and UIKit, designed to help users manage tasks, track habits, and improve focus through a Pomodoro timer.

## Features 

- Authentication: User account creation and login via Firebase
- Pomodoro Timer: Customizable focus and break sessions
- To-Do List: Task management with priorities, due dates, and tags
- Habit Tracker: Track daily habits with streak monitoring
- Motivational Quotes: Receive inspirational quotes as notifications

## Architecture

This app uses the MVVM (Model-View-ViewModel) architectural pattern with UIKit navigation and SwiftUI views:

- SwiftUI views embedded in UIKit navigation controllers
- Firebase for authentication
- Core Data for local data persistence
- User-specific data segregation

## Dependencies

- Firebase/Auth
- Lottie

## Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/ProductivityApp.git
```

2. Open the .xcworkspace file:

```bash
open ProductivityApp.xcworkspace
```

3. Add your Firebase configuration:

    1. Create a Firebase project at https://console.firebase.google.com/
    2. Add an iOS app to your Firebase project
    3. Download the GoogleService-Info.plist file
    4. Add the file to your Xcode project


4. Build and run the project!

