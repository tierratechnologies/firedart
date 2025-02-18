const FIRESTORE_HOST_URI = 'firestore.googleapis.com';
const FIRESTORE_HOST_PORT = 443;

const AUTH_HOST_URI_AUTHORITY = 'identitytoolkit.googleapis.com';
const AUTH_HOST_URI_PATH = 'v1/accounts';

const EMULATORS_HOST_URI = 'localhost';
const FIRESTORE_EMULATOR_HOST_PORT = 8080;
const AUTH_EMULATOR_HOST_PORT = 9099;
const AUTH_EMULATOR_HOST_URI =
    'http://$EMULATORS_HOST_URI:$AUTH_EMULATOR_HOST_PORT/emulator/v1/projects/{{project_id}}';
