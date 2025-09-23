'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      const cols = await queryInterface.describeTable('Clientes').catch(() => ({}));

      if (cols?.imagen) {
        await queryInterface.removeColumn('Clientes', 'imagen', { transaction });
      }
      if (cols?.estado) {
        await queryInterface.removeColumn('Clientes', 'estado', { transaction });
      }
      if (cols?.cantidad) {
        await queryInterface.removeColumn('Clientes', 'cantidad', { transaction });
      }
      if (cols?.price) {
        await queryInterface.removeColumn('Clientes', 'price', { transaction });
      }

      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      const cols = await queryInterface.describeTable('Clientes').catch(() => ({}));

      if (!cols?.price) {
        await queryInterface.addColumn('Clientes', 'price', {
          type: Sequelize.DECIMAL(10, 2),
          allowNull: false,
          defaultValue: 0
        }, { transaction });
      }
      if (!cols?.cantidad) {
        await queryInterface.addColumn('Clientes', 'cantidad', {
          type: Sequelize.INTEGER,
          allowNull: false,
          defaultValue: 0
        }, { transaction });
      }
      if (!cols?.estado) {
        await queryInterface.addColumn('Clientes', 'estado', {
          type: Sequelize.STRING(50),
          allowNull: false,
          defaultValue: 'Activo'
        }, { transaction });
      }
      if (!cols?.imagen) {
        await queryInterface.addColumn('Clientes', 'imagen', {
          type: Sequelize.STRING(255),
          allowNull: true
        }, { transaction });
      }

      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }
};
