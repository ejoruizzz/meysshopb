// Capa de acceso a datos de Cliente (aisla Sequelize del resto)
const { Op } = require('sequelize');
const { Cliente } = require('../models');

function toPOJO(row) {
  if (!row) return null;
  const {
    id,
    nombre,
    apellido,
    email,
    telefono,
    direccion,
    price,
    cantidad,
    estado,
    imagen,
    createdAt,
    updatedAt
  } =
    row.toJSON ? row.toJSON() : row;
  const priceNumber = price != null ? Number(price) : null;
  const cantidadNumber = cantidad != null ? Number(cantidad) : null;
  return {
    id,
    nombre,
    apellido,
    email,
    telefono,
    direccion,
    price: priceNumber,
    cantidad: cantidadNumber,
    estado,
    imagen,
    createdAt,
    updatedAt
  };
}

module.exports = {
  // Listar con filtro opcional por q (nombre/apellido/email) y opciones de paginación
  async listar({ q = null, limit = 50, offset = 0, order = [['createdAt', 'DESC']] } = {}, tx) {
    const where = q
      ? {
          [Op.or]: [
            { nombre:   { [Op.like]: `%${q}%` } },
            { apellido: { [Op.like]: `%${q}%` } },
            { email:    { [Op.like]: `%${q}%` } }
          ]
        }
      : {};
    const rows = await Cliente.findAll({ where, limit, offset, order, transaction: tx });
    return rows.map(toPOJO);
  },

  // Listado paginado (devuelve items y count total)
  async listarPaginado({ q = null, page = 1, pageSize = 20, order = [['createdAt', 'DESC']] } = {}, tx) {
    const where = q
      ? {
          [Op.or]: [
            { nombre:   { [Op.like]: `%${q}%` } },
            { apellido: { [Op.like]: `%${q}%` } },
            { email:    { [Op.like]: `%${q}%` } }
          ]
        }
      : {};
    const limit = pageSize;
    const offset = (page - 1) * pageSize;
    const { rows, count } = await Cliente.findAndCountAll({ where, limit, offset, order, transaction: tx });
    return { items: rows.map(toPOJO), total: count, page, pageSize };
  },

  async buscarPorId(id, tx) {
    const row = await Cliente.findByPk(id, { transaction: tx });
    return toPOJO(row);
  },

  async existeEmail(email, { excluirId = null } = {}, tx) {
    if (email == null) return false; // permitimos múltiples NULL
    const where = excluirId ? { email, id: { [Op.ne]: excluirId } } : { email };
    const n = await Cliente.count({ where, transaction: tx });
    return n > 0;
  },

  async crear(data, tx) {
    const row = await Cliente.create(data, { transaction: tx });
    return toPOJO(row);
  },

  async actualizar(id, data, tx) {
    await Cliente.update(data, { where: { id }, transaction: tx });
    const row = await Cliente.findByPk(id, { transaction: tx });
    return toPOJO(row); // puede ser null si no existía
  },

  async eliminar(id, tx) {
    const n = await Cliente.destroy({ where: { id }, transaction: tx });
    return n > 0;
  }
};
