const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const authRepo = require('../repositories/authRepository');
const { ACCESS_SECRET } = require('../middleware/authJwt');

const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'refresh_secret';
const ACCESS_EXP = process.env.JWT_ACCESS_EXPIRES || '15m';
const REFRESH_EXP = process.env.JWT_REFRESH_EXPIRES || '30d';
const REFRESH_EXP_MS = (() => {
  // Convierte "30d" a ms de forma simple: d/h/m
  const m = String(REFRESH_EXP).match(/^(\d+)([dhm])$/i);
  if (!m) return 30 * 24 * 60 * 60 * 1000;
  const n = Number(m[1]); const u = m[2].toLowerCase();
  return u === 'd' ? n*24*60*60*1000 : u === 'h' ? n*60*60*1000 : n*60*1000;
})();

const signAccess = (u) =>
  jwt.sign({ id: u.id, email: u.email, rol: u.rol }, ACCESS_SECRET, { expiresIn: ACCESS_EXP });

const signRefresh = (payload) =>
  jwt.sign(payload, REFRESH_SECRET, { expiresIn: REFRESH_EXP });

const genIds = () => ({
  jti: crypto.randomBytes(16).toString('hex'),
  familyId: crypto.randomBytes(16).toString('hex')
});

const hashToken = (t) => crypto.createHash('sha256').update(t).digest('hex');

// ---------- Register ----------
const register = async (req, res) => {
  try {
    const { nombre, email, password } = req.body;
    if (!nombre || !email || !password) {
      return res.status(400).json({ error: 'Datos incompletos' });
    }
    const existe = await authRepo.existeEmail(email);
    if (existe) return res.status(409).json({ error: 'Email ya registrado' });

    const hash = await bcrypt.hash(password, 10);
    const user = await authRepo.crearUsuario({ nombre, email, hash, rol: 'cliente' });
    res.status(201).json({ id: user.id, nombre: user.nombre, email: user.email });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// ---------- Login ----------
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const userRow = await authRepo.buscarUsuarioPorEmail(email);
    if (!userRow) return res.status(401).json({ error: 'Credenciales inválidas' });

    const ok = await bcrypt.compare(password, userRow.hash);
    if (!ok) return res.status(401).json({ error: 'Credenciales inválidas' });

    const access = signAccess(userRow);
    const { jti, familyId } = genIds();
    const refresh = signRefresh({ id: userRow.id, email: userRow.email, rol: userRow.rol, jti, familyId });

    await authRepo.crearSesion({
      userId: userRow.id,
      jti,
      familyId,
      tokenHash: hashToken(refresh),
      userAgent: req.headers['user-agent'] || null,
      ip: req.ip || null,
      expiresAt: new Date(Date.now() + REFRESH_EXP_MS)
    });

    res.json({
      access,
      refresh,
      usuario: { id: userRow.id, nombre: userRow.nombre, email: userRow.email, rol: userRow.rol }
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// ---------- Refresh (rotación segura) ----------
const refresh = async (req, res) => {
  try {
    const { refresh: refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ error: 'Falta refresh token' });

    let payload;
    try {
      payload = jwt.verify(refreshToken, REFRESH_SECRET);
    } catch {
      return res.status(401).json({ error: 'Refresh inválido' });
    }

    const { id, email, rol, jti, familyId } = payload;
    const sesion = await authRepo.obtenerSesionPorJti(jti);
    if (!sesion || sesion.revokedAt) {
      // posible reuso → revoca toda la familia
      await authRepo.revocarFamilia(familyId);
      return res.status(401).json({ error: 'Refresh revocado' });
    }
    if (sesion.expiresAt && sesion.expiresAt < new Date()) {
      await authRepo.revocarSesionPorJti(jti);
      return res.status(401).json({ error: 'Refresh expirado' });
    }

    // rotación
    const nuevoJti = crypto.randomBytes(16).toString('hex');
    const nuevoRefresh = signRefresh({ id, email, rol, jti: nuevoJti, familyId });

    await authRepo.crearSesionRotada({
      userId: id,
      oldJti: jti,
      newJti: nuevoJti,
      familyId,
      tokenHash: hashToken(nuevoRefresh),
      userAgent: req.headers['user-agent'] || null,
      ip: req.ip || null,
      expiresAt: new Date(Date.now() + REFRESH_EXP_MS)
    });

    const access = signAccess({ id, email, rol });
    res.json({ access, refresh: nuevoRefresh });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// ---------- Logout (revoca solo la sesión del refresh enviado) ----------
const logout = async (req, res) => {
  try {
    const { refresh: refreshToken } = req.body;
    if (!refreshToken) return res.json({ ok: true });
    try {
      const { jti } = jwt.verify(refreshToken, REFRESH_SECRET);
      await authRepo.revocarSesionPorJti(jti);
    } catch { /* ignore */ }
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// ---------- Logout All (revoca todas las sesiones del usuario actual) ----------
const logoutAll = async (req, res) => {
  try {
    await authRepo.revocarTodasPorUser(req.user.id);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

module.exports = { register, login, refresh, logout, logoutAll };
