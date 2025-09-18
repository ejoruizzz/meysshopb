const jwt = require('jsonwebtoken');

const ACCESS_SECRET = process.env.JWT_SECRET || 'access_secret';

/**
 * Extrae el token Bearer del header Authorization.
 * Ej: "Authorization: Bearer <token>"
 */
function getBearerToken(req) {
  const h = req.headers.authorization || '';
  if (!h.startsWith('Bearer ')) return null;
  return h.slice(7);
}

/**
 * Middleware: requiereAuth
 * - Verifica el Access Token (JWT)
 * - Inyecta payload en req.user -> { id, email, rol, iat, exp }
 */
function requiereAuth(req, res, next) {
  const token = getBearerToken(req);
  if (!token) return res.status(401).json({ error: 'No autorizado' });

  try {
    const payload = jwt.verify(token, ACCESS_SECRET);
    req.user = payload;
    return next();
  } catch (_e) {
    return res.status(401).json({ error: 'Token inválido o expirado' });
  }
}

/**
 * Middleware: requiereAdmin
 * - Requiere que req.user.rol === 'admin'
 * - Debe ir DESPUÉS de requiereAuth
 */
function requiereAdmin(req, res, next) {
  if (req.user?.rol !== 'admin') {
    return res.status(403).json({ error: 'Requiere rol admin' });
  }
  return next();
}

module.exports = {
  requiereAuth,
  requiereAdmin,
  // exporto la constante por si la necesitas en otros módulos
  ACCESS_SECRET
};
