'use strict';

module.exports = (sequelize, DataTypes) => {
  const Producto = sequelize.define('Producto', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    nombre: { type: DataTypes.STRING(150), allowNull: false },
    descripcion: { type: DataTypes.TEXT, allowNull: false },
    categoria: { type: DataTypes.STRING(120), allowNull: false, defaultValue: 'General' },
    precio: { type: DataTypes.DECIMAL(10, 2), allowNull: false, defaultValue: 0 },
    stock: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    estado: { type: DataTypes.STRING(50), allowNull: false, defaultValue: 'Activo' },
    imagen: { type: DataTypes.STRING(255), allowNull: true }
  }, {
    tableName: 'Productos',
    timestamps: true
  });

  Producto.associate = function (_models) { /* relaciones futuras */ };
  return Producto;
};
