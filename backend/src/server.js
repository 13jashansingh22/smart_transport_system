require('dotenv').config();

const { initializeFirebaseAdmin } = require('./config/firebaseAdmin');
const { createApp } = require('./app');

const PORT = process.env.PORT || 4000;

try {
  initializeFirebaseAdmin();
} catch (error) {
  console.warn(error.message);
}

const app = createApp();

app.listen(PORT, () => {
  console.log(`Smart Transport backend running on http://localhost:${PORT}`);
});

