// Repositorio de Autenticación: aísla Sequelize para Usuarios y Sesiones
const { Usuario, Sesion, Sequelize } = require('../models');
const { Op } = Sequelize;

function toUsuarioPOJO(u) {
  if (!u) return null;
  const json = u.toJSON ? u.toJSON() : u;
  const { id, nombre, email, rol, phone = null, avatarUrl = null, createdAt, updatedAt } = json;
  return { id, nombre, email, rol, phone, avatarUrl, createdAt, updatedAt };
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

  async existeEmail(email, { excluirId = null } = {}, tx) {
    if (email == null) return false;
    const where = excluirId ? { email, id: { [Op.ne]: excluirId } } : { email };
    const n = await Usuario.count({ where, transaction: tx });
    return n > 0;
  },

  async actualizarUsuario(id, data, tx) {
    if (!id) return null;

    const allowed = ['nombre', 'email', 'phone', 'avatarUrl'];
    const patch = {};
    for (const field of allowed) {
      if (Object.prototype.hasOwnProperty.call(data, field)) {
        const value = data[field];
        if (value !== undefined) {
          patch[field] = value;
        }
      }
    }

    if (Object.keys(patch).length > 0) {
      await Usuario.update(patch, { where: { id }, transaction: tx });
    }

    const actualizado = await Usuario.findByPk(id, { transaction: tx });
    return toUsuarioPOJO(actualizado);
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
