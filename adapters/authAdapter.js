const { validationResult } = require('express-validator');
const authController = require('../controllers/authController');

module.exports = {
  register: async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ error: errors.array()[0].msg });
      }
      await authController.register(req, res);
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  },

  login: async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ error: errors.array()[0].msg });
      }
      await authController.login(req, res);
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  },

  refresh: async (req, res) => {
    try {
      await authController.refresh(req, res);
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  },

  logout: async (req, res) => {
    try {
      await authController.logout(req, res);
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  },

  logoutAll: async (req, res) => {
    try {
      await authController.logoutAll(req, res);
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  }
};
