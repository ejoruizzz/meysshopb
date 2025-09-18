const jwt = require('jsonwebtoken');

const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'refresh_secret';

module.exports = (req, res, next) => {
  const { refresh } = req.body;
  if (!refresh) {
    return res.status(400).json({ error: 'Refresh token requerido' });
  }

  try {
    const payload = jwt.verify(refresh, REFRESH_SECRET);
    req.refreshPayload = payload; // guardamos el payload del refresh para usarlo en el controller
    next();
  } catch {
    return res.status(401).json({ error: 'Refresh token inválido o expirado' });
  }
};
