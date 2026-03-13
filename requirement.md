# Product Requirement Document (PRD)
## Smart Class Check-in & Learning Reflection App

### 1. Problem Statement
Universities need a reliable way to confirm that students are physically present in class and actively participating in learning activities. Traditional attendance systems (like paper sign-ins) do not verify true location or mental engagement. This system aims to improve attendance tracking by combining GPS location verification, QR code scanning, and student learning reflection into a single mobile workflow.

### 2. Target Users
* **University Students:** Attending classroom sessions who need a quick and straightforward way to check-in and out.
* **Instructors:** Who want to accurately track physical attendance and receive immediate feedback on student engagement.

### 3. Feature List
**Class Check-in (Before Class)**
* Student presses **Check-in**
* System records current **GPS location** (Latitude/Longitude)
* System records exact **timestamp**
* Student scans the **class QR code**
* Student fills out a **pre-class reflection form**:
  * Topic covered in the previous class
  * Expected topic for today's class
  * Mood before class (1-5 scale):
    * 1 = 😡 Very negative
    * 2 = 🙁 Negative
    * 3 = 😐 Neutral
    * 4 = 🙂 Positive
    * 5 = 😄 Very positive

**Class Completion (After Class)**
* Student presses **Finish Class** on an active session
* Student scans **QR code again**
* System records **checkout GPS location** and **timestamp**
* Student fills out a **post-class learning reflection form**:
  * What they learned today (short text)
  * Feedback about the class or instructor

**Data Storage**
* Full lifecycle storage of check-in and check-out data.
* Offline-first behavior using **SQLite** as the local database for the MVP.

### 4. User Flow
1. Open the application.
2. Viewing Home Screen with existing sessions. Press **Check-in**.
3. System captures current **GPS location** and timestamp automatically.
4. Student scans the **instructor's QR Code**.
5. Student fills out the **pre-class reflection form** (ID, topics, mood) and submits.
6. The session is now active and the student attends the class.
7. After class, the student presses **Finish Class** for that session.
8. Student scans the **QR Code again**.
9. System captures the checkout **GPS location** and timestamp.
10. Student fills out the **learning reflection and feedback**.
11. Complete session is finalized and saved locally.

### 5. Data Fields
**Check-in Data**
* `student_id` (String)
* `check_in_timestamp` (DateTime)
* `check_in_latitude` / `check_in_longitude` (Double)
* `check_in_qr_code` (String)
* `previous_topic` (String)
* `expected_topic` (String)
* `mood_before_class` (Integer: 1-5)

**Check-out Data**
* `check_out_timestamp` (DateTime)
* `check_out_latitude` / `check_out_longitude` (Double)
* `check_out_qr_code` (String)
* `learned_today` (String)
* `feedback` (String)

### 6. Technology Stack
* **Frontend:** Flutter (Dart) for MVP implementation
* **Local Storage:** SQLite (via `sqflite` package)
* **Device Integration:** `geolocator` for GPS mapping, `mobile_scanner` for QR code reading
* **Deployment:** Firebase Hosting (Web build deployment for accessible demonstration)
