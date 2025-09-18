'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('Sesiones', {
  id: {
    allowNull: false,
    autoIncrement: true,
    primaryKey: true,
    type: Sequelize.INTEGER
  },
  userId: {
    type: Sequelize.INTEGER,
    allowNull: false,
    references: { model: 'Usuarios', key: 'id' },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE'
  },
  jti: {
    type: Sequelize.STRING(64),
    allowNull: false,
    unique: true
  },
  familyId: {
    type: Sequelize.STRING(64),
    allowNull: false
  },
  tokenHash: {
    type: Sequelize.STRING(255),
    allowNull: false
  },
  replacedByJti: {
    type: Sequelize.STRING(64),
    allowNull: true
  },
  userAgent: {
    type: Sequelize.STRING(255),
    allowNull: true
  },
  ip: {
    type: Sequelize.STRING(64),
    allowNull: true
  },
  expiresAt: {
    type: Sequelize.DATE,
    allowNull: false
  },
  revokedAt: {
    type: Sequelize.DATE,
    allowNull: true
  },
  createdAt: {
    allowNull: false,
    type: Sequelize.DATE,
    defaultValue: Sequelize.fn('NOW')
  },
  updatedAt: {
    allowNull: false,
    type: Sequelize.DATE,
    defaultValue: Sequelize.fn('NOW')
  }
});

// índices útiles
await queryInterface.addIndex('Sesiones', ['userId']);
await queryInterface.addIndex('Sesiones', ['familyId']);
await queryInterface.addIndex('Sesiones', ['expiresAt']);

  },
  async down(queryInterface, Sequelize) {
  await queryInterface.dropTable('Sesiones'); // 👈 corregido
}

};