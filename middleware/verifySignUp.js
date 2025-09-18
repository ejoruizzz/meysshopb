const { Usuario } = require('../models');

// Middleware para verificar que no exista ya un usuario con el mismo email
const checkDuplicateEmail = async (req, res, next) => {
  try {
    if (!req.body.email) {
      return res.status(400).json({ error: 'Email requerido' });
    }

    const existe = await Usuario.count({ where: { email: req.body.email } });
    if (existe > 0) {
      return res.status(409).json({ error: 'Email ya registrado' });
    }

    next();
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};

module.exports = { checkDuplicateEmail };
