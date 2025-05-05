# Application Architecture

This document outlines the architecture of the Muslim Kids app, including file organization, code structure, and design patterns.

## Directory Structure
The application follows a feature-first organization:

```
lib/
  ├── Features/       # Feature modules
  ├── models/         # Data models
  ├── screens/        # UI screens
  ├── services/       # Core services
  └── widgets/        # Reusable UI components
```

## Key Components
### Core Services
- **AuthenticationService**: Manages user authentication with Firebase Auth
- **NotificationService**: Handles local notifications and Firebase messaging
- **FirebaseService**: Core Firebase integrations (Firestore, Cloud Messaging)

### Feature Components
- **PrayerTracker**: System for tracking and visualizing prayer activity
- **IslamicCalendar**: Calendar with significant days and educational content
- **VideoPlayer**: Custom video player for animated moral stories
- **LiveClassManager**: Handles Quran recitation live classes

## Data Flow
The application follows a unidirectional data flow using the Repository pattern:
1. User interactions trigger events in the UI
2. Events are handled by state management (Riverpod)
3. Business logic is executed in repositories
4. Data is retrieved/stored through Firebase services
5. UI updates based on state changes

## State Management
- Uses Riverpod for state management
- Provider-based dependency injection
- State is maintained in StateNotifier classes following repository pattern
- AsyncValue for handling loading, error, and success states

## Repository Pattern Implementation
- Repositories abstract the data sources (Firebase, local storage)
- Each entity type has its own repository
- Repositories handle data transformation and error handling
- Return rich result objects containing both data and metadata

## Navigation System
- Basic navigation framework
- Screen-based routing
- Role-based navigation (Child/Parent/Teacher)

## Widget Hierarchy
- App Shell containing navigation and authentication state
- Screen widgets for major features
- Feature-specific widget components
- Shared UI elements for consistent design

## Feature Documentation

### Authentication
- Supports multiple user types (Kid, Parent, Teacher)
- Firebase Authentication integration
- Role-based access control

### Prayer Tracking
- Visual charts for tracking prayers
- Data stored in Firestore
- Progress visualization

### Islamic Calendar
- Significant days in Islamic calendar
- Educational descriptions for each event
- Visual calendar interface

### Live Classes
- Real-time interaction between teachers and students
- Video streaming integration
- Class scheduling and management

---

*This document will be updated as the architecture evolves.* 