const { validationResult } = require('express-validator');
const ctrl = require('../controllers/clienteController');

module.exports = {
  listar: async (req, res) => {
    try {
      await ctrl.listar(req, res);
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  },

  crear: async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) return res.status(400).json({ error: errors.array()[0].msg });
      await ctrl.crear(req, res);
    } catch (e) {
      res.status(400).json({ error: e.message });
    }
  },

  actualizar: async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) return res.status(400).json({ error: errors.array()[0].msg });
      await ctrl.actualizar(req, res);
    } catch (e) {
      res.status(400).json({ error: e.message });
    }
  },

  eliminar: async (req, res) => {
    try {
      await ctrl.eliminar(req, res);
    } catch (e) {
      res.status(400).json({ error: e.message });
    }
  }
};
