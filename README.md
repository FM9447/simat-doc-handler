# SIMAT DocTransit 🎓📜

**SIMAT DocTransit** is a modern, paperless document request, approval, and Duty Leave management platform designed for **Sreepathy Institute of Management and Technology (SIMAT)**, affiliated to **APJ Abdul Kalam Technological University (KTU), Kerala**.

DocTransit replaces traditional paper certificate requests with a digital workflow engine (`Tutor → HOD → Office → Principal`), real-time push notifications, official SIMAT PDF generation, and automated Duty Leave attendance tracking.

---

## 🌟 Key Features

### 📄 1. Official KTU Document Requests
- **Bonafide Certificate** (*Workflow: Tutor → HOD → Principal*)
- **Duty Leave Application** (*Workflow: Tutor → HOD → Tutor*)
- **Transfer Certificate (T.C.)** (*Workflow: Tutor → Office → Principal*)
- **No Objection Certificate (N.O.C.)** (*Workflow: HOD → Principal*)
- **Course Completion Certificate** (*Workflow: Tutor → HOD → Office → Principal*)

### 📅 2. Duty Leave Management & Attendance Marking
- **Multi-Day & Period Schedule Table**: Interactive schedule input for dates, class periods, and event reasons.
- **Nodal Category & Faculty Assignment**: Admin management for event categories (**IEDC**, **NSS**, **MuLearn**, **IEEE**, **Sports**, **Arts**) with assigned Faculty In-Charge.
- **Tutor Attendance Marking**: Class Tutors can mark attendance directly in official registers and notify students with one click.

### 🖼️ 3. Official PDF Generation & Digital Signatures
- Embeds the official **SIMAT Header Banner** with KTU, AICTE, NAAC, and NBA accreditation logos.
- Supports student, tutor, HOD, and principal digital signatures stored securely.

### 🔐 4. Seamless Security & Mobile/Web Experience
- **Auto-Fill & Password Manager**: Integrated with Chrome, Safari, Android Autofill, and iOS Keychain.
- **Role-Based Access Control**: Tailored dashboards for Students, Tutors, HODs, Office Staff, Principals, and System Admins.

---

## 📁 Repository Structure

```
simat-doc-handler/
├── backend/                  # Node.js / Express REST API & Google Drive JSON DB models
│   ├── config/               # Database & Cloudinary storage configuration
│   ├── models/               # Drive-backed model wrappers (User, Document, DocumentType, DutyCategory)
│   ├── routes/               # Express API endpoints
│   ├── seed_flows.js         # KTU document template seeding script
│   ├── clear_students_and_requests.js # Administrative data cleanup utility
│   └── server.js             # API server entrypoint
├── flutter_app/              # Flutter Mobile & Web Client application
│   ├── lib/                  # Application code (Features, Models, Providers, Services)
│   ├── assets/images/        # SIMAT header banner & visual assets
│   └── test/                 # Automated unit and integration tests
├── .github/workflows/        # Automated CI/CD Workflows
│   ├── backend.yml           # Backend deployment to Azure Web App
│   └── main_doctransit.yml   # Frontend web deployment to GitHub Pages (doctransit.live)
└── README.md
```

---

## 🚀 Complete Developer Setup Guide

Follow these step-by-step instructions to set up and run **DocTransit** locally.

### 📋 1. Prerequisites
Ensure you have the following installed on your machine:
- **Node.js**: v20.x or v24.x ([nodejs.org](https://nodejs.org/))
- **Flutter SDK**: 3.24+ ([flutter.dev](https://flutter.dev/))
- **Google Drive JSON DB**: deployed Google Apps Script endpoint and API key.
- **Git**: Installed and configured.

---

### ⚙️ 2. Backend Setup & Run

1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create your environment configuration file `backend/.env`:
   ```env
   PORT=5000
   DRIVE_DB_ENDPOINT=https://script.google.com/macros/s/<deployment-id>/exec
   DRIVE_DB_API_KEY=<drive-db-api-key>
   CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
   CLOUDINARY_API_KEY=your_cloudinary_api_key
   CLOUDINARY_API_SECRET=your_cloudinary_api_secret
   ```

4. Start the backend server:
   ```bash
   # Development mode with auto-reload:
   npm run dev

   # Standard node execution:
   node server.js
   ```
   *Note: On startup, `connectDB()` automatically seeds/updates all KTU document templates into the Drive JSON DB backend.*

---

### 📱 3. Flutter Mobile & Web App Setup

1. Open a new terminal and navigate to `flutter_app`:
   ```bash
   cd flutter_app
   ```

2. Install Flutter packages:
   ```bash
   flutter pub get
   ```

3. Generate Riverpod provider & serialization code:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Run the application:
   ```bash
   # View connected devices (Android / iOS / Chrome):
   flutter devices

   # Run on connected Android phone:
   flutter run -d <device_id> --release

   # Run on Web (Chrome):
   flutter run -d chrome
   ```

5. Build production Web release bundle:
   ```bash
   flutter build web --release --base-href /
   ```

---

### 🧪 4. Running Automated Tests

Run the full Flutter test suite:
```bash
cd flutter_app
flutter test
```

Run static analysis:
```bash
flutter analyze
```

---

## 🌐 Deployment Pipeline (CI/CD)

The repository includes GitHub Actions workflows under `.github/workflows/`:

- **Backend (`.github/workflows/backend.yml`)**: Builds Node.js backend on push to `master` and deploys to Azure Web App (`docTransit`).
- **Web Frontend (`.github/workflows/main_doctransit.yml`)**: Builds Flutter Web bundle and deploys to GitHub Pages at [doctransit.live](https://doctransit.live).

---

## 📄 License
Maintained by Sreepathy Institute of Management and Technology (SIMAT). All rights reserved.