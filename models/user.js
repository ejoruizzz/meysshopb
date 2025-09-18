'use strict';
module.exports = (sequelize, DataTypes) => {
  const Usuario = sequelize.define('Usuario', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },

    nombre: { type: DataTypes.STRING(120), allowNull: false },

    email: {
      type: DataTypes.STRING(160),
      allowNull: false,
      unique: true
    },

    hash: { type: DataTypes.STRING, allowNull: false },

    rol: {
      type: DataTypes.ENUM('cliente', 'admin'),
      allowNull: false,
      defaultValue: 'cliente'
    },

    phone: { type: DataTypes.STRING(30), allowNull: true },

    avatarUrl: { type: DataTypes.STRING(255), allowNull: true }
  }, {
    tableName: 'Usuarios',
    timestamps: true
  });

  Usuario.associate = function (models) {
    // Relación con Sesiones
    Usuario.hasMany(models.Sesion, {
      foreignKey: 'userId',
      as: 'sesiones',
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
  };

  return Usuario;
};
