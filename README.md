# Digital Certificate Auth Dashboard

A Flutter + Firebase module for the UPM Digital Certificate Repository system.  
This part covers **Module 1A (Authentication & Role Management)** and **1B (Recipient Registration & Dashboard)**.

## 🚀 Features Implemented

### ✅ Module 1A – Authentication & Role Management
- Google Sign-In integration using `@upm.edu.my` domain restriction
- Automatic user creation in Firestore
- Role-Based Access Control (RBAC) with default role: `recipient`
- Firebase Authentication and Firestore integration

### ✅ Module 1B – Recipient Registration & Dashboard
- Upon login, recipient users are registered automatically
- Recipients can view a list of their issued certificates
- Certificate data is dynamically fetched from Firestore (`certificates` collection)

---

## 📦 Tech Stack

- **Frontend:** Flutter
- **Backend-as-a-Service:** Firebase (Auth, Firestore)
- **Authentication:** Google OAuth (with domain restriction)
- **State Management:** Minimal (Stateless + FutureBuilder)

---

## 🔧 How to Run

1. Clone this repo:
   ```bash
   git clone https://github.com/yokea1/digital-cert-auth-dashboard.git
   cd digital-cert-auth-dashboard
   ```

2. Get packages:
   ```bash
   flutter pub get
   ```

3. Add your `google-services.json` file under:
   ```
   android/app/google-services.json
   ```

4. Run the app:
   ```bash
   flutter run
   ```

> ⚠️ Only users with an `@upm.edu.my` Google account can log in.

---

## 📁 Firestore Data Structure

### `users` collection:
```json
{
  "email": "student@upm.edu.my",
  "role": "recipient",
  "createdAt": "timestamp"
}
```

### `certificates` collection (for display):
```json
{
  "title": "Flutter Workshop Certificate",
  "recipientEmail": "student@upm.edu.my",
  "issuer": "UPM CA",
  "issuedDate": "2025-06-10"
}
```

---

## 📌 What’s Next (For Teammates)
This project sets the foundation for:
- Certificate Generation (Module 2A)
- Secure Sharing & Viewer Access (Module 2B)
- True Copy Upload & Approval (Modules 3A & 3B)

Please fork or clone this repo and continue development from this point. Firebase is already integrated.

---

## 👨‍💻 Developed by

**He Yuke**  
Module 1A & 1B Developer  
[GitHub: yokea1](https://github.com/yokea1)
