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