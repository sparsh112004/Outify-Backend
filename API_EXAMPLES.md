# API Usage Examples

Base URL: `http://localhost:8000/api`

## Authentication

### Register (student only)
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Eve Student",
    "email": "eve@student.local",
    "password": "EvePass123!",
    "college_id": "STU002"
  }'
```

### Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@outing.local",
    "password": "StudentPass123!"
  }'
```
Response includes `access` and `refresh` JWT tokens.

### Me (current user)
```bash
curl -X GET http://localhost:8000/api/auth/me \
  -H "Authorization: Bearer <access_token>"
```

## Outing Requests (Student)

### Create outing request
```bash
curl -X POST http://localhost:8000/api/requests \
  -H "Authorization: Bearer <student_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Visit library for project work",
    "destination": "Main Campus Library",
    "departure_datetime": "2026-03-13T09:00:00Z",
    "expected_return_datetime": "2026-03-13T12:00:00Z"
  }'
```

### List my requests
```bash
curl -X GET http://localhost:8000/api/requests/student \
  -H "Authorization: Bearer <student_access_token>"
```

### Get request details
```bash
curl -X GET http://localhost:8000/api/requests/1 \
  -H "Authorization: Bearer <access_token>"
```

## Faculty

### List pending faculty approvals
```bash
curl -X GET http://localhost:8000/api/requests/faculty/pending \
  -H "Authorization: Bearer <faculty_access_token>"
```

### Approve/Reject (faculty)
```bash
curl -X POST http://localhost:8000/api/requests/faculty/1/decide \
  -H "Authorization: Bearer <faculty_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "decision": "approved",
    "remarks": "Valid academic reason"
  }'
```

## Warden

### List pending warden approvals
```bash
curl -X GET http://localhost:8000/api/requests/warden/pending \
  -H "Authorization: Bearer <warden_access_token>"
```

### Approve/Reject (warden)
```bash
curl -X POST http://localhost:8000/api/requests/warden/1/decide \
  -H "Authorization: Bearer <warden_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "decision": "approved",
    "room_number": "A101",
    "room_details": "First floor, east wing",
    "remarks": "Room verified"
  }'
```

## Security

### Today’s approved outings
```bash
curl -X GET http://localhost:8000/api/requests/security/today \
  -H "Authorization: Bearer <security_access_token>"
```

### Verify Exit/Entry
```bash
curl -X POST http://localhost:8000/api/requests/security/1/verify \
  -H "Authorization: Bearer <security_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "exit"
  }'
```
or
```bash
curl -X POST http://localhost:8000/api/requests/security/1/verify \
  -H "Authorization: Bearer <security_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "entry"
  }'
```

## Admin (optional)

### List logs
```bash
curl -X GET http://localhost:8000/api/logs \
  -H "Authorization: Bearer <admin_access_token>"
```

### List notifications
```bash
curl -X GET http://localhost:8000/api/notifications \
  -H "Authorization: Bearer <admin_access_token>"
```

## Notes
- All datetime fields must be ISO 8601 (e.g. `2026-03-13T09:00:00Z`).
- Replace `<access_token>` with the JWT received from `/auth/login`.
- Use the seeded accounts for quick testing (see backend/management/commands/seed.py).
