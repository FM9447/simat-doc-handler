# AntiGravity - Digital Document Approval System

This is the fully generated source code for AntiGravity.

## Project Structure
- `backend/`: Node.js, Express, MongoDB REST API.
- `flutter_app/`: Flutter 3.19+ cross-platform mobile application utilizing Riverpod for state management.

## Prerequisites
1. **Node.js**: v18+ installed on your system.
2. **MongoDB**: A running MongoDB instance or MongoDB Atlas cluster.
3. **Flutter**: v3.19+ installed and added to PATH.

## ⚡ Quick Start (Recommended)
You can now manage the whole project from the root folder:

1.  **Backend Setup & Start**:
    ```bash
    npm run dev
    ```
    *This will automatically seed document types, approve all users, and start the server.*

2.  **Frontend Start**:
    ```bash
    flutter run
    ```
    *Make sure you are in the `flutter_app/` folder or use `npm run frontend` from the root.*

## 🛠️ Individual Commands (Root)
- `npm run dev`: All-in-one Backend setup (Seed + Approve + Server). 🚀
- `npm run backend`: Starts only the Node.js server.
- `npm run seed`: Populates initial document flows (Bonafide, TC, etc.).
- `npm run approve`: Approves all users instantly for testing.
- `npm run install-all`: Installs dependencies for both Backend and Frontend.

## 📱 Platform Support
The app automatically detects the environment:
- **Web**: Connects to `localhost:5000`.
- **Android Emulator**: Connects to `10.0.2.2:5000`.
- **Physical Mobile**: Connects to `192.168.1.39:5000` (Make sure phone is on the SAME Wi-FI).

---
*For detailed administrative features, please refer to the internal walkthrough.*