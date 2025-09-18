'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class Sesion extends Model {
    static associate(models) {
      Sesion.belongsTo(models.Usuario, {
        foreignKey: 'userId',
        as: 'usuario',
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE'
      });
    }
  }

  Sesion.init({
    userId: { type: DataTypes.INTEGER, allowNull: false },
    jti: { type: DataTypes.STRING(64), allowNull: false, unique: true },
    familyId: { type: DataTypes.STRING(64), allowNull: false },
    tokenHash: { type: DataTypes.STRING(255), allowNull: false },
    replacedByJti: { type: DataTypes.STRING(64), allowNull: true },
    userAgent: { type: DataTypes.STRING(255), allowNull: true },
    ip: { type: DataTypes.STRING(64), allowNull: true },
    expiresAt: { type: DataTypes.DATE, allowNull: false },
    revokedAt: { type: DataTypes.DATE, allowNull: true }
  }, {
    sequelize,
    modelName: 'Sesion',
    tableName: 'Sesiones',     // 👈 importante
    timestamps: true           // 👈 a juego con la migración
  });

  return Sesion;
};
