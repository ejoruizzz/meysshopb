// Repositorio de Autenticación: aísla Sequelize para Usuarios y Sesiones
const { Usuario, Sesion, Sequelize } = require('../models');
const { Op } = Sequelize;

function toUsuarioPOJO(u) {
  if (!u) return null;
  const { id, nombre, email, rol, createdAt, updatedAt } = u.toJSON ? u.toJSON() : u;
  return { id, nombre, email, rol, createdAt, updatedAt };
}

module.exports = {
  // ====== USUARIOS ======
  async crearUsuario({ nombre, email, hash, rol = 'cliente' }, tx) {
    const u = await Usuario.create({ nombre, email, hash, rol }, { transaction: tx });
    return toUsuarioPOJO(u);
  },

  async buscarUsuarioPorEmail(email, tx) {
    // devuelve instancia completa (para usar .hash en login)
    return await Usuario.findOne({ where: { email }, transaction: tx });
  },

  async buscarUsuarioPorId(id, tx) {
    const u = await Usuario.findByPk(id, { transaction: tx });
    return toUsuarioPOJO(u);
  },

  async existeEmail(email, tx) {
    const n = await Usuario.count({ where: { email }, transaction: tx });
    return n > 0;
  },

  // ====== SESIONES (REFRESH) ======
  async crearSesion({ userId, jti, familyId, tokenHash, userAgent = null, ip = null, expiresAt }, tx) {
    return await Sesion.create(
      { userId, jti, familyId, tokenHash, userAgent, ip, expiresAt, revokedAt: null },
      { transaction: tx }
    );
  },

  async obtenerSesionPorJti(jti, tx) {
    return await Sesion.findOne({ where: { jti }, transaction: tx });
  },

  async revocarSesionPorJti(jti, { replacedByJti = null } = {}, tx) {
    const patch = { revokedAt: new Date() };
    if (replacedByJti) patch.replacedByJti = replacedByJti;
    await Sesion.update(patch, { where: { jti }, transaction: tx });
  },

  async revocarFamilia(familyId, tx) {
    await Sesion.update({ revokedAt: new Date() }, { where: { familyId }, transaction: tx });
  },

  async revocarTodasPorUser(userId, tx) {
    await Sesion.update({ revokedAt: new Date() }, { where: { userId }, transaction: tx });
  },

  async crearSesionRotada({ userId, oldJti, newJti, familyId, tokenHash, userAgent, ip, expiresAt }, tx) {
    // marca la vieja como revocada y encadena el reemplazo
    await Sesion.update(
      { revokedAt: new Date(), replacedByJti: newJti },
      { where: { jti: oldJti }, transaction: tx }
    );
    // crea la nueva
    return await Sesion.create(
      { userId, jti: newJti, familyId, tokenHash, userAgent, ip, expiresAt, revokedAt: null },
      { transaction: tx }
    );
  }
};
