require('dotenv').config();

const { initializeFirebaseAdmin } = require('./config/firebaseAdmin');
const { createApp } = require('./app');

try {
  initializeFirebaseAdmin();
} catch (error) {
  console.warn(error.message);
}

const app = createApp();

// Listen only when run directly (not when imported as a Vercel serverless function)
if (require.main === module) {
  const PORT = process.env.PORT || 4000;
  app.listen(PORT, () => {
    console.log(`Smart Transport backend running on http://localhost:${PORT}`);
  });
}

module.exports = app;

