# Smart Class Check-in & Learning Reflection App

## Project Description
The Smart Class Application is a mobile application developed in Flutter designed for university environments. It helps verify student classroom presence and active engagement through a simple check-in and check-out process. To enforce physical presence, the app relies on **GPS location verification** alongside in-classroom **QR Code scanning**. 

At the start of the session, students check in, verify location/QR, and submit a brief pre-class reflection form assessing their mood and current knowledge. At the end of the session, students check out, re-verify their parameters, and submit a post-class reflection on what they learned. In the MVP version, data is persisted locally via SQLite.

This project was built as part of the Midterm Lab Exam for Mobile Application Development.

## System Design

The system follows a simple client-side architecture for the MVP version, focusing on local validation:

```text
+-------------------+
|  Student (User)   |
+---------+---------+
          |
          v
+-------------------+
|    Flutter App    |
|-------------------|
| Home Screen       |
| Check-in Screen   |
| Finish Class Screen|
+---------+---------+
          |
          v
+-------------------+
|  Device Services  |
|-------------------|
| GPS (Geolocator)  |
| QR Scanner        |
+---------+---------+
          |
          v
+-------------------+
|  Local Database   |
| SQLite            |
+-------------------+
```

* **Student (User):** Interacts directly with the application interface to submit presence and reflections.
* **Flutter App:** Forms the visual presentation layer consisting of the distinct user journey (Home, Check-in, Finish Class screens).
* **Device Services:** Invokes native device hardware through integrations (`geolocator` and `mobile_scanner`) to strictly enforce that the student is physically present in the classroom.
* **Local Database:** An offline-first local SQLite datastore that maintains a persistent record of all check-in timestamps, required locations, expectations, and feedback entries.

## Setup Instructions

### Prerequisites
1. **Flutter SDK** (v3.11.0 or higher)
2. **Dart SDK**
3. **Android Studio** (for Android deployment) or **Xcode** (for iOS deployment)
4. **Firebase CLI** (for deployment tasks)

### Installation
1. Clone the repository to your local machine:
   ```bash
   git clone <YOUR_GITHUB_REPO_URL>
   cd lab-test
   ```
2. Navigate to the app directory:
   ```bash
   cd smart_class_app
   ```
3. Install project dependencies:
   ```bash
   flutter pub get
   ```

## How to Run the App

### Running Locally (Mobile/Emulator)
You can run this app on an Android/iOS emulator or a physical device:
```bash
flutter run
```
*Note: GPS functionalities require granting location permissions on the device. QR code scanning requires camera permission and physical device testing for optimal experience (emulators cannot seamlessly test real QR codes without setup).*

### Running on Web
To run the web version locally:
```bash
flutter run -d chrome
```

## Firebase Configuration & Deployment

This project includes configuration to deploy the Flutter Web build to Firebase Hosting. 

**Steps to deploy:**
1. Generate the web build output:
   ```bash
   cd smart_class_app
   flutter build web
   ```
2. In the root `lab-test` directory (where `firebase.json` is located), log in to Firebase:
   ```bash
   firebase login
   ```
3. Initialize your Firebase project (if you haven't already):
   ```bash
   firebase init hosting
   ```
   *Select your existing Firebase project. Do NOT overwrite the "public" directory configured in `firebase.json`.*
4. Deploy to Firebase:
   ```bash
   firebase deploy --only hosting
   ```
5. The application is officially deployed here: **[https://smart-class-app-80fed.web.app/](https://smart-class-app-80fed.web.app/)**

## AI Usage Report

* **AI Tools Used:** GitHub Copilot (Gemini 3.1 Pro model via VS Code)
* **What AI Helped Generate:**
  * **Requirement Analysis (PRD):** Synthesized the original draft requirements directly into a formatted Markdown PRD (`requirement.md`) with explicit metrics.
  * **Flutter UI Scaffolding & State Management:** The AI generated the boilerplate code for the `HomeScreen`, `CheckInScreen`, and `FinishClassScreen` flows.
  * **Hardware Integration:** The AI synthesized the code required for `geolocator` (GPS) and `mobile_scanner` (QR scanning) tools, properly structuring the device sensor logic alongside `sqflite` saving logic.
  * **Testing Structure:** AI updated the standard widget test (`widget_test.dart`) to accommodate SQLite database mocking restrictions and clean architectures.
* **What I Modified/Implemented Myself:**
  * Coordinated the system design sequence, actively defining the exact file architecture.
  * Triggered Flutter builds and dependency resolutions via CLI.
  * Verified UI outputs, verified linting conditions, and orchestrated the Firebase web artifacts.
