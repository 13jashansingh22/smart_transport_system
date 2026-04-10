const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRouter = require('./routes/auth');
const firebaseRouter = require('./routes/firebase');
const healthRouter = require('./routes/health');
const profilesRouter = require('./routes/profiles');
const transportRouter = require('./routes/transport');

function createApp() {
  const app = express();

  app.use(helmet());
  app.use(
    cors({
      origin: process.env.CORS_ORIGIN || '*',
    }),
  );
  app.use(express.json());
  app.use(morgan('dev'));

  app.get('/', (req, res) => {
    res.json({
      message: 'Smart Transport System API',
      endpoints: [
        '/api/health',
        '/api/firebase/status',
        '/api/auth/me',
        '/api/profiles/me',
        '/api/routes',
        '/api/vehicles',
      ],
    });
  });

  app.use('/api/health', healthRouter);
  app.use('/api/firebase', firebaseRouter);
  app.use('/api/auth', authRouter);
  app.use('/api/profiles', profilesRouter);
  app.use('/api', transportRouter);

  app.use((req, res) => {
    res.status(404).json({
      success: false,
      message: 'Route not found',
    });
  });

  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  });

  return app;
}

module.exports = { createApp };

