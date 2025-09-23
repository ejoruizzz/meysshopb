'use strict';
module.exports = (sequelize, DataTypes) => {
  const Cliente = sequelize.define('Cliente', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },

    nombre:   { type: DataTypes.STRING(120), allowNull: false },
    apellido: { type: DataTypes.STRING(120), allowNull: false },

    // nullable pero único si existe
    email:    { type: DataTypes.STRING(160), allowNull: true, unique: true },

    telefono:  { type: DataTypes.STRING(50),  allowNull: true },
    direccion: { type: DataTypes.STRING(255), allowNull: true },

    
  }, {
    tableName: 'Clientes',
    timestamps: true
  });

  Cliente.associate = function (_models) { /* relaciones futuras */ };
  return Cliente;
};
