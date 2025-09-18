'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const S = Sequelize;
    const q = queryInterface;
    const cols = await q.describeTable('Clientes').catch(() => ({}));

    // nombre / apellido requeridos
    if (!cols?.nombre) {
      await q.addColumn('Clientes', 'nombre', { type: S.STRING(120), allowNull: false, defaultValue: 'Nombre' });
    }
    await q.changeColumn('Clientes', 'nombre', { type: S.STRING(120), allowNull: false });

    if (!cols?.apellido) {
      await q.addColumn('Clientes', 'apellido', { type: S.STRING(120), allowNull: false, defaultValue: 'Apellido' });
    }
    await q.changeColumn('Clientes', 'apellido', { type: S.STRING(120), allowNull: false });

    // email: nullable pero único si existe
    if (!cols?.email) {
      await q.addColumn('Clientes', 'email', { type: S.STRING(160), allowNull: true });
    } else {
      await q.changeColumn('Clientes', 'email', { type: S.STRING(160), allowNull: true });
    }

    // telefono / direccion opcionales
    if (!cols?.telefono)  await q.addColumn('Clientes', 'telefono',  { type: S.STRING(50),  allowNull: true });
    if (!cols?.direccion) await q.addColumn('Clientes', 'direccion', { type: S.STRING(255), allowNull: true });

    // índice único en email (si no existe)
    try {
      await q.addIndex('Clientes', ['email'], { unique: true, name: 'clientes_email_uindex' });
    } catch (e) { /* ya existía */ }

    // índice auxiliar para búsquedas por nombre+apellido (opcional)
    try {
      await q.addIndex('Clientes', ['nombre', 'apellido'], { name: 'clientes_nombre_apellido_idx' });
    } catch (e) { /* ya existía */ }
  },

  async down(queryInterface) {
    // revertimos solo índices para evitar perder datos
    try { await queryInterface.removeIndex('Clientes', 'clientes_email_uindex'); } catch (e) {}
    try { await queryInterface.removeIndex('Clientes', 'clientes_nombre_apellido_idx'); } catch (e) {}
    // (no eliminamos columnas en down para no romper datos existentes)
  }
};
