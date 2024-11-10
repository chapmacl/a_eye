# A_Eye

A_Eye is a Peronal Project Flutter app that turns a smartphone into an intelligent security camera with object detection. When a known object is detected, the app captures photos, processes them with overlays of what was detected in the frame, and saves the photo. Additionally, it can upload photos to a Firebase backend. Users can create an account and remotely access captured footage from a different device. 

### Main Features
- **Object Detection Model**: Uses an AI-powered object detection model to identify objects in the camera’s view. When a known object is detected, A_Eye begins capturing photos, draws detection labels and bounding boxes on them.
- **Write Data to Internal Storage** The photos are written to internal storage on the device in real time during capture, and can be viewed in the app. Photos are combined into a final video file as well. Media is stored automatically in a hierarchy of _Year/Month/Day/Event_
- **Cloud Storage Capable**: Captured footage can be uploaded to Firebase for remote access. The app supports creation of an account with Google Sign-In, and photos can be viewed and downloaded from other devices. 

### Prerequisites

1. Flutter SDK: Install the Flutter SDK.
2.	Firebase Setup:
3. Firebase Account: Create a Firebase project for your app.
4. Google Services Configuration:
   - Download google-services.json and add it to android/app/.
   - Download GoogleService-Info.plist and add it to ios/Runner/.
5. An object detection model must be in the project. For ease of use, I recommend the official model files from Google on Tensorhub, since they work well with a Flutter Library. 


### Project Structure 

For those less familiar with Flutter projects, the basic file structure is arranged like this
```
a_eye/
├── android/                    # Android-specific code and configurations
├── assets/                     # Static assets like images, models
├── ios/                        # iOS-specific code and configurations
├── lib/                        # Main application code for Flutter
│   ├── main.dart               # Entry point of the application
│   ├── providers/              # State management and data providers
│   ├── screens/                # UI screens and navigation flows
│   ├── utils/                  # Utility functions and helper classes
│   └── widgets/                # Reusable UI components
├── test/                       # Unit and widget tests
└── pubspec.yaml                # Dependency and asset configuration
```

### Folder Overview

- *lib/providers/*: Contains provider class objects for managing app state, in this case our Firebase backend.
- *lib/screens/*: Houses each screen of the app, through which users navigate (e.g., login, settings, main detection view).
- *lib/utils/*: Utility functions and helpers for tasks such as object detection pipeline and data processing.
- *lib/widgets/*: Reusable components for a consistent UI across the app.

This structure supports a clean separation of concerns, helping make A_Eye easy to extend and maintain. When designing a project, it is useful to separate code into files based on what the code does. It should be as granular as possible, and then organized in a way that groups files based on their general purpose or function. 