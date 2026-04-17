# Outing Management System for College

This repository contains:

- Django REST backend (MySQL) with JWT auth, multi-level approval workflow (Faculty  Warden  Security), audit logs, notifications table, and Celery reminders.

## Prerequisites

- Python 3.12+
- MySQL Server (running)
- Redis (running) for Celery broker

## Backend Setup

### 1) Create `.env`

Create `./.env` (you already have it). Example:

```env
DJANGO_SECRET_KEY=change-me
DJANGO_DEBUG=true
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
DJANGO_TIME_ZONE=UTC

DB_HOST=localhost
DB_PORT=3306
DB_USER=outing_user
DB_PASSWORD=StrongPassword123!
DB_NAME=smart_campus_outing

CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

JWT_ACCESS_LIFETIME_MINUTES=60
JWT_REFRESH_LIFETIME_DAYS=7

REDIS_URL=redis://localhost:6379/0

EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=true
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
EMAIL_FROM=Outing System <no-reply@example.com>

FIREBASE_SERVICE_ACCOUNT_JSON_PATH=
FRONTEND_URL=http://localhost:3000
```

### 2) Install Python dependencies

If you are not using a virtual environment, you can still install globally.

```bash
python -m pip install -U pip
python -m pip install django djangorestframework djangorestframework-simplejwt mysqlclient python-dotenv django-cors-headers drf-spectacular firebase-admin celery redis
```

### 3) Run migrations

```bash
python manage.py migrate
```

### 4) Create an admin user

```bash
python manage.py createsuperuser
```

### 5) Start the backend

```bash
python manage.py runserver
```

API Docs:

- http://127.0.0.1:8000/api/docs/

## Celery Reminders (Two Processes)

Start Redis first.

### Terminal 1: Celery Worker

```bash
python -m celery -A backend worker -l info
```

### Terminal 2: Celery Beat

```bash
python -m celery -A backend beat -l info
```

The Beat schedule runs `outings.tasks.send_return_reminders_strict` every minute.

## API Quick Test

### Register student

`POST /api/auth/register`

Body:

```json
{
  "name": "Student One",
  "email": "student1@example.com",
  "password": "password123",
  "college_id": "CSE001"
}
```

### Login

`POST /api/auth/login`

Body:

```json
{
  "email": "student1@example.com",
  "password": "password123"
}
```

Use the returned `access` token as:

`Authorization: Bearer <token>`

## Notes

- Email and FCM are optional for local development; failures are recorded in `notifications` and `logs`.
- Firebase requires a local JSON file path in `FIREBASE_SERVICE_ACCOUNT_JSON_PATH`.
