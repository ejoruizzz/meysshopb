'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.createTable('Productos', {
        id: {
          allowNull: false,
          autoIncrement: true,
          primaryKey: true,
          type: Sequelize.INTEGER
        },
        nombre: {
          type: Sequelize.STRING(150),
          allowNull: false
        },
        descripcion: {
          type: Sequelize.TEXT,
          allowNull: false
        },
        categoria: {
          type: Sequelize.STRING(120),
          allowNull: false,
          defaultValue: 'General'
        },
        precio: {
          type: Sequelize.DECIMAL(10, 2),
          allowNull: false,
          defaultValue: 0
        },
        stock: {
          type: Sequelize.INTEGER,
          allowNull: false,
          defaultValue: 0
        },
        estado: {
          type: Sequelize.STRING(50),
          allowNull: false,
          defaultValue: 'Activo'
        },
        imagen: {
          type: Sequelize.STRING(255),
          allowNull: true
        },
        createdAt: {
          allowNull: false,
          type: Sequelize.DATE,
          defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
        },
        updatedAt: {
          allowNull: false,
          type: Sequelize.DATE,
          defaultValue: Sequelize.literal('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP')
        }
      }, { transaction });

      const cols = await queryInterface.describeTable('Clientes').catch(() => null);
      if (cols && cols.price && cols.cantidad) {
        await queryInterface.sequelize.query(
          `INSERT INTO Productos (nombre, descripcion, categoria, precio, stock, estado, imagen, createdAt, updatedAt)
           SELECT
             nombre,
             CASE
               WHEN direccion IS NOT NULL AND direccion <> '' THEN direccion
               WHEN apellido IS NOT NULL AND apellido <> '' THEN apellido
               ELSE 'Sin descripción'
             END AS descripcion,
             CASE
               WHEN apellido IS NOT NULL AND apellido <> '' THEN apellido
               ELSE 'General'
             END AS categoria,
             price,
             cantidad,
             COALESCE(estado, 'Activo') AS estado,
             imagen,
             createdAt,
             updatedAt
           FROM Clientes
           WHERE price IS NOT NULL OR cantidad IS NOT NULL OR imagen IS NOT NULL`,
          { transaction }
        );
      }

      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface) {
    await queryInterface.dropTable('Productos');
  }
};
