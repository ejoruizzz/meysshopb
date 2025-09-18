const express = require('express');
const router = express.Router();

// Rutas de módulos
const authRoutes = require('./auth.routes');
const clientesRoutes = require('./cliente.routes'); // si aún no la tienes, la pasamos después

// Healthcheck simple (opcional)
router.get('/health', (_req, res) => res.json({ ok: true, ts: Date.now() }));

// Montaje con prefijo /api
router.use('/api/auth', authRoutes);
router.use('/api/clientes', clientesRoutes);

module.exports = router;
