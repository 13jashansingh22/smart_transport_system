# Smart Transport Backend

A lightweight Express backend for the Smart Transport System.

## Run

```bash
npm install
npm run dev
```

## Endpoints

- `GET /api/health` - service health check
- `GET /api/firebase/status` - Firebase Admin initialization status
- `GET /api/routes` - mock route list
- `GET /api/vehicles` - mock vehicle list

## Environment

Copy `.env.example` to `.env` and configure Firebase using one option:

1. `FIREBASE_SERVICE_ACCOUNT_JSON` with raw service account JSON
2. `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` with Base64-encoded JSON
3. `GOOGLE_APPLICATION_CREDENTIALS` with a local key file path

Set `FIREBASE_PROJECT_ID` if it is not included by your credential source.

