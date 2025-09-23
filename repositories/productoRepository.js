const { Op } = require('sequelize');
const { Producto } = require('../models');

function toPOJO(row) {
  if (!row) return null;
  const {
    id,
    nombre,
    descripcion,
    categoria,
    precio,
    stock,
    estado,
    imagen,
    createdAt,
    updatedAt
  } = row.toJSON ? row.toJSON() : row;

  const precioNumber = precio != null ? Number(precio) : null;
  const stockNumber = stock != null ? Number(stock) : null;

  return {
    id,
    nombre,
    descripcion,
    categoria,
    precio: precioNumber,
    stock: stockNumber,
    estado,
    imagen: imagen ?? null,
    createdAt,
    updatedAt
  };
}

module.exports = {
  async listar({ q = null, limit = 50, offset = 0, order = [['createdAt', 'DESC']] } = {}, tx) {
    const where = q
      ? {
          [Op.or]: [
            { nombre: { [Op.like]: `%${q}%` } },
            { categoria: { [Op.like]: `%${q}%` } },
            { descripcion: { [Op.like]: `%${q}%` } }
          ]
        }
      : {};

    const rows = await Producto.findAll({ where, limit, offset, order, transaction: tx });
    return rows.map(toPOJO);
  },

  async listarPaginado({ q = null, page = 1, pageSize = 20, order = [['createdAt', 'DESC']] } = {}, tx) {
    const where = q
      ? {
          [Op.or]: [
            { nombre: { [Op.like]: `%${q}%` } },
            { categoria: { [Op.like]: `%${q}%` } },
            { descripcion: { [Op.like]: `%${q}%` } }
          ]
        }
      : {};

    const limit = pageSize;
    const offset = (page - 1) * pageSize;
    const { rows, count } = await Producto.findAndCountAll({ where, limit, offset, order, transaction: tx });
    return { items: rows.map(toPOJO), total: count, page, pageSize };
  },

  async buscarPorId(id, tx) {
    const row = await Producto.findByPk(id, { transaction: tx });
    return toPOJO(row);
  },

  async crear(data, tx) {
    const row = await Producto.create(data, { transaction: tx });
    return toPOJO(row);
  },

  async actualizar(id, data, tx) {
    await Producto.update(data, { where: { id }, transaction: tx });
    const row = await Producto.findByPk(id, { transaction: tx });
    return toPOJO(row);
  },

  async eliminar(id, tx) {
    const n = await Producto.destroy({ where: { id }, transaction: tx });
    return n > 0;
  }
};
