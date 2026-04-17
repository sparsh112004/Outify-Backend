# Backend + Frontend Integration Guide

## 1. Backend Setup

### Prerequisites
- Python 3.11+
- MySQL running (localhost:3306)
- Redis running (localhost:6379) for Celery
- Firebase service account JSON file (for push notifications)

### Environment
Copy `.env.example` to `.env` and set:
```ini
DB_HOST=localhost
DB_PORT=3306
DB_USER=outing_user
DB_PASSWORD=StrongPassword123!
DB_NAME=smart_campus_outing
REDIS_URL=redis://localhost:6379/0
FIREBASE_SERVICE_ACCOUNT_JSON_PATH=C:\path\to\your-firebase-adminsdk.json
```

### Install & Run
```bash
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
python manage.py seed  # creates admin/faculty/warden/security/student users
python manage.py runserver
```

### Celery (background tasks & reminders)
Open two terminals:
```bash
# Terminal A: worker
celery -A backend worker -l info

# Terminal B: beat (scheduler)
celery -A backend beat -l info
```

### Verify
- Swagger UI: http://localhost:8000/api/docs/
- Admin: http://localhost:8000/admin/

---

## 2. Flutter Frontend Setup

### Prerequisites
- Flutter SDK
- Android emulator or physical device

### Configuration
- API base URL is in `frontend/lib/utils/constants.dart`.
  - Default for Android emulator: `http://10.0.2.2:8000/api`
  - For real device on same Wi‑Fi: change to your PC’s IP, e.g. `http://192.168.1.10:8000/api`

### Install & Run
```bash
cd frontend
flutter pub get
flutter run
```

### Test Users (from `python manage.py seed`)
| Role          | Email                     | Password          |
|---------------|---------------------------|-------------------|
| Admin         | admin@outing.local        | AdminPass123!     |
| Faculty       | faculty@outing.local      | FacultyPass123!   |
| Warden        | warden@outing.local       | WardenPass123!    |
| Security      | security@outing.local     | SecurityPass123!  |
| Student       | student@outing.local      | StudentPass123!   |

---

## 3. End-to-End Workflow Example

1) **Student** logs in, creates an outing request.
2) **Faculty** logs in, sees pending, approves.
3) **Warden** logs in, sees pending, adds room info and approves.
4) **Student** sees approved request; QR now encodes `outingRequestId`.
5) **Security**:
   - Views today’s approved outings.
   - Scans student QR → navigates to verify screen.
   - Taps Verify Exit → marks actual_departure_time.
   - Later, Verify Entry → marks actual_return_time and completes the outing.

---

## 4. Troubleshooting

### Backend
- `python manage.py check` validates configuration.
- MySQL connection errors: verify DB credentials and that MySQL is running.
- Celery errors: ensure Redis is running.

### Frontend
- Network errors: verify API base URL and that the backend is running.
- QR scan not working: ensure camera permissions are granted.
- Role routing issues: check that the user’s `role` matches one of: student, faculty, warden, security, admin.

---

## 5. CORS Note
- Backend is configured to allow `http://localhost:*` and `http://10.0.2.2:*`.
- If you use a different IP, update `CORS_ALLOWED_ORIGINS` in `backend/settings.py`.
