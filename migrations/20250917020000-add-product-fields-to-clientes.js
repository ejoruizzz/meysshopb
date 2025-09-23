'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const q = queryInterface;
    const S = Sequelize;
    const cols = await q.describeTable('Clientes').catch(() => ({}));

    if (!cols?.price) {
      await q.addColumn('Clientes', 'price', { type: S.DECIMAL(10, 2), allowNull: false, defaultValue: 0 });
    }
    if (!cols?.cantidad) {
      await q.addColumn('Clientes', 'cantidad', { type: S.INTEGER, allowNull: false, defaultValue: 0 });
    }
    if (!cols?.estado) {
      await q.addColumn('Clientes', 'estado', { type: S.STRING(50), allowNull: false, defaultValue: 'Activo' });
    } else {
      await q.changeColumn('Clientes', 'estado', { type: S.STRING(50), allowNull: false, defaultValue: 'Activo' });
    }
    if (!cols?.imagen) {
      await q.addColumn('Clientes', 'imagen', { type: S.STRING(255), allowNull: true });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('Clientes', 'imagen').catch(() => {});
    await queryInterface.removeColumn('Clientes', 'estado').catch(() => {});
    await queryInterface.removeColumn('Clientes', 'cantidad').catch(() => {});
    await queryInterface.removeColumn('Clientes', 'price').catch(() => {});
  }
};
