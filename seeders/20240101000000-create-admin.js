'use strict';

const bcrypt = require('bcrypt');

module.exports = {
  async up(queryInterface, Sequelize) {
    const hash = await bcrypt.hash('admin123', 10);

    return queryInterface.bulkInsert('Usuarios', [
      {
        nombre: 'Admin',
        email: 'admin@example.com',
        hash,
        rol: 'admin',
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ]);
  },

  async down(queryInterface, Sequelize) {
    return queryInterface.bulkDelete('Usuarios', { email: 'admin@example.com' });
  }
};
